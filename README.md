# QModel Compilation: Data Quality, Feature Construction, and Modeling Pipeline

This repository implements a data-to-model pipeline for empirical software engineering analyses on GitHub projects (currently focused on `ansible/ansible` and `facebook/react`).

The workflow is organized around three SQL research queries (`RQ1_test.sql`, `RQ1.sql`, `RQ2.sql`) and modeling clients (notably `clients/proven/rq3/RQ3_models.py`), with caching and strategy-based analysis infrastructure.

---

## Study Design Overview

- **Research objective**: quantify data completeness and build analyzable datasets from commit graph, code churn, CI, and socio-technical signals.
- **Primary artifacts**:
  - `queries/RQ1_test.sql`
  - `queries/RQ1.sql`
  - `queries/RQ2.sql`
  - `clients/proven/rq3/RQ3_models.py`
- **Pipeline style**: SQL feature engineering -> parquet caching -> statistical/ML analysis via strategy factory.

---

## RQ1 (`queries/RQ1_test.sql`): Project-Level Data Coverage and Linkage Readiness

`queries/RQ1_test.sql` produces a **project-level audit table** for repository data quality and cross-entity linkage coverage.

### What it computes

For each selected project, the query reports:

- artifact volume (`commits_total`, `issues_total`, `pull_requests_total`, `file_changes_total`, `timelines_total`, `reactions_total`, `ci_check_runs_total`);
- linkage completeness (e.g., closed issues linked to PRs, PRs linked to commits);
- timestamp completeness for commits, issues, PRs, timelines;
- file-change completeness (`patch` availability, changed-line coverage);
- defect provenance linkage statistics (issues with fixing commits, issues with candidate bug-introducing commits, number of issue-BIC links).

### Why this matters

This query addresses **dataset validity and observability** before modeling.  
It answers whether the repository has enough complete and linked records to support robust downstream analysis.

---

## RQ2 (`queries/RQ1.sql`): Computability of Aggregated Issue/PR Analysis Rows

`queries/RQ1.sql` evaluates whether issue-level and PR-level rows can be consistently computed from available graph/churn evidence.

### Constructed row families

The query builds three row sets, then unifies them:

- `Issue-level fixing-commit dataset`
- `Issue-level candidate-BIC dataset`
- `PR-level candidate-BIC dataset`

### Key outputs

For each project and dataset type:

- total analysis rows;
- target computability (`target_duration_computability_percent`);
- graph summary computability (`graph_summary_computability_percent`);
- churn summary computability (`churn_summary_computability_percent`);
- joint graph+churn readiness;
- average numbers of commits and ready commits per analysis row;
- aggregate graph/churn summary means (depth range, branch distance, total changes, etc.).

### Why this matters

This is a **feasibility and quality gate** for later inferential or predictive studies.  
It quantifies how often a complete feature/target tuple exists at the intended unit of analysis.

---

## RQ3 (`queries/RQ2.sql`): PR-Level Modeling Dataset for Review-Time Prediction

`queries/RQ2.sql` creates a **feature-rich PR-level regression table** where each row corresponds to one pull request.

### Target variable

- `pr_review_seconds` (and transformed target `log_pr_review_seconds`)

### Feature groups

- process/social features: labels, assignees, reviewers, timeline events, reactions;
- evidence-count features: number of commits and readiness fractions;
- candidate defect-provenance features: BIC presence and related link counts;
- graph-history features: depth, branch distance/rates, degree structure;
- churn features: additions/deletions/changes/files and density;
- CI features: passed/failed/cancelled/other counts and percentages, CI duration.

### Train/validation split

The SQL defines `dataset_split` deterministically (`train`/`validation`) using a hash-style split on project+PR identity.  
This supports reproducible model evaluation.

---

## RQ3 Modeling Client (`clients/proven/rq3/RQ3_models.py`)

`IssueDefectRQ3Models` is the executable modeling wrapper for the RQ3 dataset.

### Responsibilities

- loads data via `DataCacheHandler` from `queries/RQ2.sql` into cached parquet;
- filters by `project_owner`;
- applies target transformation (`np.log1p` on `pr_review_seconds`);
- defines selected predictor subset (`self.features`);
- executes:
  - linear regression via `AnalysisFactory.get_analysis("linear_regression")`;
  - random forest regression via `AnalysisFactory.get_analysis("random_forest")`;
- visualizes coefficients/importances/fit/residuals/metrics.

### Learning paradigm clarification

Both models in this file are **supervised learning** methods:

- linear regression: supervised regression;
- random forest regressor: supervised regression.

They are not unsupervised methods because they explicitly learn from a target label (`log_pr_review_seconds`).

---

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


## Reproducibility Notes

- Data source assumptions are encoded in `DataCacheHandler` (`qmodel_demo`, MySQL connection config).
- RQ3 modeling depends on successful generation/loading of:
  - `persistence/files/pr_rq3_review_time_graph_churn_ci_bic_<owner>.parquet`
- Analyses are run per owner (`ansible`, `facebook`) in `clients/proven/rq3/RQ3_models.py`.
