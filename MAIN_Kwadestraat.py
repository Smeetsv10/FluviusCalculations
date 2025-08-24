import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from MAIN_DigitalMeter_Kwadestraat import get_smartmeter_data 
from MAIN_climateGridData import get_climate_for_location

### Smart meter data analysis for Kwadestraat ###
# 1. Import digital meter data
# 2. Find relative timeframe
# 3. Import climate grid data
# 4. Analyze and visualize data
#################################################

### Settings
SMARTMETER_FILEPATH = 'C:\\Users\\Smeets\\My Drive\\Personal\\Projects\\FluviusBerekeningen\\P1e-2025-6-01-2025-8-01.csv'

# 1. Import digital meter data
smartmeter_data = get_smartmeter_data(file_path=SMARTMETER_FILEPATH)  

# 2. Find relative timeframe
START_DATE = smartmeter_data['time'].min().strftime('%Y-%m-%d')
END_DATE = smartmeter_data['time'].max().strftime('%Y-%m-%d')

# 3. Import climate grid data
climate_data = get_climate_for_location(
        location_name="Hoegaarden, Belgium",
        start_date=START_DATE, 
        end_date=END_DATE
    )

# 4. Synchronize and combine data
def merge_data(smartmeter_data, climate_data):
    """Merge smart meter and climate data on date."""
    smartmeter_data['date'] = pd.to_datetime(smartmeter_data['time']).dt.date
    climate_data['date'] = pd.to_datetime(climate_data['day']).dt.date
    
    # Merge on date
    merged_data = pd.merge(smartmeter_data, climate_data, on='date', how='inner')
    print(f"Smart meter data: {len(smartmeter_data)} rows")
    print(f"Climate data: {len(climate_data)} rows") 
    print(f"Merged data: {len(merged_data)} rows")
    print(f"Date range in merged data: {merged_data['date'].min()} to {merged_data['date'].max()}")
    print(f"Available columns in merged data: {list(merged_data.columns)}")
    return merged_data

merged_data = merge_data(smartmeter_data, climate_data)

# 5. Comprehensive Correlation Analysis
def correlation_analysis(merged_data, var1_list, var2_list):
    """Perform correlation analysis between two variables."""
    
    for var1 in var1_list:
        plt.figure(figsize=(10, 6))
        plt.xlabel(var1)
        for var2 in var2_list:
            if var1 in merged_data.columns and var2 in merged_data.columns:
                correlation = merged_data[var1].corr(merged_data[var2])
                print(f"Correlation between {var1} and {var2}: {correlation:.4f}")
                
                plt.scatter(merged_data[var1], merged_data[var2], alpha=0.5, label=var2)
                plt.grid()
        plt.legend()
    plt.show()
    
    return correlation

correlation_analysis(merged_data, ['temp_avg'], ['total_daily_export'])
