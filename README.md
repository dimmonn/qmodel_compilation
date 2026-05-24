# QModel Compilation

This repository contains the SQL queries, analysis scripts, and results used in the empirical evaluation of QModel (as reported in the paper). It provides end-to-end reproducibility for the RQ1 and RQ2 analyses by materializing the required datasets from a populated QModel database and running the modeling steps.

## Quick Start

1. **Prepare the database:** Ensure a MySQL/MariaDB database contains the mined QModel data (see the main qmodel) repo for mining instructions).  
2. **Run RQ1 (SQL datasets):**  
   ```bash
   mysql -u <user> -p qmodel_demo < queries/RQ1.sql
   ```  
   This creates the issue-level candidate-BIC, issue-level fixing-commit, and PR-level datasets in the database.  
3. **Run RQ2 (modeling):**  
   ```bash
   python3 clients/proven/rq3/RQ2_models.py
   ```  
   This script loads the PR-level dataset from the database, trains exploratory models, and saves feature-importance figures and result tables. Edit the DB connection settings in the script as needed.  
4. **View Results:** Derived tables and figures are saved in the `persistence/files/pr_rq3_review_time_graph_churn_ci_bic_{project_owner}.parquet` file. Compare these with the tables and plots reported in the paper.  


## Architecture: `context/`, `core/`, `persistence/`

### `persistence/`: Data Access + Local Caching

`persistence/DataCacheHandler.py` implements:

- DB connection creation (`SQLAlchemy` + MySQL);
- SQL execution with optional parameter (`owner`);
- cache materialization to CSV/Parquet/JSON/Pickle;
- lazy load behavior: if cache file exists, load; otherwise execute query and save.

This layer decouples expensive SQL extraction from repeated analysis runs.

### `core/`: Strategy and Factory for Analyses

- `core/factories/analysis_factory.py` maps strategy names to concrete implementations:
  - `pearson_spearman`, `pca`, `anova`, `linear_regression`, `random_forest`, `elastic_net`.
- `core/correlation_analysis_factory.py` defines abstract `AnalysisStrategy` plus shared visualization helpers.
- `core/strategies/*.py` contains concrete implementations:
  - correlation (`pearson_spearman.py`),
  - dimensionality reduction (`pca.py`),
  - hypothesis testing (`anova.py`),
  - supervised regression (`linear_regression.py`, `random_forest.py`).

This provides a clean, extensible analysis dispatch mechanism.

### `context/`: Lightweight Execution Contexts

- `context/rf_context.py` is a wrapper around `RandomForestAnalysis` for running and visualizing with a bound dataframe.
- `context/LrContext.py` and `context/PsContext.py` currently exist but are empty placeholders.


## Contents

- `queries/RQ1.sql`: SQL query to build RQ1 analysis datasets.  
- `clients/proven/rq3/RQ2_models.py`: Python script for RQ2 (random-forest modeling on PR data).  
- `results/`: Generated tables and figures for RQ1 and RQ2 (for review only) and qmodel schema.  
- `requirements.txt` (if present): Python dependencies.  
- `README.md`, `LICENSE`: This documentation and license information.  

## Notes

- This repository assumes the database schema defined by the main QModel mining project.).  
- The full QModel database can be large (on the order of hundreds of GB) because it stores raw GitHub data and derived artifacts. For practicality, this repo provides only the SQL and scripts needed to generate the reported results; the actual data dump is not included.  
- After publication, this compilation package will be archived (e.g. on Zenodo) alongside the QModel framework for long-term access.  
