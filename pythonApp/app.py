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
    
    grid_data.start_date = request.start_date
    grid_data.end_date = request.end_date
    grid_data.flag_EV = request.flag_EV
    grid_data.flag_PV = request.flag_PV
    grid_data.EAN_ID = request.EAN_ID
    grid_data.file_path = request.file_path
    grid_data.df = pd.DataFrame()  # Reset dataframe
      
    return {
        "message": "Data loaded and processed successfully",
        "data_info": {
            "records": len(grid_data.df) if not grid_data.df.empty else 0,
            "columns": list(grid_data.df.columns) if not grid_data.df.empty else [],
            "date_range": {
                "start": grid_data.df['datetime'].min().strftime('%Y-%m-%d %H:%M:%S') if not grid_data.df.empty else None,
                "end": grid_data.df['datetime'].max().strftime('%Y-%m-%d %H:%M:%S') if not grid_data.df.empty else None
            }
        }
    }

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

# ---------------------------
# Plot data visualization
# ---------------------------
@app.get("/plot_data")
def plot_data():
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}
    
    try:
        print("📊 Creating visualization...")
        
        # Get the dataframe from grid_data
        if grid_data.df.empty:
            return {"error": "Dataframe is empty. Load and process data first."}

        df = grid_data.df

        # Create the plot
        fig, axes = plt.subplots(2, 1, figsize=(12, 6), sharex=True)

        # Generate daily boundaries
        daily_boundaries = pd.date_range(start=df['datetime'].dt.floor('D').min(),
                                        end=df['datetime'].dt.floor('D').max(),
                                        freq='D')

        # --- Plot 1: Import vs Export ---
        axes[0].plot(df['datetime'], df['import'], color='blue', label='Import')
        axes[0].plot(df['datetime'], df['export'], color='orange', label='Export')
        axes[0].set_title("Import vs Export (kWh)")
        axes[0].legend()
        axes[0].grid(True, which='both', axis='both', linestyle='--', alpha=0.5)

        # --- Plot 2: Remaining ---
        axes[1].plot(df['datetime'], df['remaining'], color='black', label='Remaining')
        axes[1].fill_between(df['datetime'], df['remaining'], 0,
                            where=(df['remaining'] > 0), color='red', alpha=0.3)
        axes[1].fill_between(df['datetime'], df['remaining'], 0,
                            where=(df['remaining'] < 0), color='green', alpha=0.3)
        axes[1].set_title("Remaining Consumption (kWh)")
        axes[1].legend()
        axes[1].grid(True, which='both', axis='both', linestyle='--', alpha=0.5)

        # Add vertical lines for each day
        for day in daily_boundaries:
            axes[0].axvline(day, color='gray', linestyle='--', alpha=0.3)
            axes[1].axvline(day, color='gray', linestyle='--', alpha=0.3)

        # X-axis: day numbers and full date on first of month
        xticks = []
        xticklabels = []
        for day in daily_boundaries:
            xticks.append(day)
            if day.day == 1:
                xticklabels.append(day.strftime('%Y-%m-%d'))  # full date for first day of month
            else:
                xticklabels.append(str(day.day))  # day number for other days

        axes[1].set_xticks(xticks)
        axes[1].set_xticklabels(xticklabels, rotation=45, ha='right')

        plt.tight_layout()
        
        # Convert plot to base64 string for Flutter
        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format='png', dpi=150, bbox_inches='tight')
        img_buffer.seek(0)
        img_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
        plt.close(fig)  # Important: close the figure to free memory
        
        print("✅ Plot created successfully!")
        return {"plot_image": img_base64}
        
    except Exception as e:
        print(f"❌ Failed to create plot: {e}")
        return {"error": f"Failed to create plot: {e}"}

# ---------------------------
# Get plot data as JSON for Flutter plotting
# ---------------------------
@app.get("/plot_data_json")
def plot_data_json():
    global grid_data
    if grid_data is None:
        return {"error": "Grid data not loaded. Call /load_data first."}
    
    try:
        print("📊 Preparing plot data as JSON...")
        
        # Get the dataframe from grid_data
        if grid_data.df.empty:
            return {"error": "Dataframe is empty. Load and process data first."}

        df = grid_data.df
        
        # Convert datetime to string for JSON serialization
        plot_data = {
            "datetime": df['datetime'].dt.strftime('%Y-%m-%d %H:%M:%S').tolist(),
            "import": df['import'].tolist(),
            "export": df['export'].tolist(), 
            "remaining": df['remaining'].tolist(),
            "data_info": {
                "start_date": df['datetime'].min().strftime('%Y-%m-%d'),
                "end_date": df['datetime'].max().strftime('%Y-%m-%d'),
                "total_records": len(df),
                "date_range_days": (df['datetime'].max() - df['datetime'].min()).days
            }
        }
        
        print(f"✅ Plot data prepared: {len(df)} records, {len(str(plot_data))} characters")
        return plot_data
        
    except Exception as e:
        print(f"❌ Failed to prepare plot data: {e}")
        return {"error": f"Failed to prepare plot data: {e}"}