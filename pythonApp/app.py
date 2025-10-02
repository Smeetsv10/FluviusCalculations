from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, timedelta

# Import your simplified classes
from classes.myHouse import House
from classes.myBattery import Battery
from classes.myFluviusData import FluviusData

# ---------------------------
# FastAPI app
# ---------------------------
app = FastAPI(title="FluviusCalculations API", version="1.0")

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
    EAN_ID: Optional[str] = None
    file_path: Optional[str] = None  # optional file path if needed

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
    return {"message": "FluviusCalculations API is running!"}

# ---------------------------
# Load data once
# ---------------------------
@app.post("/load_data")
def load_data(request: SimulationRequest):
    global grid_data
    
    # Load Fluvius data only once
    if grid_data is None:
        grid_data = FluviusData(
            file_path=request.file_path,
            start_date=request.start_date,
            end_date=request.end_date
        )
        try:
            grid_data.load_data()
        except Exception as e:
            return {"error": f"Failed to load grid data: {e}"}
        try:
            grid_data.process_data()
        except Exception as e:
            return {"error": f"Failed to process grid data: {e}"}

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
