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

# Import your simplified classes
from classes.myHouse import House
from classes.myBattery import Battery
from classes.myFluviusData import FluviusData

# ---------------------------
# FastAPI app
# ---------------------------
app = FastAPI(title="FluviusCalculations API")

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

class SimulationRequest(BaseModel):
    # Dates
    start_date: Optional[str] = seven_days_ago.isoformat()
    end_date: Optional[str] = today.isoformat()
    
    # House parameters
    location: Optional[str] = ""
    injection_price: Optional[float] = 0.04
    price_per_kWh: Optional[float] = 0.35
    
    # Battery parameters
    battery_capacity: Optional[float] = 0.0
    battery_lifetime: Optional[int] = 10
    price_per_kWh_battery: Optional[float] = 700
    efficiency: Optional[float] = 0.95
    C_rate: Optional[float] = 0.25 / 4
    dynamic: Optional[bool] = False
    
    # FluviusData parameters
    flag_EV: Optional[bool] = True
    flag_PV: Optional[bool] = True
    EAN_ID: Optional[int] = -1
    file_path: Optional[str] = None  # optional file path if needed
    csv_data: Optional[str] = None  # CSV file content as base64 string

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
    return {"message": "FluviusCalculations API is running! - v1.0.1"}

# ---------------------------
# Load data once
# ---------------------------
@app.post("/load_data")
def load_data(request: SimulationRequest):
    global grid_data
    try:
        # Initialize grid_data
        grid_data = FluviusData()
        
        # Validate required fields
        if request.csv_data is None or request.csv_data == "":
            return {"error": "csv_data field is required and cannot be empty"}
        
        # Set FluviusData parameters
        grid_data.start_date = request.start_date if isinstance(request.start_date, str) else seven_days_ago.isoformat()
        grid_data.end_date = request.end_date if isinstance(request.end_date, str) else today.isoformat()
        grid_data.flag_EV = request.flag_EV
        grid_data.flag_PV = request.flag_PV
        grid_data.EAN_ID = request.EAN_ID
        grid_data.file_path = request.file_path
        
        print("📊 Loading CSV data from bytes...")
        data = grid_data.load_csv_from_bytes(request.csv_data)
        
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
                    "start": grid_data.df['datetime'].min().strftime('%Y-%m-%d %H:%M:%S'),
                    "end": grid_data.df['datetime'].max().strftime('%Y-%m-%d %H:%M:%S')
                }
            except Exception as e:
                print(f"⚠️ Warning: Could not extract date range: {e}")
        
        return {
            "message": "Data loaded and processed successfully",
            "data_info": {
                "records": len(grid_data.df),
                "date_range": date_range_info
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
def simulate_household(request: SimulationRequest):
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}

    # Create House with Battery
    house = House(
        battery=Battery(max_capacity=request.battery_capacity, 
                        efficiency=request.efficiency,
                        price_per_kWh=request.price_per_kWh_battery,
                        battery_lifetime=request.battery_lifetime,
                        C_rate=request.C_rate),
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
def optimize_battery(request: SimulationRequest):
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}

    house = House(
        battery=Battery(max_capacity=request.battery_capacity, 
                        efficiency=request.efficiency,
                        price_per_kWh=request.price_per_kWh_battery,
                        battery_lifetime=request.battery_lifetime,
                        C_rate=request.C_rate),
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
