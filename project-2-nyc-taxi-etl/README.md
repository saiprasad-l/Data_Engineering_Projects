# 🚕 Project 2: NYC Yellow Taxi Data Pipeline (2023)

This project simulates a real-world data pipeline using NYC Yellow Taxi trip records for January 2023. We ingest raw `.parquet` files, enrich them with zone lookup data, clean the data, and generate useful summary reports using PySpark — all inside GitHub Codespaces.

---

## 📁 Project Structure
├── data/
│   ├── yellow_tripdata_2023-01.parquet
│   └── taxi_zone_lookup.csv
├── output/
│   ├── parquet/yellow_tripdata_enriched/
│   ├── cleaned/yellow_tripdata_cleaned/
│   └── summaries/
│       ├── top_10_pickup_zones/
│       ├── avg_fare_by_borough/
│       └── trips_by_hour/
├── notebooks/
│   ├── nyc_taxi_etl.ipynb

---

## 📌 Objectives

- ✅ Ingest raw Parquet trip data  
- ✅ Enrich with zone lookup (pickup/dropoff locations)  
- ✅ Clean invalid records (e.g., negative fare, bad timestamps)  
- ✅ Perform aggregations for insights  
- ✅ Save all outputs in stage-wise folders  

---

## 📊 Key Visualizations (Generated in Stage 3)

1. **Top 10 Pickup Zones by Trip Volume**  
   Helps identify busiest areas in NYC by volume of rides.

2. **Average Fare by Borough**  
   Useful for analyzing pricing trends across NYC regions.

3. **Hourly Trip Distribution**  
   Shows peak hours for taxi demand throughout the day.

---

## 🧹 Data Cleaning Steps

- Removed trips with:  
  - Fare amount ≤ 0  
  - Passenger count < 1  
  - Invalid pickup/dropoff timestamps  

- Filled missing values in:  
  - `airport_fee`, `congestion_surcharge`  

- Converted all timestamp fields to datetime  
- Output saved as `.parquet` for downstream use  

---

## 🧰 Tools & Technologies

| Tool              | Purpose                             |
|-------------------|-------------------------------------|
| PySpark           | Distributed processing              |
| Pandas            | Minor CSV joins and EDA             |
| GitHub Codespaces | Cloud-based Python dev environment  |
| NYC TLC Data      | Source of real-world taxi data      |

---

## 📂 Dataset

- **Trip Data**:  
  [NYC Yellow Taxi Trip Records – 2023](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)  
  Used January `.parquet` file

- **Zone Lookup**:  
  `taxi_zone_lookup.csv` — maps location ID to borough and zone name

---

## 🚀 Next Steps

- ✅ Build full pipeline in PySpark  
- ⏳ Stage 4: Load cleaned `.parquet` to Snowflake (or simulate it)  
- ⏳ Introduce partitioning and file format comparison (Avro, Iceberg, etc.)  
- ⏳ Add orchestration layer (Airflow or Prefect)  
- ⏳ Add dashboarding (e.g., Streamlit or Power BI)  

---

## 📌 Author

**Sai Prasad L**  
_Data Engineer | Building Data Portfolios for Big Tech_  
[GitHub](https://github.com/yourusername) • [LinkedIn](https://www.linkedin.com/in/yourprofile)