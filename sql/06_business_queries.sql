USE FinanceReporting;
GO

-- =================================================================================================
-- Script: 06_business_queries.sql
-- Title : Guided business insights for the Finance Reporting dataset
-- Author: Arun Acharya
-- Purpose: Provide five ready-to-run analytical queries that answer the most frequently asked
--          project finance questions. Each section explains what the query reveals so finance and
--          delivery stakeholders can quickly interpret the results.
-- How to use: Run the whole file or execute individual questions as needed. The statements only read
--             data; they do not modify any tables.
-- =================================================================================================

SET NOCOUNT ON;
PRINT 'Starting 06_business_queries.sql: exploring five core project finance questions...';

/* ================================================================================================
   Question 1: Budget vs. actual spend by project
   -----------------------------------------------------------------------------------------------
   Goal: Compare each project''s approved budget with the actual spend recorded in spend_log.
   Output highlights the dollar variance and the variance percentage so portfolio leaders can see
   which projects are trending under or over budget.
   ================================================================================================ */
-- Question 1 - Budget vs. Actual Spend by Project
WITH spend_by_project AS (
    SELECT
        sl.project_id,
        SUM(sl.amount) AS actual_spend
    FROM spend_log AS sl
    GROUP BY
        sl.project_id
)
SELECT
    p.project_id,
    p.name AS project_name,
    p.budget AS budget_amount,
    COALESCE(sb.actual_spend, 0.00) AS actual_spend_amount,
    p.budget - COALESCE(sb.actual_spend, 0.00) AS variance_amount,
    CASE
        WHEN p.budget = 0 THEN NULL
        ELSE (p.budget - COALESCE(sb.actual_spend, 0.00)) / p.budget
    END AS variance_percent
FROM projects AS p
LEFT JOIN spend_by_project AS sb
    ON sb.project_id = p.project_id
ORDER BY
    p.project_id;

/* ================================================================================================
   Question 2: Purchase orders vs. actual expenditure
   -----------------------------------------------------------------------------------------------
   Goal: Compare committed spend (purchase orders) with actual ledger spend. Finance teams can
   confirm whether invoices are catching up with commitments or if outstanding POs still need to be
   received and accrued.
   ================================================================================================ */
-- Question 2 - Purchase Orders vs. Actual Expenditure
WITH purchase_order_totals AS (
    SELECT
        po.project_id,
        SUM(po.po_amount) AS total_purchase_orders,
        MIN(po.po_date) AS first_po_date,
        MAX(po.po_date) AS latest_po_date
    FROM purchase_orders AS po
    GROUP BY
        po.project_id
), actual_spend_totals AS (
    SELECT
        sl.project_id,
        SUM(sl.amount) AS total_actual_spend,
        MIN(sl.[date]) AS first_spend_date,
        MAX(sl.[date]) AS latest_spend_date
    FROM spend_log AS sl
    GROUP BY
        sl.project_id
)
SELECT
    p.project_id,
    p.name AS project_name,
    COALESCE(pot.total_purchase_orders, 0.00) AS total_purchase_orders,
    COALESCE(ast.total_actual_spend, 0.00) AS total_actual_spend,
    COALESCE(pot.total_purchase_orders, 0.00) - COALESCE(ast.total_actual_spend, 0.00) AS open_commitments,
    CASE
        WHEN COALESCE(pot.total_purchase_orders, 0.00) = 0 THEN NULL
        ELSE (COALESCE(ast.total_actual_spend, 0.00) / pot.total_purchase_orders)
    END AS invoice_conversion_ratio,
    pot.first_po_date,
    pot.latest_po_date,
    ast.first_spend_date,
    ast.latest_spend_date
FROM projects AS p
LEFT JOIN purchase_order_totals AS pot
    ON pot.project_id = p.project_id
LEFT JOIN actual_spend_totals AS ast
    ON ast.project_id = p.project_id
ORDER BY
    p.project_id;

/* ================================================================================================
   Question 3: Forecast vs. actual variance analysis
   -----------------------------------------------------------------------------------------------
   Goal: Compare forecasted spend to actual outcomes for each forecast period. Variance values
   highlight where delivery teams are overshooting or undershooting expectations.
   ================================================================================================ */
-- Question 3 - Forecast vs. Actual Variance Analysis
WITH forecast_periods AS (
    SELECT
        f.project_id,
        f.forecast_date,
        SUM(f.forecast_amount) AS forecast_amount,
        SUM(f.actual_amount) AS actual_amount
    FROM forecast AS f
    GROUP BY
        f.project_id,
        f.forecast_date
)
SELECT
    fp.project_id,
    p.name AS project_name,
    fp.forecast_date,
    fp.forecast_amount,
    fp.actual_amount,
    fp.actual_amount - fp.forecast_amount AS variance_amount,
    CASE
        WHEN fp.forecast_amount = 0 THEN NULL
        ELSE (fp.actual_amount - fp.forecast_amount) / fp.forecast_amount
    END AS variance_percent
FROM forecast_periods AS fp
INNER JOIN projects AS p
    ON p.project_id = fp.project_id
ORDER BY
    fp.project_id,
    fp.forecast_date;

/* ================================================================================================
   Question 4: Spend trend and burn rate analysis
   -----------------------------------------------------------------------------------------------
   Goal: Track monthly spend progression for each project and calculate the burn rate (average daily
   spend) up to the end of each month. This helps finance teams anticipate when budgets may be
   exhausted if the current pace continues.
   ================================================================================================ */
-- Question 4 - Spend Trend and Burn Rate Analysis
WITH monthly_spend AS (
    SELECT
        sl.project_id,
        DATEFROMPARTS(YEAR(sl.[date]), MONTH(sl.[date]), 1) AS month_start,
        EOMONTH(sl.[date]) AS month_end,
        SUM(sl.amount) AS month_spend
    FROM spend_log AS sl
    GROUP BY
        sl.project_id,
        DATEFROMPARTS(YEAR(sl.[date]), MONTH(sl.[date]), 1),
        EOMONTH(sl.[date])
)
SELECT
    ms.project_id,
    p.name AS project_name,
    ms.month_start,
    ms.month_end,
    ms.month_spend,
    SUM(ms.month_spend) OVER (
        PARTITION BY ms.project_id
        ORDER BY ms.month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_spend,
    CASE
        WHEN DATEDIFF(DAY, p.start_date, ms.month_end) + 1 <= 0 THEN NULL
        ELSE SUM(ms.month_spend) OVER (
                 PARTITION BY ms.project_id
                 ORDER BY ms.month_start
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
             ) / NULLIF(CAST(DATEDIFF(DAY, p.start_date, ms.month_end) + 1 AS DECIMAL(10,2)), 0)
    END AS burn_rate_per_day
FROM monthly_spend AS ms
INNER JOIN projects AS p
    ON p.project_id = ms.project_id
ORDER BY
    ms.project_id,
    ms.month_start;

/* ================================================================================================
   Question 5: Milestone timeliness and schedule health
   -----------------------------------------------------------------------------------------------
   Goal: Assess milestone delivery health by flagging delayed tasks and summarising on-time
   completion rates per project. "On-time" treats Completed milestones as successful and counts
   Delayed milestones as behind schedule. In-flight milestones marked "On Track" are shown for
   awareness but excluded from the on-time percentage until they close.
   ================================================================================================ */
-- Question 5 - Milestone Timeliness and Schedule Health
WITH milestone_flags AS (
    SELECT
        m.project_id,
        m.milestone_id,
        m.milestone_name,
        m.due_date,
        m.status,
        CASE WHEN m.status = 'Delayed' THEN 1 ELSE 0 END AS is_delayed,
        CASE WHEN m.status = 'Completed' THEN 1 ELSE 0 END AS is_completed
    FROM milestones AS m
), project_summary AS (
    SELECT
        mf.project_id,
        SUM(mf.is_completed) AS completed_count,
        SUM(mf.is_delayed) AS delayed_count,
        SUM(CASE WHEN mf.status = 'On Track' THEN 1 ELSE 0 END) AS inflight_count
    FROM milestone_flags AS mf
    GROUP BY
        mf.project_id
)
SELECT
    mf.project_id,
    p.name AS project_name,
    mf.milestone_id,
    mf.milestone_name,
    mf.due_date,
    mf.status,
    CASE WHEN mf.is_delayed = 1 THEN 'Delayed' ELSE 'On-Time/Upcoming' END AS schedule_flag,
    ps.completed_count,
    ps.delayed_count,
    ps.inflight_count,
    CASE
        WHEN ps.completed_count + ps.delayed_count = 0 THEN NULL
        ELSE CAST(ps.completed_count AS DECIMAL(10,2)) / (ps.completed_count + ps.delayed_count)
    END AS on_time_completion_percent
FROM milestone_flags AS mf
INNER JOIN project_summary AS ps
    ON ps.project_id = mf.project_id
INNER JOIN projects AS p
    ON p.project_id = mf.project_id
ORDER BY
    mf.project_id,
    mf.due_date,
    mf.milestone_id;

/* ================================================================================================
   KPI Views: Reusable metrics for dashboards and Power BI models
   -----------------------------------------------------------------------------------------------
   The following views calculate key finance and delivery KPIs requested by leadership. Wrapping the
   logic inside views ensures Power BI (or any reporting tool) can consume the metrics without
   rewriting business rules in multiple places.
   ================================================================================================ */

-- Drop and recreate the budget utilization view so reruns stay idempotent
IF OBJECT_ID(N'dbo.v_BudgetUtilization', N'V') IS NOT NULL
    DROP VIEW dbo.v_BudgetUtilization;
GO
CREATE VIEW dbo.v_BudgetUtilization
AS
WITH spend_by_project AS (
    SELECT
        sl.project_id,
        SUM(sl.amount) AS actual_spend
    FROM dbo.spend_log AS sl
    GROUP BY
        sl.project_id
)
SELECT
    p.project_id,
    p.name AS project_name,
    p.budget AS budget_amount,
    COALESCE(sb.actual_spend, 0.00) AS actual_spend_amount,
    CASE
        WHEN p.budget = 0 THEN NULL
        ELSE COALESCE(sb.actual_spend, 0.00) / p.budget
    END AS budget_utilization_percent,
    COALESCE(sb.actual_spend, 0.00) - p.budget AS cost_variance_amount
FROM dbo.projects AS p
LEFT JOIN spend_by_project AS sb
    ON sb.project_id = p.project_id;
GO

-- Drop and recreate the projects-on-budget view (portfolio level rollup)
IF OBJECT_ID(N'dbo.v_ProjectsOnBudget', N'V') IS NOT NULL
    DROP VIEW dbo.v_ProjectsOnBudget;
GO
CREATE VIEW dbo.v_ProjectsOnBudget
AS
WITH spend_by_project AS (
    SELECT
        sl.project_id,
        SUM(sl.amount) AS actual_spend
    FROM dbo.spend_log AS sl
    GROUP BY
        sl.project_id
), project_flags AS (
    SELECT
        p.project_id,
        p.name AS project_name,
        p.budget,
        COALESCE(sb.actual_spend, 0.00) AS actual_spend,
        CASE
            WHEN COALESCE(sb.actual_spend, 0.00) <= p.budget THEN 1 ELSE 0
        END AS is_on_budget
    FROM dbo.projects AS p
    LEFT JOIN spend_by_project AS sb
        ON sb.project_id = p.project_id
)
SELECT
    COUNT(*) AS total_projects,
    SUM(project_flags.is_on_budget) AS projects_on_budget,
    COUNT(*) - SUM(project_flags.is_on_budget) AS projects_over_budget,
    CASE
        WHEN COUNT(*) = 0 THEN NULL
        ELSE CAST(SUM(project_flags.is_on_budget) AS DECIMAL(10,2)) / COUNT(*)
    END AS percent_projects_on_budget
FROM project_flags;
GO

-- Drop and recreate the projects-on-time view using actual completion dates
IF OBJECT_ID(N'dbo.v_ProjectsOnTime', N'V') IS NOT NULL
    DROP VIEW dbo.v_ProjectsOnTime;
GO
CREATE VIEW dbo.v_ProjectsOnTime
AS
WITH completion_data AS (
    SELECT
        p.project_id,
        p.name AS project_name,
        p.end_date AS planned_end_date,
        pc.actual_end_date,
        CASE
            WHEN pc.actual_end_date IS NULL THEN 0
            WHEN pc.actual_end_date <= p.end_date THEN 1
            ELSE 0
        END AS is_on_time
    FROM dbo.projects AS p
    LEFT JOIN dbo.project_completion AS pc
        ON pc.project_id = p.project_id
)
SELECT
    COUNT(*) AS total_projects,
    SUM(is_on_time) AS projects_on_time,
    COUNT(*) - SUM(is_on_time) AS projects_delivered_late,
    CASE
        WHEN COUNT(*) = 0 THEN NULL
        ELSE CAST(SUM(is_on_time) AS DECIMAL(10,2)) / COUNT(*)
    END AS percent_projects_on_time
FROM completion_data;
GO

-- Placeholder note: CPI, SPI, and ROI require future earned value / benefits tables before views can be created
PRINT 'Reminder: Add earned value and benefits tables before modelling CPI, SPI, and ROI KPIs.';

PRINT '06_business_queries.sql complete: analysis queries and KPI views ready for Power BI.';
GO