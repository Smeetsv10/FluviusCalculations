from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel
from typing import List, Optional

from datetime import date, timedelta
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt

import io
import base64
import uvicorn

# Import your simplified classes
from classes.myHouse import House
from classes.myBattery import Battery
from classes.myFluviusData import FluviusData

# ---------------------------
# FastAPI app
# ---------------------------
app = FastAPI(title="Home Battery Sizing Tool API")

# Add CORS middleware to allow Flutter web requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------
# Global variable for grid data
# ---------------------------
grid_data: Optional[FluviusData] = None

# ---------------------------
# Request/Response Models
# ---------------------------
today = date.today()
seven_days_ago = today - timedelta(days=7)


class BatteryRequest(BaseModel):
    max_capacity: float = 0.0
    efficiency: float = 0.95
    variable_cost: float = 700
    battery_lifetime: int = 10
    C_rate: float = 0.25

class GridDataRequest(BaseModel):
    file_path: Optional[str] = None
    flag_EV: bool = True
    flag_PV: bool = True
    EAN_ID: int = -1
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    csv_data: Optional[str] = None

class HouseRequest(BaseModel):
    location: Optional[str] = ""
    injection_price: float = 0.04
    price_per_kWh: float = 0.35
    battery: BatteryRequest
    grid_data: GridDataRequest
    
class SimulationResponse(BaseModel):
    import_energy: List[float]
    export_energy: List[float]
    soc_history: List[float]
    import_cost: float
    export_revenue: float
    energy_cost: float
    optimal_capacity: Optional[float] = None

# ---------------------------
# Root endpoint
# ---------------------------
@app.get("/")
def root():
    return {"message": "FluviusCalculations API is running! - v1.1.0"}

# ---------------------------
# Load data once
# ---------------------------
@app.post("/load_data")
def load_data(request: HouseRequest):
    global grid_data
    try:
        # Initialize grid_data
        grid_data = FluviusData()

        # Validate required fields
        if request.grid_data.csv_data is None or request.grid_data.csv_data == "":
            return {"error": f"csv_data field is required and cannot be empty: {request.grid_data.csv_data}"}

        # Set FluviusData parameters
        grid_data.start_date = request.grid_data.start_date if isinstance(request.grid_data.start_date, str) else seven_days_ago.isoformat()
        grid_data.end_date = request.grid_data.end_date if isinstance(request.grid_data.end_date, str) else today.isoformat()
        grid_data.flag_EV = request.grid_data.flag_EV
        grid_data.flag_PV = request.grid_data.flag_PV
        grid_data.EAN_ID = request.grid_data.EAN_ID
        grid_data.file_path = request.grid_data.file_path

        print("📊 Loading CSV data from bytes...")
        data = grid_data.load_csv_from_bytes(request.grid_data.csv_data)

        grid_data.load_data(data)
        grid_data.process_data()
        
        if grid_data.df.empty:
            return {"error": "Failed to load data or dataframe is empty"}
        
        print(f"✅ Data loaded: {len(grid_data.df)} rows, columns: {list(grid_data.df.columns)}")
        
        # Safely get date range info
        date_range_info = {"start": None, "end": None}
        if 'datetime' in grid_data.df.columns:
            try:
                date_range_info = {
                    "start": grid_data.df['datetime'].min().isoformat(),
                    "end": grid_data.df['datetime'].max().isoformat()
                }
            except Exception as e:
                print(f"⚠️ Warning: Could not extract date range: {e}")
        
        return {
            "message": "Data loaded and processed successfully",
            "data_info": {
                "records": len(grid_data.df),
                "date_range": date_range_info,

            }
        }
        
    except Exception as e:
        print(f"❌ Error in load_data: {e}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        return {"error": f"Failed to load data: {str(e)}"}

# ---------------------------
# Simulate household using preloaded grid data
# ---------------------------
@app.post("/simulate", response_model=SimulationResponse)
def simulate_household(request: HouseRequest):
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}

    # Create House with Battery
    house = House(
        battery=Battery(max_capacity=request.battery.max_capacity, 
                        efficiency=request.battery.efficiency,
                        price_per_kWh=request.battery.price_per_kWh,
                        battery_lifetime=request.battery.battery_lifetime,
                        C_rate=request.battery.C_rate),
        grid_data=grid_data,
        injection_price=request.injection_price,
        price_per_kWh=request.price_per_kWh
        
    )

    try:
        import_energy, export_energy = house.simulate_household()
    except Exception as e:
        return {"error": f"Simulation failed: {e}"}

    return SimulationResponse(
        import_energy=import_energy,
        export_energy=export_energy,
        soc_history=house.battery.SOC_history,
        import_cost=house.import_cost,
        export_revenue=house.export_revenue,
        energy_cost=house.energy_cost
    )

# ---------------------------
# Optimize battery capacity
# ---------------------------
@app.post("/optimize", response_model=SimulationResponse)
def optimize_battery(request: HouseRequest):
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}

    house = House(
        battery=Battery(max_capacity=request.battery.max_capacity, 
                        efficiency=request.battery.efficiency,
                        price_per_kWh=request.battery.price_per_kWh,
                        battery_lifetime=request.battery.battery_lifetime,
                        C_rate=request.battery.C_rate),
        grid_data=grid_data
    )

    try:
        house.optimize_battery_capacity()
    except Exception as e:
        return {"error": f"Optimization failed: {e}"}

    return SimulationResponse(
        import_energy=house.import_energy_history,
        export_energy=house.export_energy_history,
        soc_history=house.battery.SOC_history,
        import_cost=house.import_cost,
        export_revenue=house.export_revenue,
        energy_cost=house.energy_cost,
        optimal_capacity=house.optimal_battery_capacity
    )

@app.post("/plot_data")
def plot_data(request: HouseRequest):
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}

    try:
        # Get the matplotlib figure from visualize_data
        fig = grid_data.visualize_data()
        
        # Convert the plot to a base64 string
        buffer = io.BytesIO()
        fig.savefig(buffer, format='png', dpi=150, bbox_inches='tight')
        buffer.seek(0)
        
        # Encode to base64
        plot_data_b64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
        buffer.close()
        
        # Close the figure to free memory
        plt.close(fig)
        
        return {
            "message": "Plot generated successfully",
            "plot_data": plot_data_b64
        }
        
    except Exception as e:
        import traceback
        print(f"❌ Error in plot_data: {e}")
        print(f"Full traceback: {traceback.format_exc()}")
        return {"error": f"Plotting failed: {str(e)}"}
    
# --- Run Server ---
if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)