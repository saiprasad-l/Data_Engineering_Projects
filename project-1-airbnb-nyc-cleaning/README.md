# Project 1: Airbnb NYC Data Cleaning & EDA

## Dataset
[Airbnb NYC 2019 on Kaggle](https://www.kaggle.com/datasets/dgomonov/new-york-city-airbnb-open-data)

## Tools Used
- GitHub Codespaces
- Python (Pandas)
- Jupyter Notebook

## Objectives
- Load and explore raw Airbnb NYC data
- Clean missing values
- Drop unnecessary columns
- Export cleaned version for future use

## Transformations Applied
- Dropped unnecessary columns: `id`, `host_name`
- Filled missing values in `reviews_per_month` with 0
- Saved cleaned dataset as `airbnb_cleaned.csv`

## Files
- `airbnb_clean.ipynb`: Notebook with code
- `AB_NYC_2019.csv`: Raw data
- `airbnb_cleaned.csv`: Cleaned output


## 📊 Data Visualizations
Here are some visual insights from the cleaned Airbnb NYC dataset:
- Average prices by borough
- Most popular neighborhoods
- Distribution of listing prices
- Room types across NYC




# 🏙️ Project 1: Airbnb NYC Data Cleaning & EDA

This project focuses on exploring and cleaning the [Airbnb NYC 2019 dataset](https://www.kaggle.com/datasets/dgomonov/new-york-city-airbnb-open-data). The goal is to prepare the dataset for downstream analytics and reporting by applying basic data cleaning and visualization techniques.

---

## 📁 Project Structure
---

## 📌 Objectives

- ✅ Load and inspect the raw Airbnb NYC dataset
- ✅ Handle missing values and drop irrelevant columns
- ✅ Generate basic insights and summary statistics
- ✅ Visualize trends using `matplotlib` and `pandas`

---

## 📊 Key Visualizations

1. **Average Price by Borough**  
   Compare the average price per listing across different NYC boroughs.

2. **Top 10 Neighborhoods by Number of Listings**  
   See which neighborhoods are the most popular in terms of listings.

3. **Price Distribution (under $500)**  
   Understand the pricing trend by removing outliers.

4. **Room Type Distribution**  
   Visual representation of shared vs private vs entire home listings.

---

## 🧹 Data Cleaning Steps

- Removed columns: `id`, `host_name`
- Filled null values in `reviews_per_month` with `0`
- Exported cleaned CSV for reuse

---

## 🧰 Tools & Technologies

| Tool        | Purpose                        |
|-------------|--------------------------------|
| Python      | Core programming language      |
| Pandas      | Data manipulation and analysis |
| Matplotlib  | Visualizations                 |
| Jupyter     | Interactive notebook           |
| GitHub Codespaces | Cloud-based dev environment |

---

## 📂 Dataset

- Source: [Kaggle – Airbnb NYC 2019](https://www.kaggle.com/datasets/dgomonov/new-york-city-airbnb-open-data)
- Records: ~49,000
- Features: Listings, hosts, prices, reviews, geolocation, etc.

---

## 🚀 Next Steps

- Build a PySpark version of the same pipeline
- Extend this into a data pipeline: raw data → clean → store as Parquet → load to Snowflake
- Add a Streamlit dashboard or Tableau view

---

## 📌 Author

**Sai Prasad L**  
_Data Engineer | Building Data Portfolios for Big Tech_  
[GitHub](https://github.com/yourusername) • [LinkedIn](https://www.linkedin.com/in/yourprofile)

---