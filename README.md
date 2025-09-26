# Finance Reporting (SQL + SSMS)

This end‑to‑end SQL portfolio project demonstrates **schema design**, **idempotent seeding**, **validation and data‑quality checks** and **business insights** for a portfolio‑finance use case. The goal is to create a reliable database foundation that can feed reporting tools like Power BI.

> **Tech:** Microsoft SQL Server Management Studio (SSMS).
> **Scope:** Projects, managers, budgets, spend logs, milestones, forecasts, purchase orders and completion status.

## 💂 Repository Structure

```
Finance-Reporting-SQL/
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_table.sql
│   ├── 03_insert_data.sql
│   ├── 04_validation_checks.sql
│   ├── 05_data_quality_checks.sql
│   └── 06_business_queries.sql
├── erd/
│   └── finance_reporting.png   # ERD exported from Lucidchart
├── docs/
│   └── kpi_reference_explainer.md
├── LICENSE
└── README.md  # Project overview (this file)
```

## 🚀 Quickstart

1. Open **SSMS** and connect to your SQL Server instance.
2. Run the scripts in the following order (they are **idempotent** — safe to re‑run):
   1. `sql/01_create_database.sql` – creates the `FinanceReporting` database.
   2. `sql/02_create_table.sql` – creates all tables & constraints.
   3. `sql/03_insert_data.sql` – seeds a realistic demo dataset (~50 projects, managers, spend, milestones, forecasts, POs, completion and KPI glossary).
   4. `sql/04_validation_checks.sql` – referential & logic checks.
   5. `sql/05_data_quality_checks.sql` – duplicate, null and outlier checks (designed to return **no rows** if clean).
   6. `sql/06_business_queries.sql` – business analysis queries and **KPI views** ready for BI tools.

## 🔧 Data Model (ERD)

![ERD](erd/finance_reporting.png)

**Entities:** `manager`, `project`, `spend_log`, `milestone`, `forecast`, `purchase_order`, `project_completion` and `kpi_reference`.  The `kpi_reference` table is intentionally standalone as a glossary of KPI definitions and targets.

## 📈 Sample KPI Queries


After running `06_business_queries.sql`, the database exposes several reusable views.  Here’s an example of how to inspect projects staying within their approved budgets:

```sql
SELECT project_id,
       project_name,
       budget,
       spend_to_date,
       CASE WHEN spend_to_date <= budget THEN 'On budget' ELSE 'Over budget' END AS budget_status
FROM v_BudgetUtilization;
```

These views feed directly into Power BI dashboards for real‑time portfolio monitoring.

## ✅ Data Quality & Trust

- `04_validation_checks.sql` verifies referential integrity, date ranges and other invariants.
- `05_data_quality_checks.sql` inspects duplicates, nulls and improbable values; it is designed to return **no rows** if the data is clean.

## 🔎 What This Demonstrates

- **Schema design** with clear accountability and analysis tables.
- **Idempotent DDL/DML** with readable prints and safeguards.
- **Validation & quality** checks for trustworthy analytics.
- **Business queries & KPI views** that plug directly into BI tools.
- **Polished ERD and documentation** for non‑technical audiences.

## 🚃 Roadmap

Future improvements may include:

- Adding `kpi_result` or `project_kpi` tables to store KPI values over time.
- Introducing earned value and benefit‑realisation tables (CPI/SPI/ROI).
- Implementing indexes and performance tuning as the dataset scales.

## 👤 Author & Acknowledgments

**Arun Acharya**  – *Data Analyst (Ottawa, Canada)*

This project is open‑sourced under the **MIT License**.  Some parts of the SQL scripts were generated with the assistance of OpenAI Codex, but all scripts were reviewed, refined and finalised by Arun Acharya.

---

*If you build upon this project or have suggestions, feel free to open an issue or connect with me on [LinkedIn](https://www.linkedin.com/in/arun-acharya-26077a362).* 
