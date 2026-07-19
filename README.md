# QModel Compilation

This repository contains the SQL queries, analysis scripts, dataset snapshots and selected results used in the empirical evaluation of [QModel](https://github.com/dimmonn/qmodel).

The artifact supports three research questions:

| Research question | Purpose | Main files |
|---|---|---|
| RQ1 | Artifact coverage and cross-artifact linkability | `queries/RQ1.sql` |
| RQ2 | Derived-metric computability | `queries/RQ2.sql` |
| RQ3 | Pull-request review-time worked example | `queries/RQ3.sql`, `clients/proven/rq3/RQ3_models.py` |

The complete QModel MySQL database is not distributed because of its size. Reproduction from SQL requires a compatible populated database. The `results/` directory contains selected archived outputs for comparison with a reproduced execution.

## Requirements

- Python 3
- MySQL 8 or a compatible MariaDB installation
- A populated QModel database
- Python dependencies from `requirements.txt`
- A Parquet engine such as `pyarrow`

Create the Python environment from the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
python3 -m pip install pyarrow
```

For a fully pinned environment, `pyarrow` should also be added to `requirements.txt`.

## Database configuration

The examples below assume:

```bash
export QMODEL_DB_HOST='localhost'
export QMODEL_DB_PORT='3307'
export QMODEL_DB_NAME='qmodel_demo'
export QMODEL_DB_USER='root'
```

The MySQL client prompts for the database password.

The RQ3 Python analysis uses the connection settings defined in:

```text
persistence/DataCacheHandler.py
```

Before running RQ3 against a database, update the following fields in that file:

```python
self.db_config = {
    "username": "root",
    "password": "admin",
    "host": "localhost",
    "port": "3307",
    "dbname": "qmodel_demo"
}
```

Do not commit real passwords or other credentials.

## Reproducing RQ1

RQ1 reports artifact coverage and cross-artifact linkability for the evaluated projects.

From the repository root:

```bash
mkdir -p reproduced-results

mysql \
  --host="$QMODEL_DB_HOST" \
  --port="$QMODEL_DB_PORT" \
  --user="$QMODEL_DB_USER" \
  --password \
  --batch \
  --raw \
  "$QMODEL_DB_NAME" \
  < queries/RQ1.sql \
  > reproduced-results/RQ1.tsv
```

The output includes artifact counts, timestamp completeness, pull-request–commit coverage, issue–pull-request link coverage, CI coverage, file-change coverage and defect-linking statistics.

## Reproducing RQ2

RQ2 evaluates whether graph, churn, process, CI and defect-provenance variables can be computed from the persisted artifacts.

```bash
mysql \
  --host="$QMODEL_DB_HOST" \
  --port="$QMODEL_DB_PORT" \
  --user="$QMODEL_DB_USER" \
  --password \
  --batch \
  --raw \
  "$QMODEL_DB_NAME" \
  < queries/RQ2.sql \
  > reproduced-results/RQ2.tsv
```

The output reports computability for issue-level fixing-commit data, issue-level candidate bug-introducing commit data and pull-request-level candidate-defect data.

## Reproducing RQ3

RQ3 is a worked pull-request review-time analysis for:

- `ansible/ansible`
- `facebook/react`

The Python script executes `queries/RQ3.sql`, constructs the pull-request-level dataset and runs the descriptive ordinary least-squares and random-forest analyses.

Run it from its expected working directory:

```bash
(
  cd clients/proven/rq3
  PYTHONPATH=../../.. python3 RQ3_models.py
)
```

The script:

- executes `queries/RQ3.sql` when a cached dataset is unavailable;
- creates one pull-request-level dataset for each project;
- stores dataset caches under `persistence/files/`;
- fits the descriptive linear-regression models;
- evaluates the random forests using the dataset’s deterministic train/validation split;
- prints model results and displays the diagnostic figures.

The cache filenames are:

```text
persistence/files/pr_rq3_review_time_graph_churn_ci_bic_ansible.parquet
persistence/files/pr_rq3_review_time_graph_churn_ci_bic_facebook.parquet
```

If a cache exists, `DataCacheHandler` loads it instead of executing `queries/RQ3.sql`. To force extraction from the configured database, move the existing cache files outside `persistence/files/` before running the script.

## Issue–pull-request validation

The row-level report used in the paper is distributed at:

```text
results/issue-pr-validation-results.csv
```

It contains 200 sampled issue–pull-request relations:

- confirmed: 197
- contradicted: 3
- unverifiable: 0
- confirmation proportion: 0.9850
- 95% Wilson interval: [0.9568, 0.9949]

The validation implementation is maintained in the main QModel repository:

```text
src/test/java/com/research/qmodel/validation/IssuePrDatasetValidationTest.java
src/test/resources/validation.sql
```

To reproduce the external GitHub validation from the QModel project root:

```bash
export QMODEL_DB_URL='jdbc:mysql://localhost:3306/qmodel_demo'
export QMODEL_DB_USER='<database-user>'
export QMODEL_DB_PASSWORD='<database-password>'
export GITHUB_TOKEN='<github-token>'

mvn test \
  -Dtest=IssuePrDatasetValidationTest \
  -Dvalidation.sql=src/test/resources/validation.sql \
  -Dvalidation.expectedRows=200 \
  -Dvalidation.minPrecision=0.95 \
  -Dvalidation.maxUnverifiableFraction=0.10
```

The test writes the generated report to:

```text
build/reports/qmodel/issue-pr-validation-results.csv
```

A GitHub token is required for the external semantic-validation step. Without it, only the SQL-result invariants are checked.

## Database resource report

The main QModel repository includes:

```text
db_report.sql
```

Run it against the populated database to report table row counts and storage consumption:

```bash
mysql \
  --host="$QMODEL_DB_HOST" \
  --port="$QMODEL_DB_PORT" \
  --user="$QMODEL_DB_USER" \
  --password \
  "$QMODEL_DB_NAME" \
  < ../qmodel/db_report.sql \
  > reproduced-results/database-report.txt
```

Storage requirements depend on the selected repositories, history depth and collected artifact types.

## Repository structure

```text
queries/
  RQ1.sql
  RQ2.sql
  RQ3.sql

clients/proven/rq3/
  RQ3_models.py

core/
  factories/
  strategies/

persistence/
  DataCacheHandler.py
  files/

results/
  issue-pr-validation-results.csv
  selected dataset snapshots and model outputs

requirements.txt
README.md
LICENSE
```

### `persistence/`

`persistence/DataCacheHandler.py` provides:

- SQLAlchemy database connections;
- SQL execution with the project-owner parameter;
- CSV, Parquet, JSON and Pickle cache materialization;
- reuse of existing cache files.

### `core/`

`core/factories/analysis_factory.py` maps analysis names to their implementations.

Available strategies include:

- Pearson and Spearman correlation;
- principal component analysis;
- analysis of variance;
- linear regression;
- random forest;
- elastic net.

The implementations are stored under `core/strategies/`.

### `context/`

The `context/` directory contains lightweight wrappers for executing selected analysis strategies with a bound dataset.

## Reproducibility scope

The archived outputs describe the database snapshot evaluated in the paper. Re-mining the repositories from the live GitHub API can produce different results because repositories, branches and GitHub metadata can change over time.

For exact comparison with the paper:

1. use the repository revisions identified in the manuscript;
2. use a compatible snapshot of the QModel database;
3. retain the SQL queries and configuration used for the execution;
4. record the execution timestamp and software environment;
5. compare regenerated outputs with the selected artifacts in `results/`.

## Security

Never commit:

- GitHub tokens;
- database passwords;
- private repository data;
- local secret-property files;
- generated environment files containing credentials.