# KPI Reference – Explainer

The `kpi_reference` table standardizes names, definitions, and target thresholds for KPIs used across reports and queries.

## Columns
- **kpi_name (PK)** – unique, human-readable identifier (e.g., `Budget Utilization`).
- **description** – definition of the KPI.
- **target_threshold** – target or acceptable band (e.g., `±5%`, `>= 90%`).

## Examples
- **Budget Variance (Cost Variance)** – difference between approved budget and recorded actual spend to date. Target: `±5%`.
- **Budget Utilization** – portion of budget consumed. Target: `Stay below 95% until final month`.
- **Forecast Accuracy** – proximity of forecast to actuals each period. Target: `±5%`.
- **On-Time Milestone Completion Rate** – % of milestones delivered on/before due date. Target: `>= 90%`.
- **On-Time Project Delivery** – % of projects meeting planned end date. Target: `>= 85%`.
- **CPI, SPI, ROI** – placeholders for future tables (earned value & benefits).

## Why no foreign keys (for now)?
KPI definitions may apply at multiple grains (project, portfolio, month). Keeping this table free-standing makes it easy to reuse in BI as a glossary. You can later add a bridge (e.g., `project_kpi`) or a `kpi_result` fact table when you want to persist measured values.

## BI usage ideas
- Show definitions and targets in **tooltips** or side panels.
- Use `target_threshold` to color-code visuals (e.g., green if within ±5%).

