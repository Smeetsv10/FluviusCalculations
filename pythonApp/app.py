from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
from classes.myBattery import Battery
from classes.myHouse import House 
from classes.myFluviusData import FluviusData


# FastAPI app
app = FastAPI(title="Fluvius Energy API", version="1.0")

# ---------------------------
# Request/Response Models
# ---------------------------
@app.get("/")
def root():
    return {"message": "FluviusCalculations API is running!"}

class SimulationRequest(BaseModel):
    start_date: str
    end_date: str
    battery_capacity: Optional[float] = 0.0
    efficiency: Optional[float] = 0.95
    location: Optional[str] = None
    dynamic: Optional[bool] = False
    file_path: Optional[str] = None
    file_name: Optional[str] = None
    

class SimulationResponse(BaseModel):
    import_energy: List[float]
    export_energy: List[float]
    soc_history: List[float]
    import_cost: float
    export_revenue: float
    energy_cost: float
    optimal_capacity: Optional[float] = None


# ---------------------------
# Endpoints
# ---------------------------

@app.post("/simulate", response_model=SimulationResponse)
def simulate_household(request: SimulationRequest):
    """
    Simulate a household given start_date, end_date, and battery settings.
    """

    # Load Fluvius data for requested period
    grid_data = FluviusData(start_date=request.start_date, end_date=request.end_date)

    # Create House
    house = House(
        battery=Battery(max_capacity=request.battery_capacity, efficiency=request.efficiency),
        grid_data=grid_data
    )

    # If dynamic flag is set, switch management strategy
    if request.dynamic:
        house.battery_management_system = house.dynamic_battery_management_system

    # Run simulation
    import_energy, export_energy = house.simulate_household()

    return SimulationResponse(
        import_energy=import_energy,
        export_energy=export_energy,
        soc_history=house.battery.SOC_history,
        import_cost=house.import_cost,
        export_revenue=house.export_revenue,
        energy_cost=house.energy_cost
    )


@app.post("/optimize", response_model=SimulationResponse)
def optimize_battery(request: SimulationRequest):
    """
    Run battery capacity optimization and return optimal capacity + savings.
    """

    grid_data = FluviusData(start_date=request.start_date, end_date=request.end_date)
    house = House(
        battery=Battery(max_capacity=request.battery_capacity, efficiency=request.efficiency),
        grid_data=grid_data
    )

    capacities, savings, battery_cost = house.optimize_battery_capacity()
    
    return SimulationResponse(
        import_energy=house.import_energy_history,
        export_energy=house.export_energy_history,
        soc_history=house.battery.SOC_history,
        import_cost=house.import_cost,
        export_revenue=house.export_revenue,
        energy_cost=house.energy_cost,
        optimal_capacity=house.optimal_battery_capacity
    )
