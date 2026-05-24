# QModel Compilation

This repository contains the SQL queries, scripts, and results for the *QModel* analysis reported in the paper. It constructs PR- and issue-level datasets by joining project metadata, graph metrics, churn, CI outcomes, and defect-provenance evidence.

## Purpose
- Materialize empirical datasets for RQ1 and RQ2 analyses from a populated *QModel* database.
- Ensure end-to-end reproducibility of the SQL transformations and modeling steps.

## Quick Start

1. **Prerequisites:** A running MySQL/MariaDB database containing the mined *QModel* data (schema as per the mining repo). Python 3 with dependencies (e.g. `pandas`, `scikit-learn`) for modeling.
2. **Run RQ1 (SQL dataset):**  
   ```bash
   mysql -u <user> -p -D qmodel_demo < queries/RQ1.sql
   ```  
   This executes the RQ1 dataset query (in `queries/RQ1.sql`). The query generates the analysis tables. By default, it includes a filter to keep only rows with CI action evidence (`ci_total_checks > 0`). You can remove this clause to include all rows.
3. **Run RQ2 (modeling):**  
   ```bash
   python3 clients/proven/rq3/RQ2_models.py
   ```  
   This Python script loads the PR-level dataset (from the database), trains exploratory models, and writes results (feature importance, prediction plots) to `results/`. Adjust DB connection settings inside the script if needed.
4. **Results:** Derived tables and figures are saved in the `results/` directory. Compare these with the paper’s reported tables.

## File Overview

| Path                                      | Purpose                                      |
|-------------------------------------------|----------------------------------------------|
| `queries/RQ1.sql`                         | SQL for RQ1 dataset (issue-level BIC, fixing-commit, PR-level BIC) |
| `clients/proven/rq3/RQ2_models.py`        | Python script for RQ2 modeling (PR review-time) |
| `results/`                                | Generated result tables and figures          |
| `requirements.txt` (if present)          | Python dependencies for modeling             |
| `LICENSE`                                 | License (MIT/CC BY placeholder)              |

## Reproduction Checklist

- [ ] Ensure the *QModel* database is populated and accessible.  
- [ ] Run the RQ1 SQL query (see Quick Start) against the database.  
- [ ] Verify SQL completes without errors; inspect output tables (in DB or `results/`).  
- [ ] Run the RQ2 Python script. Check that models and plots are produced in `results/`.  
- [ ] Confirm outputs match the published tables/figures.