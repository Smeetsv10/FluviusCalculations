from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, timedelta
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io
import base64
import uvicorn
import uuid
from typing import Dict


from classes.myHouse import House
from classes.myBattery import Battery
from classes.myFluviusData import FluviusData

# ---------------------------
# FastAPI app
# ---------------------------
app = FastAPI(title="Home Battery Sizing Tool API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------
# Globals
# ---------------------------
sessions: Dict[str, dict] = {}
house: Optional[House] = None

# ---------------------------
# Pydantic Models
# ---------------------------
class BatteryRequest(BaseModel):
    max_capacity: float = 0.0
    efficiency: float = 0.95
    variable_cost: float = 700
    fixed_costs: float = 1000
    battery_lifetime: int = 10
    C_rate: float = 0.25

class GridDataRequest(BaseModel):
    file_path: Optional[str] = None
    flag_EV: bool = True
    flag_PV: bool = True
    EAN_ID: int = -1
    start_date: Optional[str] = (date.today()- timedelta(days=7)).isoformat()
    end_date: Optional[str] = date.today().isoformat()
    csv_data: Optional[str] = None

class HouseRequest(BaseModel):
    location: Optional[str] = ""
    injection_price: float = 0.04
    price_per_kWh: float = 0.35
    battery: BatteryRequest
    grid_data: GridDataRequest
    
class SessionRequest(BaseModel):
    session_id: str
    house: HouseRequest

class SimulationResponse(BaseModel):
    import_energy: List[float] = []
    export_energy: List[float] = []
    soc_history: List[float] = []
    import_cost: float = 0.0
    export_revenue: float = 0.0
    energy_cost: float = 0.0
    optimal_capacity: Optional[float] = 0
    capacity_array: List[float] = []
    savings_list: List[float] = []
    annualized_battery_cost_array: List[float] = []
    base64Figure: Optional[str] = ""
    base64GridDataFigure: Optional[str] = ""
    message: Optional[str] = None
    data_info: Optional[dict] = {}

# ---------------------------
# Utility Functions
# ---------------------------
def plot_to_base64(fig) -> str:
    buffer = io.BytesIO()
    fig.savefig(buffer, format='png', dpi=150, bbox_inches='tight')
    buffer.seek(0)
    img_str = base64.b64encode(buffer.getvalue()).decode('utf-8')
    buffer.close()
    plt.close(fig)
    return img_str

# ---------------------------
# Routes
# ---------------------------
@app.get("/")
def root():
    return SimulationResponse(message="Fluvious Home Battery Sizing Tool API is running.")

@app.post("/load_data", response_model=SimulationResponse)
def load_data(request: HouseRequest):
    global house
    try:
        csv_data = request.grid_data.csv_data
        if not csv_data:
            return SimulationResponse(message="csv_data is required")

        # Initialize house if it doesn't exist
        if house is None:
            house = House()
        
        house.grid_data = FluviusData()
        house.grid_data.start_date = request.grid_data.start_date
        house.grid_data.end_date = request.grid_data.end_date
        house.grid_data.flag_EV = request.grid_data.flag_EV
        house.grid_data.flag_PV = request.grid_data.flag_PV
        house.grid_data.EAN_ID = request.grid_data.EAN_ID
        house.grid_data.file_path = request.grid_data.file_path

        df = house.grid_data.load_csv_from_bytes(csv_data)
        house.grid_data.load_data(df)
        house.grid_data.process_data()
        
        if house.grid_data.df.empty:
            return SimulationResponse(message="Dataframe is empty after loading")

        # Create session
        session_id = str(uuid.uuid4())
        sessions[session_id] = {"house": house}

        date_range = {
            "start": house.grid_data.df['datetime'].min().isoformat(),
            "end": house.grid_data.df['datetime'].max().isoformat()
        }

        return SimulationResponse(
            message="Data loaded successfully",
            data_info={
                "session_id": session_id,
                "num_records": len(house.grid_data.df),
                "date_range": date_range,
            },
        )

    except Exception as e:
        return SimulationResponse(message=f"Failed to load data: {e}")

@app.post("/plot_data", response_model=SimulationResponse)
def plot_data():
    global house
    if house is None or house.grid_data is None:
        return SimulationResponse(message="Grid data not loaded. Call /load_data first.")

    try:
        fig = house.grid_data.visualize_data()
        plot_b64 = plot_to_base64(fig)
        return SimulationResponse(base64GridDataFigure=plot_b64, message="Plotting completed successfully")
    except Exception as e:
        return SimulationResponse(message=f"Plotting failed: {e}")
    
@app.post("/simulate", response_model=SimulationResponse)
def simulate_household(request: HouseRequest):
    global house

    if house.grid_data is None:
        return SimulationResponse(message="Grid data not loaded. Call /load_data first.")
    house = House(
        battery=Battery(
            max_capacity=request.battery.max_capacity,
            efficiency=request.battery.efficiency,
            variable_cost=request.battery.variable_cost,
            fixed_costs=request.battery.fixed_costs,
            battery_lifetime=request.battery.battery_lifetime,
            C_rate=request.battery.C_rate,
        ),
        injection_price=request.injection_price,
        price_per_kWh=request.price_per_kWh
    )

    try:
        import_energy, export_energy = house.simulate_household()
        return SimulationResponse(
            import_energy=import_energy,
            export_energy=export_energy,
            soc_history=house.battery.SOC_history,
            import_cost=house.import_cost,
            export_revenue=house.export_revenue,
            energy_cost=house.energy_cost,
            message="Simulation completed successfully",
        )

    except Exception as e:
        return SimulationResponse(message=f"Simulation failed: {e}")

@app.post("/plot_simulation", response_model=SimulationResponse)
def plot_simulation():
    global house
    if house is None or house.grid_data is None:
        return SimulationResponse(message="Grid data not loaded. Call /load_data first.")

    try:
        fig = house.plot_energy_history()
        plot_b64 = plot_to_base64(fig)
        return SimulationResponse(
                import_energy=house.import_energy_history,
                export_energy=house.export_energy_history,
                soc_history=house.battery.SOC_history,
                import_cost=house.import_cost,
                export_revenue=house.export_revenue,
                energy_cost=house.energy_cost,
                message="Plotting completed successfully",
                base64Figure=plot_b64,
            )
    except Exception as e:
        return SimulationResponse(message=f"Plotting failed: {e}")

@app.post("/optimize", response_model=SimulationResponse)
def optimize_battery(request: HouseRequest):
    global house
    if house is None or house.grid_data is None:
        return SimulationResponse(message="Grid data not loaded. Call /load_data first.")

    try:
        capacity_array, savings_list, annualized_battery_cost_array = house.optimize_battery_capacity()
        return SimulationResponse(
            import_energy=house.import_energy_history,
            export_energy=house.export_energy_history,
            soc_history=house.battery.SOC_history,
            import_cost=house.import_cost,
            export_revenue=house.export_revenue,
            energy_cost=house.energy_cost,
            optimal_capacity=house.optimal_battery_capacity,
            capacity_array=capacity_array,
            savings_list=savings_list,
            annualized_battery_cost_array=annualized_battery_cost_array,
            message="Optimization completed successfully",
        )
    except Exception as e:
        return SimulationResponse(message=f"Optimization failed: {e}")


# ---------------------------
# Run server
# ---------------------------
if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
