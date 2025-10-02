import pandas as pd
import math
from geopy.geocoders import Nominatim
import matplotlib.pyplot as plt
import os
from datetime import datetime
import glob
CLIMATEDATA_FILEFOLDER = 'C:\\Users\\Smeets\\My Drive\\Personal\\Projects\\FluviusBerekeningen\\climateGridData\\'
CLIMATEDATA_FILEFOLDER = "C:\\Users\\Victor\\My Drive (victor.smeets99@gmail.com)\\Personal\\Projects\\FluviusBerekeningen\\climateGridData\\"

# ---------- 1. Haversine distance function ----------
def haversine(lat1, lon1, lat2, lon2):
    """Calculate the great-circle distance between two points in km."""
    R = 6371.0  # Earth radius in km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

# ---------- 2. Load metadata ----------
def load_metadata(metadata_file):
    """Load the climate grid metadata with pixel coordinates."""
    return pd.read_csv(metadata_file, sep=";")

# ---------- 3. Load climate data ----------
def load_climate_data(climate_file):
    """Load the daily gridded climate data."""
    return pd.read_csv(climate_file, sep=";")

# ---------- 4. Geocode location ----------
def get_lat_lon(location_name):
    """Return (lat, lon) for a given location name."""
    geolocator = Nominatim(user_agent="climate_grid_locator")
    location = geolocator.geocode(location_name)
    if location:
        return location.latitude, location.longitude
    else:
        raise ValueError(f"Location '{location_name}' not found")

# ---------- 5. Find nearest pixel ----------
def find_nearest_pixel(lat, lon, metadata_df):
    """Find the nearest pixel ID to given coordinates."""
    distances = metadata_df.apply(
        lambda row: haversine(lat, lon, row["PIXEL_LAT_CENTER"], row["PIXEL_LON_CENTER"]),
        axis=1
    )
    nearest_index = distances.idxmin()
    return metadata_df.iloc[nearest_index]["PIXEL_ID"]

# ---------- 6. Get climate data files in date range ----------
def get_climate_files_in_range(start_date, end_date, folder_path):
    """Get all climate data files that fall within the specified date range."""
    # Convert string dates to datetime objects if needed
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, '%Y-%m-%d')
    if isinstance(end_date, str):
        end_date = datetime.strptime(end_date, '%Y-%m-%d')
    
    # Find all climate grid CSV files in the folder
    pattern = os.path.join(folder_path, "climategrid_*.csv")
    all_files = glob.glob(pattern)
    
    files_in_range = []
    
    for file_path in all_files:
        # Extract date from filename (assuming format: climategrid_YYYYMM.csv)
        filename = os.path.basename(file_path)
        if filename.startswith("climategrid_") and filename.endswith(".csv"):
            try:
                # Extract YYYYMM from filename
                date_str = filename.replace("climategrid_", "").replace(".csv", "")
                if len(date_str) == 6:  # YYYYMM format
                    file_year = int(date_str[:4])
                    file_month = int(date_str[4:6])
                    file_date = datetime(file_year, file_month, 1)
                    
                    # Check if file date falls within range (month-wise check)
                    if start_date.replace(day=1) <= file_date <= end_date.replace(day=28):
                        files_in_range.append(file_path)
                        
            except (ValueError, IndexError):
                print(f"Warning: Could not parse date from filename {filename}")
                continue
    
    return sorted(files_in_range)

# ---------- 7. Load and concatenate multiple climate data files ----------
def load_multiple_climate_files(file_list):
    """Load and concatenate multiple climate data files."""
    if not file_list:
        raise ValueError("No climate data files found in the specified date range")
    
    dataframes = []
    print(f"Loading {len(file_list)} climate data files...")
    
    for file_path in file_list:
        try:
            df = pd.read_csv(file_path, sep=";")
            filename = os.path.basename(file_path)
            print(f"  - Loaded {filename}: {len(df)} rows")
            dataframes.append(df)
        except Exception as e:
            print(f"Warning: Could not load {file_path}: {str(e)}")
            continue
    
    if not dataframes:
        raise ValueError("No valid climate data files could be loaded")
    
    # Concatenate all dataframes
    concatenated_df = pd.concat(dataframes, ignore_index=True)
    
    # Sort by date if date column exists
    if 'date' in concatenated_df.columns:
        concatenated_df['date'] = pd.to_datetime(concatenated_df['date'])
        concatenated_df = concatenated_df.sort_values('date')
    
    print(f"Total concatenated data: {len(concatenated_df)} rows")
    return concatenated_df

# ---------- 8. Get climate data for a pixel with date range ----------
def get_climate_for_location(location_name, start_date, end_date, metadata_file=None):
    """
    Return climate data for nearest pixel to a location within specified date range.
    
    Parameters:
    location_name (str): Name of the location to search for
    start_date (str or datetime): Start date in 'YYYY-MM-DD' format
    end_date (str or datetime): End date in 'YYYY-MM-DD' format
    metadata_file (str, optional): Path to metadata file. If None, uses default path.
    
    Returns:
    pandas.DataFrame: Climate data for the location and date range
    """
    # Set default metadata file path if not provided
    if metadata_file is None:
        metadata_file = os.path.join(CLIMATEDATA_FILEFOLDER, "climategrid_pixel_metadata.csv")
    
    print(f"Getting climate data for '{location_name}' from {start_date} to {end_date}")
    
    # Load metadata
    print("Loading metadata...")
    metadata_df = load_metadata(metadata_file)
    
    # Get location coordinates
    print(f"Geocoding location: {location_name}")
    lat, lon = get_lat_lon(location_name)
    print(f"Found coordinates: {lat:.4f}, {lon:.4f}")
    
    # Get climate files in date range (daily)
    if False:
        # Find nearest pixel
        pixel_id = find_nearest_pixel(lat, lon, metadata_df)
        print(f"Nearest pixel ID: {pixel_id}")
        climate_files = get_climate_files_in_range(start_date, end_date, CLIMATEDATA_FILEFOLDER)
        if not climate_files:
            raise ValueError(f"No climate data files found for date range {start_date} to {end_date}")
        climate_df = load_multiple_climate_files(climate_files)
    
        # Filter climate data for the specific pixel
        climate_pixel_data = climate_df[climate_df["pixel_id"] == pixel_id].copy()
        
        # Filter by exact date range if day column exists
        if 'day' in climate_pixel_data.columns:
            climate_pixel_data['day'] = pd.to_datetime(climate_pixel_data['day'])
            
            # Convert string dates to datetime if needed
            if isinstance(start_date, str):
                start_date = datetime.strptime(start_date, '%Y-%m-%d')
            if isinstance(end_date, str):
                end_date = datetime.strptime(end_date, '%Y-%m-%d')
            
            # Filter by exact date range using the 'day' column
            mask = (climate_pixel_data['day'] >= start_date) & (climate_pixel_data['day'] <= end_date)
            climate_pixel_data = climate_pixel_data[mask]
    else:
        climate_df = load_climate_data_hourly(start_date, end_date, lat, lon)

        # Remove columns FID, the_geom, code, qc_flags
        climate_pixel_data = climate_df.drop(columns=['FID', 'the_geom', 'code', 'qc_flags'], errors='ignore')
        print(climate_pixel_data.head())
        climate_pixel_data = fill_missing_hourly_data(climate_pixel_data)
        
    print(f"Final filtered data: {len(climate_pixel_data)} rows for pixel {pixel_id}")
    
    return climate_pixel_data

def fill_missing_hourly_data(df):
    """
    Fill missing timestamps and NaN values in the hourly climate DataFrame using interpolation.
    Assumes 'timestamp' is a datetime column and is sorted.
    """
    # Set timestamp as index
    df = df.set_index('timestamp').sort_index()
    # Create a complete hourly timestamp index
    full_index = pd.date_range(df.index.min(), df.index.max(), freq='H')
    df = df.reindex(full_index)
    # Interpolate numeric columns
    numeric_cols = df.select_dtypes(include=['float64', 'int64']).columns
    df[numeric_cols] = df[numeric_cols].interpolate(method='linear')
    # Optionally, fill remaining NaNs (e.g., forward fill for non-numeric)
    df = df.ffill().bfill()
    # Reset index to restore 'timestamp' column
    df = df.reset_index().rename(columns={'index': 'timestamp'})
    return df

def load_climate_data_hourly(start_date, end_date, lat, lon, csv_path="aws_1hour.csv"):
    """
    Reads the hourly climate data CSV, filters by date and nearest lat/lon, and returns a pandas DataFrame.
    """
    # Load CSV and parse timestamp
    df = pd.read_csv(
        CLIMATEDATA_FILEFOLDER+csv_path,
        parse_dates=["timestamp"],
        na_values=["", " "]
    )
    # Extract lat/lon from 'the_geom' column
    df[["lat", "lon"]] = df["the_geom"].str.extract(r'POINT \(([-\d\.]+) ([-\d\.]+)\)').astype(float)
    
    # Find nearest point
    distances = df.apply(lambda row: haversine(lat, lon, row["lat"], row["lon"]), axis=1)
    nearest_idx = distances.idxmin()
    nearest_lat = df.loc[nearest_idx, "lat"]
    nearest_lon = df.loc[nearest_idx, "lon"]
    # Filter for nearest lat/lon
    df_pixel = df[(df["lat"] == nearest_lat) & (df["lon"] == nearest_lon)].copy()
    # Filter by date range
    if isinstance(start_date, str):
        start_date = pd.to_datetime(start_date)
    if isinstance(end_date, str):
        end_date = pd.to_datetime(end_date)
    mask = (df_pixel["timestamp"] >= start_date) & (df_pixel["timestamp"] <= end_date)
    df_pixel = df_pixel[mask]
    return df_pixel

# ---------- Example usage ----------
if __name__ == "__main__":
    # Example with date range
    climate_data = get_climate_for_location(
        location_name="Hoegaarden, Belgium",
        start_date="2025-06-01", 
        end_date="2025-07-25"
    )
    
    print(f"Retrieved {len(climate_data)} days of climate data")
    print("\nFirst few rows:")
    print(climate_data.head())
    
    print("\nColumn names:")
    print(climate_data.columns.tolist())
    
    if 'date' in climate_data.columns:
        print(f"\nDate range in data: {climate_data['date'].min()} to {climate_data['date'].max()}")
    
    # Example with multiple months
    print("\n" + "="*50)
    print("Example with multiple months:")
    multi_month_data = get_climate_for_location(
        location_name="Brussels, Belgium",
        start_date="2025-06-01",
        end_date="2025-08-31"
    )
    print(f"Retrieved {len(multi_month_data)} days of climate data across multiple months")

    hourly_data = get_hourly_climate_df()
    print(hourly_data.head())