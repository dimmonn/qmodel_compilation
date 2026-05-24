# QModel Compilation

This repository contains the SQL queries, analysis scripts, and derived results
used to evaluate **QModel**, a time-aware GitHub mining framework for empirical
software quality studies.

QModel Compilation is the analysis layer of the project. It takes data already
mined into the QModel relational database and materializes SQL-defined datasets
for empirical analysis. The repository supports the results reported in the
paper:

> QModel: Early Results on a Time-Aware GitHub Mining Framework for Empirical Software Quality Studies

## Repository structure

```text
qmodel_compilation/
├── queries/
│   └── RQ1.sql
├── clients/
│   └── proven/
│       └── rq3/
│           └── RQ2_models.py
├── results/
└── README.md