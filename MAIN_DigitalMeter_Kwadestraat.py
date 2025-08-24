import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize, minimize_scalar
from datetime import datetime, timedelta

# Default file path
DEFAULT_FILE_PATH = 'C:\\Users\\Smeets\\My Drive\\Personal\\Projects\\FluviusBerekeningen\\P1e-2025-6-01-2025-8-01.csv'
DEFAULT_FILE_PATH = "C:\\Users\\Victor\\My Drive (victor.smeets99@gmail.com)\\Personal\\Projects\\FluviusBerekeningen\\gridData\\P1e-2025-7-01-2025-8-24.csv"

def LoadData(start_date=None, end_date=None, file_path=None):
    """
    Load smart meter data from CSV file.
    
    Parameters:
    file_path (str, optional): Path to the CSV file. If None, uses default path.
    
    Returns:
    pandas.DataFrame: Raw data from CSV file with time column converted to datetime
    """
    if file_path is None:
        file_path = DEFAULT_FILE_PATH
    print(f"Loading data from: {file_path}")
    
    # Load the CSV data
    data = pd.read_csv(file_path, sep=',')
    
    # Debug: print column names
    columnNames = data.columns.to_list()
    print("Column names:", columnNames)
    
    # Convert time column to datetime for better processing
    data['time'] = pd.to_datetime(data['time'])


    # Filter data by date range
    if start_date is not None:
        data = data[data['time'] >= start_date]
    if end_date is not None:
        data = data[data['time'] <= end_date]

    # Reset index after filtering
    data = data.reset_index(drop=True)

    return data

def ProcessData(data):
    """
    Process raw smart meter data to calculate daily consumption/production values.
    
    Parameters:
    data (pandas.DataFrame): Raw smart meter data
    
    Returns:
    pandas.DataFrame: Processed data with daily values and calculated totals
    """
    print("Processing smart meter data...")
    
    # Remove rows with missing data
    smartmeter_data = data.dropna().copy()
    print(f"After removing missing data: {len(smartmeter_data)} rows")
    
    # Sort by time and reset index
    smartmeter_data = smartmeter_data.sort_values('time').reset_index(drop=True)
    
    # Also keep cumulative totals for comparison
    smartmeter_data['cumulative_import'] = smartmeter_data['Import T1 kWh'] + smartmeter_data['Import T2 kWh']
    smartmeter_data['cumulative_export'] = smartmeter_data['Export T1 kWh'] + smartmeter_data['Export T2 kWh']
    smartmeter_data['cumulative_net'] = smartmeter_data['cumulative_import'] - smartmeter_data['cumulative_export']
    
    # Since values are cumulative, calculate daily differences to get actual daily consumption
    smartmeter_data['Import T1 kWh'] = smartmeter_data['Import T1 kWh'].diff().fillna(smartmeter_data['Import T1 kWh'].iloc[0])
    smartmeter_data['Import T2 kWh'] = smartmeter_data['Import T2 kWh'].diff().fillna(smartmeter_data['Import T2 kWh'].iloc[0])
    smartmeter_data['Export T1 kWh'] = smartmeter_data['Export T1 kWh'].diff().fillna(smartmeter_data['Export T1 kWh'].iloc[0])
    smartmeter_data['Export T2 kWh'] = smartmeter_data['Export T2 kWh'].diff().fillna(smartmeter_data['Export T2 kWh'].iloc[0])

    # Reset first row of daily_day_import to 0
    smartmeter_data['Import T1 kWh'].iloc[0] = 0
    smartmeter_data['Import T2 kWh'].iloc[0] = 0
    smartmeter_data['Export T1 kWh'].iloc[0] = 0
    smartmeter_data['Export T2 kWh'].iloc[0] = 0

    # Calculate total daily import and export
    smartmeter_data['Total Import kWh'] = smartmeter_data['Import T1 kWh'] + smartmeter_data['Import T2 kWh']
    smartmeter_data['Total Export kWh'] = smartmeter_data['Export T1 kWh'] + smartmeter_data['Export T2 kWh']
    smartmeter_data['Total T1 kWh'] = smartmeter_data['Import T1 kWh'] - smartmeter_data['Export T1 kWh']
    smartmeter_data['Total T2 kWh'] = smartmeter_data['Import T2 kWh'] - smartmeter_data['Export T2 kWh']
    smartmeter_data['Net Consumption kWh'] = smartmeter_data['Total Import kWh'] - smartmeter_data['Total Export kWh']

    # Also keep cumulative totals for comparison
    print("Data processing completed successfully")
    return smartmeter_data

def VisualizeData(smartmeter_data):
    """
    Create comprehensive visualization of smart meter data.
    
    Parameters:
    smartmeter_data (pandas.DataFrame): Processed smart meter data from ProcessData function
    """
    print("Creating visualizations...")
    
    # Create comprehensive visualization
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    fig.suptitle('Energy Consumption and Production Analysis', fontsize=16, fontweight='bold')

    # Plot 1: Daily Import vs Export (actual daily values)
    axes[0, 0].plot(smartmeter_data['time'], smartmeter_data['Total Import kWh'], 
                   label='Daily Import', color='red', marker='o', markersize=4)
    axes[0, 0].plot(smartmeter_data['time'], smartmeter_data['Total Export kWh'], 
                   label='Daily Export', color='green', marker='s', markersize=4)
    axes[0, 0].set_title('Daily Energy Import vs Export')
    axes[0, 0].set_xlabel('Date')
    axes[0, 0].set_ylabel('Daily Energy (kWh)')
    axes[0, 0].legend()
    axes[0, 0].grid(True, alpha=0.3)
    axes[0, 0].tick_params(axis='x', rotation=45)

    # Plot 2: Day vs Night Import/Export breakdown
    axes[0, 1].plot(smartmeter_data['time'], smartmeter_data['Import T1 kWh'], 
                   label='Day Import (T1)', color='orange', marker='o', markersize=3)
    axes[0, 1].plot(smartmeter_data['time'], smartmeter_data['Import T2 kWh'], 
                   label='Night Import (T2)', color='blue', marker='o', markersize=3)
    axes[0, 1].plot(smartmeter_data['time'], smartmeter_data['Export T1 kWh'], 
                   label='Day Export (T1)', color='yellow', marker='s', markersize=3)
    axes[0, 1].plot(smartmeter_data['time'], smartmeter_data['Export T2 kWh'], 
                   label='Night Export (T2)', color='purple', marker='s', markersize=3)
    axes[0, 1].set_title('Day/Night Energy Import/Export Breakdown')
    axes[0, 1].set_xlabel('Date')
    axes[0, 1].set_ylabel('Energy (kWh)')
    axes[0, 1].legend(fontsize=8)
    axes[0, 1].grid(True, alpha=0.3)
    axes[0, 1].tick_params(axis='x', rotation=45)

    # Plot 3: Daily Net Consumption
    axes[0, 2].plot(smartmeter_data['time'], smartmeter_data['Net Consumption kWh'], 
                   label='Daily Net Consumption', color='darkred', marker='d', markersize=4)
    axes[0, 2].axhline(y=0, color='black', linestyle='--', alpha=0.7)
    axes[0, 2].fill_between(smartmeter_data['time'], smartmeter_data['Net Consumption kWh'], 0, 
                           where=(smartmeter_data['Net Consumption kWh'] >= 0), 
                           color='red', alpha=0.3, label='Net Import')
    axes[0, 2].fill_between(smartmeter_data['time'], smartmeter_data['Net Consumption kWh'], 0, 
                           where=(smartmeter_data['Net Consumption kWh'] < 0), 
                           color='green', alpha=0.3, label='Net Export')
    axes[0, 2].set_title('Net Energy Consumption')
    axes[0, 2].set_xlabel('Date')
    axes[0, 2].set_ylabel('Net Energy (kWh)')
    axes[0, 2].legend()
    axes[0, 2].grid(True, alpha=0.3)
    axes[0, 2].tick_params(axis='x', rotation=45)

    # Plot 4: Cumulative Import vs Export (original cumulative values)
    axes[1, 0].plot(smartmeter_data['time'], smartmeter_data['Total Import kWh'], 
                   label='Cumulative Import', color='red', marker='o', markersize=4)
    axes[1, 0].plot(smartmeter_data['time'], smartmeter_data['Total Export kWh'], 
                   label='Cumulative Export', color='green', marker='s', markersize=4)
    axes[1, 0].set_title('Cumulative Energy Import vs Export')
    axes[1, 0].set_xlabel('Date')
    axes[1, 0].set_ylabel('Cumulative Energy (kWh)')
    axes[1, 0].legend()
    axes[1, 0].grid(True, alpha=0.3)
    axes[1, 0].tick_params(axis='x', rotation=45)

    # Plot 5: Bar chart of daily consumption/production
    if len(smartmeter_data) > 0:
        bar_width = 0.35
        x_pos = range(len(smartmeter_data))
        axes[1, 1].bar([x - bar_width/2 for x in x_pos], smartmeter_data['Total Import kWh'], 
                       bar_width, label='Daily Import', alpha=0.7, color='red')
        axes[1, 1].bar([x + bar_width/2 for x in x_pos], smartmeter_data['Total Export kWh'], 
                       bar_width, label='Daily Export', alpha=0.7, color='green')
        
        # Set x-axis labels to dates (show every nth date to avoid crowding)
        step = max(1, len(smartmeter_data) // 10)
        axes[1, 1].set_xticks([x for x in x_pos[::step]])
        axes[1, 1].set_xticklabels([smartmeter_data['time'].iloc[i].strftime('%m-%d') for i in x_pos[::step]], rotation=45)
        
        axes[1, 1].set_title('Daily Energy Comparison (Bar Chart)')
        axes[1, 1].set_xlabel('Date')
        axes[1, 1].set_ylabel('Daily Energy (kWh)')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)

    # Plot 6: Summary statistics
    axes[1, 2].axis('off')
    stats_text = f"""DAILY ENERGY STATISTICS

Average Import: {smartmeter_data['Total Import kWh'].mean():.2f} kWh
Average Export: {smartmeter_data['Total Export kWh'].mean():.2f} kWh
Average Net Consumption: {smartmeter_data['Net Consumption kWh'].mean():.2f} kWh

Max Import: {smartmeter_data['Total Import kWh'].max():.2f} kWh
Max Export: {smartmeter_data['Total Export kWh'].max():.2f} kWh

Min Import: {smartmeter_data['Total Import kWh'].min():.2f} kWh
Min Export: {smartmeter_data['Total Export kWh'].min():.2f} kWh

Total Period Import: {smartmeter_data['Total Import kWh'].sum():.2f} kWh
Total Period Export: {smartmeter_data['Total Export kWh'].sum():.2f} kWh
Total Period Net Consumption: {smartmeter_data['Net Consumption kWh'].sum():.2f} kWh

Days with Net Import: {(smartmeter_data['Net Consumption kWh'] > 0).sum()}
Days with Net Export: {(smartmeter_data['Net Consumption kWh'] < 0).sum()}
"""
    axes[1, 2].text(0.1, 0.9, stats_text, transform=axes[1, 2].transAxes, 
                    fontsize=10, verticalalignment='top', fontfamily='monospace',
                    bbox=dict(boxstyle="round,pad=0.3", facecolor="lightgray", alpha=0.5))

    plt.tight_layout()
    plt.show()
    print("Visualization completed successfully")

def PrintStatistics(smartmeter_data):
    """
    Print detailed statistics about the smart meter data.
    
    Parameters:
    smartmeter_data (pandas.DataFrame): Processed smart meter data from ProcessData function
    """
    print("\n=== DAILY ENERGY CONSUMPTION SUMMARY ===")
    print(f"Data period: {smartmeter_data['time'].min().strftime('%Y-%m-%d')} to {smartmeter_data['time'].max().strftime('%Y-%m-%d')}")
    print(f"Total data points: {len(smartmeter_data)} days")

    print("\n--- DAILY AVERAGES ---")
    print(f"Average Import: {smartmeter_data['Total Import kWh'].mean():.2f} kWh")
    print(f"  - Day Import (T1): {smartmeter_data['Import T1 kWh'].mean():.2f} kWh")
    print(f"  - Night Import (T2): {smartmeter_data['Import T2 kWh'].mean():.2f} kWh")

    print(f"Average Export: {smartmeter_data['Total Export kWh'].mean():.2f} kWh")
    print(f"  - Day Export (T1): {smartmeter_data['Export T1 kWh'].mean():.2f} kWh")
    print(f"  - Night Export (T2): {smartmeter_data['Export T2 kWh'].mean():.2f} kWh")

    print(f"Average Net Consumption: {smartmeter_data['Net Consumption kWh'].mean():.2f} kWh")

    print("\n--- PERIOD TOTALS ---")
    print(f"Total Period Import: {smartmeter_data['Total Import kWh'].sum():.2f} kWh")
    print(f"Total Period Export: {smartmeter_data['Total Export kWh'].sum():.2f} kWh")
    print(f"Total Period Net Consumption: {smartmeter_data['Net Consumption kWh'].sum():.2f} kWh")

    print("\n--- DAILY EXTREMES ---")
    max_import_idx = smartmeter_data['Total Import kWh'].idxmax()
    min_import_idx = smartmeter_data['Total Import kWh'].idxmin()
    max_export_idx = smartmeter_data['Total Export kWh'].idxmax()
    min_export_idx = smartmeter_data['Total Export kWh'].idxmin()

    print(f"Highest Daily Import: {smartmeter_data['Total Import kWh'].max():.2f} kWh on {smartmeter_data.loc[max_import_idx, 'time'].strftime('%Y-%m-%d')}")
    print(f"Lowest Daily Import: {smartmeter_data['Total Import kWh'].min():.2f} kWh on {smartmeter_data.loc[min_import_idx, 'time'].strftime('%Y-%m-%d')}")
    print(f"Highest Daily Export: {smartmeter_data['Total Export kWh'].max():.2f} kWh on {smartmeter_data.loc[max_export_idx, 'time'].strftime('%Y-%m-%d')}")
    print(f"Lowest Daily Export: {smartmeter_data['Total Export kWh'].min():.2f} kWh on {smartmeter_data.loc[min_export_idx, 'time'].strftime('%Y-%m-%d')}")

    print(f"\n--- CONSUMPTION PATTERNS ---")
    print(f"Days with net import (consuming more than producing): {(smartmeter_data['Net Consumption kWh'] > 0).sum()} days")
    print(f"Days with net export (producing more than consuming): {(smartmeter_data['Net Consumption kWh'] < 0).sum()} days")
    print(f"Days with perfect balance: {(smartmeter_data['Net Consumption kWh'] == 0).sum()} days")

    if smartmeter_data['Net Consumption kWh'].sum() > 0:
        print(f"\nOverall Status: Net consumer (imported {smartmeter_data['Net Consumption kWh'].sum():.2f} kWh more than exported)")
    else:
        print(f"\nOverall Status: Net producer (exported {abs(smartmeter_data['Net Consumption kWh'].sum()):.2f} kWh more than imported)")

    print("\n--- CUMULATIVE TOTALS (at end of period) ---")
    print(f"Cumulative Import: {smartmeter_data['cumulative_import'].iloc[-1]:.2f} kWh")
    print(f"Cumulative Export: {smartmeter_data['cumulative_export'].iloc[-1]:.2f} kWh")
    print(f"Cumulative Net: {smartmeter_data['cumulative_net'].iloc[-1]:.2f} kWh")

def get_smartmeter_data(start_date=None, end_date=None, file_path=None):
    """
    Main function to load, process and return smart meter data for external use.
    
    Parameters:
    file_path (str, optional): Path to the CSV file. If None, uses default path.
    
    Returns:
    pandas.DataFrame: Processed smart meter data with daily values and calculated totals
    """
    try:
        # Load the data
        raw_data = LoadData(start_date, end_date,file_path)
        
        # Process the data
        processed_data = ProcessData(raw_data)
        
        print(f"\nSuccessfully processed smart meter data with {len(processed_data)} daily records")
        return processed_data
        
    except Exception as e:
        print(f"Error processing smart meter data: {str(e)}")
        return None

def run_full_analysis(start_date=None, end_date=None, file_path=None, show_plots=True, show_stats=True):
    """
    Run complete smart meter analysis including visualization and statistics.
    
    Parameters:
    file_path (str, optional): Path to the CSV file. If None, uses default path.
    show_plots (bool): Whether to display visualizations
    show_stats (bool): Whether to print statistics
    
    Returns:
    pandas.DataFrame: Processed smart meter data
    """
    # Get the processed data
    data = get_smartmeter_data(start_date, end_date, file_path)
    
    if data is not None:
        # Show visualizations if requested
        if show_plots:
            VisualizeData(data)
        
        # Print statistics if requested
        if show_stats:
            PrintStatistics(data)
    
    return data

def simulate_battery_operation(smartmeter_data, battery_capacity_kwh=10, battery_efficiency=0.95, 
                              import_price=0.35, export_price=0.04, max_charge_rate=None, C_rate=1):
    """
    Simulate battery operation for given capacity and calculate financial benefits.
    
    Parameters:
    smartmeter_data (pd.DataFrame): Processed smart meter data
    battery_capacity_kwh (float): Battery capacity in kWh
    battery_efficiency (float): Round-trip efficiency (0-1)
    import_price (float): Price per kWh for importing electricity (€/kWh)
    export_price (float): Price per kWh for exporting electricity (€/kWh)
    max_charge_rate (float): Maximum charge/discharge rate in kWh (if None, uses capacity)
    c_rate (float): Charge/discharge rate in C (default 1C)
    
    Source: https://dashboard.vreg.be/report/DMR_Prijzen_elektriciteit.html
    
    Returns:
    dict: Simulation results including costs, savings, and battery utilization
    """
    if max_charge_rate is None:
        max_charge_rate = C_rate * battery_capacity_kwh  # Can charge/discharge at 1C rate / unit time
    
    # Initialize battery state
    battery_soc = 0.50  # State of charge
    def current_battery_capacity(battery_soc):
        return battery_soc * battery_capacity_kwh  # Current capacity stored in the battery battery (kWh)

    def available_battery_capacity(battery_soc):
        return (1-battery_soc) * battery_capacity_kwh  # Current capacity available for staorage in the battery (kWh)

    # Track daily operations
    results_list = []
    
    for idx, row in smartmeter_data.iterrows():
        tmp_import = row['Total Import kWh']
        tmp_export = row['Total Export kWh']
        net_consumption = tmp_import - tmp_export

        battery_charge = 0  # Energy charged to battery
        battery_discharge = 0  # Energy discharged from battery
        grid_import = 0  # Energy imported from grid
        grid_export = 0  # Energy exported to grid

        if net_consumption < 0:  # Excess solar production
            excess_energy = abs(net_consumption)
            
            # Try to charge battery first
            charge_limit = min(max_charge_rate, available_battery_capacity(battery_soc))
            battery_charge = min(excess_energy, charge_limit)
            battery_soc += (battery_charge / battery_capacity_kwh)
            
            # Export remaining energy
            remaining_excess = excess_energy - battery_charge
            grid_export = remaining_excess
            
        else:  # Net consumption (need energy)
            energy_needed = net_consumption
            
            # Try to discharge battery first
            discharge_limit = min(max_charge_rate, current_battery_capacity(battery_soc))
            battery_discharge = min(energy_needed, discharge_limit)
            battery_soc -= (battery_discharge / battery_capacity_kwh)
            
            # Import remaining energy from grid
            remaining_need = energy_needed - (battery_discharge * battery_efficiency)
            if remaining_need < 0:
                raise ValueError("Battery SOC cannot be negative after discharge.")
            grid_import = max(0, remaining_need)
        
        # Calculate daily costs
        import_cost = grid_import * import_price
        export_revenue = grid_export * export_price
        net_cost = import_cost - export_revenue
        
        results_list.append({
            'date': row['time'],
            'original_import': tmp_import,
            'original_export': tmp_export,
            'net_consumption': net_consumption,
            'battery_charge': battery_charge,
            'battery_discharge': battery_discharge,
            'battery_soc': battery_soc,
            'grid_import': grid_import,
            'grid_export': grid_export,
            'import_cost': import_cost,
            'export_revenue': export_revenue,
            'net_daily_cost': net_cost
        })
    
    # Calculate summary statistics
    results_df = pd.DataFrame(results_list)
    results = analyze_battery_results(results_df, battery_capacity_kwh)
    
    return results_df, results

def analyze_battery_results(results_df, battery_capacity_kwh, flagPlot = False):
    """
    Analyze battery operation results and calculate key metrics.
    """
    # Calculate total savings and costs
    total_cost = results_df['import_cost'].sum() - results_df['export_revenue'].sum()
    total_cycles = results_df['battery_charge'].sum() / battery_capacity_kwh

    # Print summary
    print("\n=== BATTERY OPERATION ANALYSIS ===")
    print(f"Total Cost (used power): €{total_cost:.2f}")
    print(f"Total Battery Cycles: {total_cycles:.2f}")
    
    # Plot results
    if flagPlot:
        plt.figure(figsize=(12, 6))
        plt.plot(results_df['date'], results_df['battery_soc'], label='Battery SOC', color='blue', marker='o', markersize=3)
        plt.title('Battery State of Charge Over Time')
        plt.xlabel('Date')
        plt.ylabel('State of Charge (%)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.show()
        
        plt.figure(figsize=(12, 6))
        net_grid_usage = results_df['grid_import'] - results_df['grid_export']
        plt.plot(results_df['date'], net_grid_usage, label='Net Daily Grid Usage', color='darkred', marker='d', markersize=4)
        plt.axhline(y=0, color='black', linestyle='--', alpha=0.7)
        plt.fill_between(results_df['date'], net_grid_usage, 0, 
                        where=(net_grid_usage >= 0), 
                        color='red', alpha=0.3, label='Daily Net Import')
        plt.fill_between(results_df['date'], net_grid_usage, 0, 
                        where=(net_grid_usage < 0), 
                        color='green', alpha=0.3, label='Daily Net Export')
        plt.title('Net Daily Grid Usage Over Time (With Battery)')
        plt.xlabel('Date')
        plt.ylabel('Net Grid Usage (kWh)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.show()

    return {
        'total_cost': total_cost,
        'total_cycles': total_cycles
    }

def optimize_battery_capacity(
    smartmeter_data,
    battery_efficiency=0.95,
    import_price=0.35,
    export_price=0.04,
    max_capacity_kwh=20,
    battery_cost_per_kwh=700,
    annualization_factor=10,
    C_rate=0.25
):
    # Optimize the battery capacity based on the price
    savings_list = []
    no_points = 50
    capacity_array = np.linspace(0, max_capacity_kwh, no_points)
    
    # Calculate scenario without battery:
    results_df_no_battery, results_no_battery = simulate_battery_operation(
        smartmeter_data,
        battery_capacity_kwh=1e-3,
        battery_efficiency=battery_efficiency,
        import_price=import_price,
        export_price=export_price,
        C_rate=C_rate,
    )
    time_range = (results_df_no_battery['date'].max() - results_df_no_battery['date'].min()).days
    base_cost = results_no_battery["total_cost"]/ time_range * 365
    
    for i in capacity_array:
        battery_capacity_kwh = i
        battery_cost_total = battery_capacity_kwh * battery_cost_per_kwh
        annualized_cost = battery_cost_total / annualization_factor
        _, results =  simulate_battery_operation(
                                smartmeter_data,
                                battery_capacity_kwh=battery_capacity_kwh,
                                battery_efficiency=battery_efficiency,
                                import_price=import_price,
                                export_price=export_price,
                                C_rate=C_rate,
                            )
        tmp_cost = (results["total_cost"]/ time_range)*365 + annualized_cost
        savings_list.append(tmp_cost-base_cost)

    # Calculate optinal solution 
    optimal_battery_capacity = capacity_array[savings_list.index(min(savings_list))]
    optimal_battery_cost = optimal_battery_capacity * battery_cost_per_kwh
    optimal_annualized_cost = optimal_battery_cost / annualization_factor
    optimal_df, optimal_results = simulate_battery_operation(
        smartmeter_data,
        battery_capacity_kwh=optimal_battery_capacity,
        battery_efficiency=battery_efficiency,
        import_price=import_price,
        export_price=export_price,
        C_rate=C_rate,
    )
    optimal_net_savings = (optimal_results["total_cost"]/ time_range)*365 - optimal_annualized_cost


    plt.figure(figsize=(10, 5))
    plt.plot(capacity_array, savings_list, marker='o')
    plt.title('Annualized Cost Savings vs Battery Capacity (i.c.t no battery)')
    plt.xlabel('Battery Capacity (kWh)')
    plt.ylabel('Annualized Cost Savings (€)')
    plt.grid(True)
    plt.show()
        
    return {
        "optimal_capacity_kwh": optimal_battery_capacity,
        "optimal_results": optimal_results,
        "optimal_annualized_cost": optimal_annualized_cost,
        "optimal_net_savings": optimal_net_savings,
        "simulation_df": optimal_df,
    }

# Main execution block
if __name__ == "__main__":
    # Run the full analysis with default settings
    # smartmeter_data = run_full_analysis(start_date="2025-07-28", end_date="2025-08-08")
    smartmeter_data = run_full_analysis()
    # results_df, results = simulate_battery_operation(smartmeter_data)
    # print(results_df.head())
    
    # Run battery optimization analysis
    results = optimize_battery_capacity(smartmeter_data)
    print("🔋 Optimal Battery Sizing Results")
    print(f"  Optimal Capacity      : {results['optimal_capacity_kwh']:.2f} kWh")
    print(f"  Annualized Cost       : €{results['optimal_annualized_cost']:.2f} / year")
    print(f"  Net Annual Savings    : €{results['optimal_net_savings']:.2f} / year")

    print("\n📊 Simulation Results:")
    for key, val in results["optimal_results"].items():
        if isinstance(val, (int, float)):
            print(f"  {key}: {val:.2f}")
        else:
            print(f"  {key}: {val}")

    # If you want to see the timeseries (battery operation for each timestep):
    df = results["simulation_df"]
    print("\nFirst 5 rows of simulation output:")
    print(df.head())
