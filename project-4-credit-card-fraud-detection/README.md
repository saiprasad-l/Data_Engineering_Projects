# 💳 Project 4: Credit Card Fraud Detection Lakehouse (2025)

This project simulates a **production-grade data & ML pipeline** in Databricks Community Edition (CE).  
We build a **Lakehouse** with Bronze → Silver → Gold Delta tables, perform feature engineering, train a fraud detection model with scikit-learn, log experiments to MLflow, and orchestrate everything with Databricks Jobs.

---

## 🧰 Tools & Technologies

| Tool              | Purpose                                         |
|-------------------|-------------------------------------------------|
| PySpark           | Data ingestion, transformation (Bronze → Gold)  |
| Delta Lake        | Storage format for Bronze layer                 |
| Pandas            | Feature prep & ML dataset handoff               |
| scikit-learn      | Fraud detection model (LogReg / Random Forest)  |
| MLflow            | Experiment tracking & model registry            |
| Databricks Jobs   | Orchestration & scheduling                      |
| Spark UI          | Observability for ETL                           |

---

## 📌 Objectives

- ✅ Ingest raw credit card transactions CSV into **Bronze Delta**  
- ✅ Clean, cast types, and enrich features in **Silver**  
- ✅ Create **Gold ML-ready table** with engineered features:  
  - PCA anonymized features (`V1–V28`)  
  - `log_amount`, `amount_zscore`, `time_zscore`  
- ✅ Handle extreme class imbalance (fraud ≈ 0.17%) using class weighting (or SMOTE)  
- ✅ Train fraud detection model (Logistic Regression & Random Forest)  
- ✅ Track model metrics (ROC-AUC, PR-AUC) in **MLflow**  
- ✅ Write predictions back to **Gold predictions** (Delta)  
- ✅ Orchestrate end-to-end pipeline with Databricks Jobs  

---

## 📁 Project Structure
```
├── data/
│   └── creditcard.csv
├── notebooks/
│   ├── 01_bronze_ingest.ipynb        # Raw ingestion → Bronze Delta (path)
│   ├── 02_silver_clean.ipynb         # Cleaning, casting, enrichment -> saveAsTable
│   ├── 03_gold_features.ipynb        # Feature engineering, PCA -> saveAsTable or delta path
│   └── 04_ml_fraud_detection.ipynb   # ML training + MLflow logging -> write predictions
├── jobs/
│   └── fraud_detection_pipeline.json # (optional) Job definition / export
└── README.md
```


---

## 📂 Dataset

- **Credit Card Transactions (Kaggle)**  
  [Credit Card Fraud Detection Dataset (mlg-ulb / creditcard.csv)](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)  
  Contains ~284,807 transactions with anonymized PCA features (`V1–V28`), `Time`, `Amount`, and fraud label (`Class`).

---

## 🧹 Data Cleaning & Feature Engineering

### Silver
- Cast `Class` to integer  
- Remove duplicates and invalid rows  
- Standardize `Amount` and `Time` (z-score), add `log_amount`

### Gold
- Add engineered features:
  - `log_amount = log1p(Amount)`
  - `amount_zscore = zscore(Amount)`
  - `time_zscore = zscore(Time)`
- Optional: reduce PCA V1–V28 to `PCA_1..PCA_10` via `sklearn.decomposition.PCA` for compact features

**Final Gold schema (example):**  
`V1..V28`, `PCA_1..PCA_10` (optional), `log_amount`, `amount_zscore`, `time_zscore`, `Class`

---

## 🤖 Machine Learning & MLflow

- Convert Gold to Pandas (small dataset / demo) or use in-Spark approaches for production
- Handle imbalance:
  - Option A: `class_weight="balanced"` in sklearn models (no additional deps)
  - Option B: use `imblearn.SMOTE` to upsample minority class (requires `imbalanced-learn`)
- Baseline models:
  - Logistic Regression (fast, interpretable)
  - Random Forest (better non-linear performance)
- Evaluation metrics:
  - ROC-AUC (primary), Precision-Recall AUC, Precision, Recall, F1
- MLflow logs per run:
  - params, metrics, model artifact, optional model `input_example`/signature

**Predictions output table (`Delta` or table):**
| Column       | Description                     |
|--------------|---------------------------------|
| `label`      | Ground truth (fraud = 1 / normal = 0) |
| `prediction` | Model predicted class (0/1)     |
| `probability`| Model's fraud probability (0–1) |

---

## 🔍 Observability & Orchestration

- **Databricks Jobs**: chain notebooks as tasks — `01_bronze` → `02_silver` → `03_gold` → `04_ml`  
- **Spark UI**: inspect ETL stages, shuffle, executor metrics  
- **MLflow UI**: inspect experiments and compare runs  
- **Great Expectations (optional)**: generate Data Docs for Silver/Gold validations

---

## ▶️ Run / Quickstart (Databricks CE)

1. Upload `creditcard.csv` to DBFS (Data → Add Data) or place in `dbfs:/Volumes/...`  
2. Create a Job cluster or use an interactive cluster. Ensure required Python libs installed:  
   - Basic: `scikit-learn`, `pandas`, `mlflow`  
   - Optional: `%pip install imbalanced-learn` for SMOTE  
3. Run notebooks in order (or create a Job DAG):
   - `01_bronze_ingest` (writes Bronze Delta path)  
   - `02_silver_clean` (reads Bronze path → writes Silver table or path)  
   - `03_gold_features` (reads Silver → writes Gold table or path)  
   - `04_ml_fraud_detection` (reads Gold → trains model → writes predictions → logs MLflow)
4. Open MLflow UI (Workspace → Experiments) to view runs and artifacts.  
5. Inspect `gold_predictions` Delta/table for results and monitoring.

---

## 🖼 Architecture Diagram

```mermaid
flowchart LR
  A["Raw CSV (creditcard.csv)"] -->|ingest| B["Bronze (Delta path)"]
  B -->|clean & transform| C["Silver (table)"]
  C -->|feature engineering| D["Gold (table) - ML-ready"]
  D -->|train + evaluate -> log| E["MLflow (model & metrics)"]
  E -->|batch predictions| F["Gold Predictions (Delta/table)"]

  style A fill:#f9f,stroke:#333,stroke-width:1px
  style B fill:#fffae6,stroke:#333
  style C fill:#fff0f0,stroke:#333
  style D fill:#e6fff2,stroke:#333
  style E fill:#e6f0ff,stroke:#333
  style F fill:#fff,stroke:#333

---
## 🚀 Next Steps & Enhancements
- Add Great Expectations checks in Silver and Gold, export Data Docs to the repo.
- Register promoted models in MLflow Model Registry (Stage → Prod).
- Build a monitoring dashboard on top of gold_predictions (Databricks SQL / Power BI).
- Add CI/CD to test notebooks and deploy Job definitions (GitHub Actions).

---

## 📌 Author

**Sai Prasad L**  
_Data Engineer | Building Data Portfolios for Big Tech_ 