﻿USE FinanceReporting;
GO

-- =================================================================================================
-- Script: 03_insert_data.sql
-- Title : Populate the Finance Reporting database with a comprehensive demonstration dataset
-- Author: Arun Acharya
-- Purpose: This idempotent script populates the manager, project, spend_log, milestone, forecast,
--          and kpi_reference tables with a larger, easy-to-understand dataset that resembles activity
--          across 10 managers and approximately 50 projects. It is written with extensive explanations
--          so that both technical and non-technical readers can follow along.
-- How to use: Run the entire script. It safely checks what is already stored before inserting new
--             rows, so you can execute it multiple times without creating duplicate records.
-- =================================================================================================

/* ================================================================================================
   SECTION 1: Prepare easy-to-read reference data in memory
   ----------------------------------------------------------------------------------------------
   Why we do this: We collect the rows we want to add inside table variables. Table variables behave
   like short-lived tables. They make the list of values visible in one place and keep the script
   tidy. Later we copy the rows into the real tables only when they are missing.
   ================================================================================================ */

/* -----------------------------------------------
   1A. Manager (10 leaders responsible for projects)
   ----------------------------------------------- */
DECLARE @Manager TABLE (
    manager_id   CHAR(4)     NOT NULL PRIMARY KEY,
    manager_name NVARCHAR(100) NOT NULL,
    email        NVARCHAR(100) NOT NULL
);

INSERT INTO @Manager (manager_id, manager_name, email)
VALUES
    ('M001', 'Arun Acharya', 'arun.acharya@proman.com'),
    ('M002', 'Emily Chen', 'emily.chen@proman.com'),
    ('M003', 'David Lin', 'david.lin@proman.com'),
    ('M004', 'Sarah Johnson', 'sarah.johnson@proman.com'),
    ('M005', 'Michael Brown', 'michael.brown@proman.com'),
    ('M006', 'Mahoro Lilian', 'mahoro.lilian@proman.com'),
    ('M007', 'Lucas Martinez', 'lucas.martinez@proman.com'),
    ('M008', 'Hannah Weiss', 'hannah.weiss@proman.com'),
    ('M009', 'Jamal Carter', 'jamal.carter@proman.com'),
    ('M010', 'Sofia Petrova', 'sofia.petrova@proman.com');

/* -----------------------------------------------------------
   1B. Project (around 50 initiatives aligned to those managers)
   ----------------------------------------------------------- */
DECLARE @Project TABLE (
    project_seq  INT          NOT NULL PRIMARY KEY,
    project_id   CHAR(4)      NOT NULL,
    project_name NVARCHAR(100) NOT NULL,
    budget       DECIMAL(14,2) NOT NULL,
    start_date   DATE         NOT NULL,
    end_date     DATE         NOT NULL,
    manager_id   CHAR(4)      NOT NULL
);

INSERT INTO @Project (project_seq, project_id, project_name, budget, start_date, end_date, manager_id)
VALUES
    ( 1, 'P001', '5G Tower Deployment - East Region',            650000, '2025-01-01', '2025-12-15', 'M001'),
    ( 2, 'P002', '5G Tower Deployment - North Region',           600000, '2025-02-01', '2026-01-31', 'M001'),
    ( 3, 'P003', 'Urban Small Cell Rollout',                     320000, '2025-03-01', '2025-11-30', 'M001'),
    ( 4, 'P004', 'Microwave Backhaul Upgrade',                   280000, '2025-04-01', '2025-12-01', 'M001'),
    ( 5, 'P005', 'Fiber Backbone Expansion',                     450000, '2025-05-01', '2026-03-31', 'M001'),
    ( 6, 'P006', 'Legacy System Modernization',                  370000, '2025-01-01', '2025-10-31', 'M002'),
    ( 7, 'P007', 'Data Warehouse Refresh',                       290000, '2025-02-01', '2025-09-30', 'M002'),
    ( 8, 'P008', 'ERP Integration Wave 1',                       410000, '2025-03-01', '2026-02-28', 'M002'),
    ( 9, 'P009', 'ERP Integration Wave 2',                       430000, '2025-06-01', '2026-05-31', 'M002'),
    (10, 'P010', 'Finance Automation Toolkit',                   220000, '2025-04-01', '2025-12-31', 'M002'),
    (11, 'P011', 'AI Network Optimization Pilot',                180000, '2025-01-01', '2025-09-30', 'M003'),
    (12, 'P012', 'Predictive Maintenance Platform',              260000, '2025-02-01', '2025-12-31', 'M003'),
    (13, 'P013', 'Chatbot Customer Support',                     140000, '2025-03-01', '2025-10-31', 'M003'),
    (14, 'P014', 'Traffic Analytics Dashboard',                  200000, '2025-04-01', '2025-12-31', 'M003'),
    (15, 'P015', 'Robotic Process Automation',                   240000, '2025-05-01', '2026-01-31', 'M003'),
    (16, 'P016', 'Cybersecurity Hardening Sprint',               310000, '2025-01-01', '2025-11-30', 'M004'),
    (17, 'P017', 'Identity Access Overhaul',                     270000, '2025-02-01', '2025-12-15', 'M004'),
    (18, 'P018', 'Zero Trust Pilot Program',                     330000, '2025-03-01', '2026-01-31', 'M004'),
    (19, 'P019', 'Incident Response Automation',                 190000, '2025-04-01', '2025-12-01', 'M004'),
    (20, 'P020', 'Security Awareness Campaign',                  150000, '2025-05-01', '2025-10-31', 'M004'),
    (21, 'P021', 'Rural Coverage Expansion - North',             520000, '2025-01-01', '2025-12-31', 'M005'),
    (22, 'P022', 'Rural Coverage Expansion - West',              540000, '2025-02-01', '2026-01-31', 'M005'),
    (23, 'P023', 'Satellite Backhaul Pilot',                     380000, '2025-03-01', '2026-02-28', 'M005'),
    (24, 'P024', 'Emergency Network Upgrade',                    260000, '2025-04-01', '2025-12-31', 'M005'),
    (25, 'P025', 'Disaster Recovery Readiness',                  300000, '2025-05-01', '2026-03-31', 'M005'),
    (26, 'P026', 'Customer Analytics Platform',                  275000, '2025-01-01', '2025-11-30', 'M006'),
    (27, 'P027', 'Marketing Automation Revamp',                  195000, '2025-02-01', '2025-09-30', 'M006'),
    (28, 'P028', 'Omnichannel Experience Launch',                335000, '2025-03-01', '2026-01-31', 'M006'),
    (29, 'P029', 'Loyalty Program Redesign',                     180000, '2025-04-01', '2025-12-15', 'M006'),
    (30, 'P030', 'Brand Intelligence Dashboard',                 210000, '2025-05-01', '2025-12-31', 'M006'),
    (31, 'P031', 'Edge Computing Lab Setup',                     265000, '2025-01-01', '2025-10-31', 'M007'),
    (32, 'P032', 'MEC Customer Pilot Series',                    295000, '2025-02-01', '2025-12-31', 'M007'),
    (33, 'P033', 'Smart City Sensor Grid',                       410000, '2025-03-01', '2026-02-28', 'M007'),
    (34, 'P034', 'Autonomous Vehicle Trials',                    360000, '2025-04-01', '2026-03-31', 'M007'),
    (35, 'P035', 'Industrial IoT Partnerships',                  340000, '2025-05-01', '2026-01-31', 'M007'),
    (36, 'P036', 'Cloud Migration Foundation',                   300000, '2025-01-01', '2025-10-31', 'M008'),
    (37, 'P037', 'Multi-Cloud Governance Framework',             280000, '2025-02-01', '2025-11-30', 'M008'),
    (38, 'P038', 'Container Platform Build-out',                 320000, '2025-03-01', '2026-01-15', 'M008'),
    (39, 'P039', 'DevOps Automation Wave',                       240000, '2025-04-01', '2025-12-31', 'M008'),
    (40, 'P040', 'Continuous Testing Framework',                 210000, '2025-05-01', '2025-12-01', 'M008'),
    (41, 'P041', 'Data Privacy Compliance Program',              230000, '2025-01-01', '2025-09-30', 'M009'),
    (42, 'P042', 'Regulatory Reporting Suite',                   260000, '2025-02-01', '2025-12-15', 'M009'),
    (43, 'P043', 'ESG Reporting Platform',                       280000, '2025-03-01', '2025-12-31', 'M009'),
    (44, 'P044', 'Risk Scoring Modernization',                   250000, '2025-04-01', '2026-01-31', 'M009'),
    (45, 'P045', 'Audit Workflow Automation',                    190000, '2025-05-01', '2025-11-30', 'M009'),
    (46, 'P046', 'HR Talent Analytics',                          185000, '2025-01-01', '2025-09-30', 'M010'),
    (47, 'P047', 'Learning Experience Refresh',                  175000, '2025-02-01', '2025-10-31', 'M010'),
    (48, 'P048', 'Workplace Collaboration Suite',                260000, '2025-03-01', '2025-12-31', 'M010'),
    (49, 'P049', 'Facilities IoT Monitoring',                    225000, '2025-04-01', '2026-01-31', 'M010'),
    (50, 'P050', 'Sustainability Innovation Lab',                315000, '2025-05-01', '2026-03-31', 'M010');

/* -----------------------------------------------------------------
   1C. Spend patterns (reusable blueprint for monthly spend activity)
   -----------------------------------------------------------------
   Each project will show five spend events across the first five months.
   Percentages add up to 90% to leave room for variance in real life.
   ----------------------------------------------------------------- */
DECLARE @SpendPattern TABLE (
    sequence_no     INT            NOT NULL PRIMARY KEY,
    category        VARCHAR(50)   NOT NULL,
    month_offset    INT            NOT NULL,
    day_offset      INT            NOT NULL,
    spend_fraction  DECIMAL(6,4)   NOT NULL
);

INSERT INTO @SpendPattern (sequence_no, category, month_offset, day_offset, spend_fraction)
VALUES
    (1, 'Planning & Design', 0, 14, 0.08),
    (2, 'Labor',             1, 18, 0.22),
    (3, 'Equipment',         2, 12, 0.28),
    (4, 'Software',          3, 16, 0.18),
    (5, 'Professional Services', 4, 20, 0.14);

/* ------------------------------------------------------
   1D. Milestone stage (three checkpoints per project)
   ------------------------------------------------------ */
DECLARE @MilestoneStage TABLE (
    stage_number  INT           NOT NULL PRIMARY KEY,
    milestone_name NVARCHAR(100) NOT NULL,
    month_offset  INT           NOT NULL,
    day_offset    INT           NOT NULL,
    default_status NVARCHAR(20) NOT NULL
);

INSERT INTO @MilestoneStage (stage_number, milestone_name, month_offset, day_offset, default_status)
VALUES
    (1, 'Project Kick-off Complete', 0, 7,  'Completed'),
    (2, 'Midpoint Health Review',    3, 0,  'On Track'),
    (3, 'Final Delivery Preparation',6, 0,  'On Track');

/* -----------------------------------------------------------------------
   1E. Forecast pattern (expected vs. actual outlook by project phase)
   -----------------------------------------------------------------------
   We forecast at the end of months 2, 4, 6, and 8 relative to a project start.
   Actuals deviate slightly to mimic real execution. All values stay positive.
   ----------------------------------------------------------------------- */
DECLARE @ForecastPattern TABLE (
    sequence_no        INT           NOT NULL PRIMARY KEY,
    month_offset       INT           NOT NULL,
    day_offset         INT           NOT NULL,
    forecast_fraction  DECIMAL(6,4)  NOT NULL,
    actual_multiplier  DECIMAL(6,4)  NOT NULL
);

INSERT INTO @ForecastPattern (sequence_no, month_offset, day_offset, forecast_fraction, actual_multiplier)
VALUES
    (1, 1, 25, 0.18, 0.95),
    (2, 3, 25, 0.32, 1.05),
    (3, 5, 25, 0.27, 0.92),
    (4, 7, 25, 0.21, 1.08);

/* -----------------------------------------------------------------
   1F. Purchase order pattern (simulate commitments before spend hits)
   ----------------------------------------------------------------- */
DECLARE @PurchaseOrderPattern TABLE (
    sequence_no    INT           NOT NULL PRIMARY KEY,
    month_offset   INT           NOT NULL,
    day_offset     INT           NOT NULL,
    po_fraction    DECIMAL(6,4)  NOT NULL
);

INSERT INTO @PurchaseOrderPattern (sequence_no, month_offset, day_offset, po_fraction)
VALUES
    (1, 0, 5,  0.30),
    (2, 1, 12, 0.35),
    (3, 2, 20, 0.25);

/* ------------------------------------------------------------
   1G. KPI reference entries (expanded to cover finance KPIs)
   ------------------------------------------------------------ */
DECLARE @KpiReference TABLE (
    kpi_name         NVARCHAR(50)  NOT NULL PRIMARY KEY,
    description      NVARCHAR(MAX) NOT NULL,
    target_threshold NVARCHAR(60)  NOT NULL
);

INSERT INTO @KpiReference (kpi_name, description, target_threshold)
VALUES
    ('Budget Variance (Cost Variance)', 'Difference between approved budget and actual spend recorded to date.', 'Aim for variance within ±5%'),
    ('Budget Utilization', 'Portion of the approved budget that has been consumed by actual spend.', 'Stay below 95% until final month'),
    ('Forecast Accuracy', 'How closely forecasts align with actual costs for each period.', 'Maintain ±5% difference'),
    ('On-Time Milestone Completion Rate', 'Percent of completed milestones delivered on or before their due dates.', '≥ 90% of milestones on time'),
    ('On-Time Project Delivery', 'Percent of projects where the actual end date met or beat the planned end date.', '≥ 85% projects delivered on schedule'),
    ('Projects On Budget', 'Percent of projects where cumulative spend is within approved budget.', '≥ 80% projects within budget'),
    ('Burn Rate', 'Average spend per day based on cumulative spend and elapsed time.', 'Contextual target – monitor trending above plan'),
    ('Cost Performance Index (CPI)', 'Requires earned value (EV) data to compare EV to Actual Cost.', 'Pending earned_value_tracking table'),
    ('Schedule Performance Index (SPI)', 'Requires earned value schedule data to compare EV to Planned Value.', 'Pending earned_value_tracking table'),
    ('Return on Investment (ROI)', 'Requires benefit realization amounts after project completion.', 'Pending project_benefits table');

/* ================================================================================================
   SECTION 2: Derive spend, milestone, forecast, and procurement rows from the blueprints
   ----------------------------------------------------------------------------------------------
   Why we do this: Rather than type hundreds of rows manually, we recycle the patterns defined in
   the previous section. The CROSS APPLY statements pair every project with each spend, milestone,
   forecast, and purchase order template, while the completion table derives actual finish dates.
   The result is richly populated yet easy-to-maintain sample data.
   ================================================================================================ */

DECLARE @SpendLog TABLE (
    entry_id    NVARCHAR(10) NOT NULL PRIMARY KEY,
    project_id  CHAR(4)      NOT NULL,
    spend_date  DATE         NOT NULL,
    category    NVARCHAR(50) NOT NULL,
    amount      DECIMAL(12,2) NOT NULL
);

INSERT INTO @SpendLog (entry_id, project_id, spend_date, category, amount)
SELECT
    CONCAT('E', RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY p.project_id, sp.sequence_no) AS VARCHAR(4)), 4)) AS entry_id,
    p.project_id,
    CASE
        WHEN DATEADD(DAY, sp.day_offset, DATEADD(MONTH, sp.month_offset, p.start_date)) <= p.end_date THEN
            DATEADD(DAY, sp.day_offset, DATEADD(MONTH, sp.month_offset, p.start_date))
        ELSE
            p.end_date
    END AS spend_date,
    sp.category,
    ROUND(p.budget * sp.spend_fraction, 2) AS amount
FROM @Project AS p
CROSS APPLY @SpendPattern AS sp;

DECLARE @Milestone TABLE (
    milestone_id   NVARCHAR(10) NOT NULL PRIMARY KEY,
    project_id     CHAR(4)      NOT NULL,
    milestone_name NVARCHAR(100) NOT NULL,
    due_date       DATE         NOT NULL,
    status         NVARCHAR(20) NOT NULL
);

INSERT INTO @Milestone (milestone_id, project_id, milestone_name, due_date, status)
SELECT
    CONCAT('MS', RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY p.project_id, ms.stage_number) AS VARCHAR(3)), 3)) AS milestone_id,
    p.project_id,
    ms.milestone_name,
    CASE
        WHEN DATEADD(DAY, ms.day_offset, DATEADD(MONTH, ms.month_offset, p.start_date)) <= p.end_date THEN
            DATEADD(DAY, ms.day_offset, DATEADD(MONTH, ms.month_offset, p.start_date))
        ELSE
            p.end_date
    END AS due_date,
    ms.default_status AS status
FROM @Project AS p
CROSS APPLY @MilestoneStage AS ms;

DECLARE @Forecast TABLE (
    forecast_id     NVARCHAR(10) NOT NULL PRIMARY KEY,
    project_id      CHAR(4)      NOT NULL,
    forecast_date   DATE         NOT NULL,
    forecast_amount DECIMAL(12,2) NOT NULL,
    actual_amount   DECIMAL(12,2) NOT NULL
);

INSERT INTO @Forecast (forecast_id, project_id, forecast_date, forecast_amount, actual_amount)
SELECT
    CONCAT('F', RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY p.project_id, fp.sequence_no) AS VARCHAR(5)), 5)) AS forecast_id,
    p.project_id,
    CASE
        WHEN DATEADD(DAY, fp.day_offset, DATEADD(MONTH, fp.month_offset, p.start_date)) <= p.end_date THEN
            DATEADD(DAY, fp.day_offset, DATEADD(MONTH, fp.month_offset, p.start_date))
        ELSE
            p.end_date
    END AS forecast_date,
    ROUND(p.budget * fp.forecast_fraction, 2) AS forecast_amount,
    ROUND(p.budget * fp.forecast_fraction * fp.actual_multiplier, 2) AS actual_amount
FROM @Project AS p
CROSS APPLY @ForecastPattern AS fp;

/* -------------------------------------------------------------
   Derived purchase orders (mirror common procurement cadence)
   ------------------------------------------------------------- */
DECLARE @PurchaseOrder TABLE (
    po_id      NVARCHAR(12) NOT NULL PRIMARY KEY,
    project_id CHAR(4)      NOT NULL,
    po_date    DATE         NOT NULL,
    po_amount  DECIMAL(12,2) NOT NULL
);

INSERT INTO @PurchaseOrder (po_id, project_id, po_date, po_amount)
SELECT
    CONCAT('PO', RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY p.project_id, pop.sequence_no) AS VARCHAR(5)), 5)) AS po_id,
    p.project_id,
    CASE
        WHEN DATEADD(DAY, pop.day_offset, DATEADD(MONTH, pop.month_offset, p.start_date)) <= p.end_date THEN
            DATEADD(DAY, pop.day_offset, DATEADD(MONTH, pop.month_offset, p.start_date))
        ELSE
            p.end_date
    END AS po_date,
    ROUND(p.budget * pop.po_fraction, 2) AS po_amount
FROM @Project AS p
CROSS APPLY @PurchaseOrderPattern AS pop;

/* -------------------------------------------------------------
   Actual completion dates (needed for on-time delivery KPI)
   ------------------------------------------------------------- */
DECLARE @ProjectCompletion TABLE (
    project_id      CHAR(4) NOT NULL PRIMARY KEY,
    actual_end_date DATE    NOT NULL
);

INSERT INTO @ProjectCompletion (project_id, actual_end_date)
SELECT
    p.project_id,
    DATEADD(DAY,
        CASE (p.project_seq % 6)
            WHEN 0 THEN 7   -- finished one week late
            WHEN 1 THEN -5  -- wrapped up early
            WHEN 2 THEN 0   -- exactly on time
            WHEN 3 THEN 14  -- two weeks late
            WHEN 4 THEN -10 -- significantly early
            ELSE 3          -- just a few days late
        END,
        p.end_date
    ) AS actual_end_date
FROM @Project AS p;

/* ================================================================================================
   SECTION 3: Insert the prepared data into the live tables (idempotent approach)
   ----------------------------------------------------------------------------------------------
   Why we do this: We move the data from our temporary lists into the production tables. The WHERE
   NOT EXISTS clause ensures we only add rows that are not already present, allowing you to rerun
   the script safely at any time.
   ================================================================================================ */

-- 3A. Insert manager
INSERT INTO manager (manager_id, manager_name, email)
SELECT src.manager_id, src.manager_name, src.email
FROM @Manager AS src
WHERE NOT EXISTS (
    SELECT 1 FROM manager AS tgt WHERE tgt.manager_id = src.manager_id
);

-- 3B. Insert project
INSERT INTO project (project_id, project_name, budget, start_date, end_date, manager_id)
SELECT src.project_id, src.project_name, src.budget, src.start_date, src.end_date, src.manager_id
FROM @Project AS src
WHERE NOT EXISTS (
    SELECT 1 FROM project AS tgt WHERE tgt.project_id = src.project_id
);

-- 3C. Insert spend log entries
INSERT INTO spend_log (entry_id, project_id, spend_date, category, amount)
SELECT src.entry_id, src.project_id, src.spend_date, src.category, src.amount
FROM @SpendLog AS src
WHERE NOT EXISTS (
    SELECT 1 FROM spend_log AS tgt WHERE tgt.entry_id = src.entry_id
);

-- 3D. Insert milestone
INSERT INTO milestone (milestone_id, project_id, milestone_name, due_date, status)
SELECT src.milestone_id, src.project_id, src.milestone_name, src.due_date, src.status
FROM @Milestone AS src
WHERE NOT EXISTS (
    SELECT 1 FROM milestone AS tgt WHERE tgt.milestone_id = src.milestone_id
);

-- 3E. Insert forecast outlooks
INSERT INTO forecast (forecast_id, project_id, forecast_date, forecast_amount, actual_amount)
SELECT src.forecast_id, src.project_id, src.forecast_date, src.forecast_amount, src.actual_amount
FROM @Forecast AS src
WHERE NOT EXISTS (
    SELECT 1 FROM forecast AS tgt WHERE tgt.forecast_id = src.forecast_id
);

-- 3F. Insert purchase order
INSERT INTO purchase_order (po_id, project_id, po_date, po_amount)
SELECT src.po_id, src.project_id, src.po_date, src.po_amount
FROM @PurchaseOrder AS src
WHERE NOT EXISTS (
    SELECT 1 FROM purchase_order AS tgt WHERE tgt.po_id = src.po_id
);

-- 3G. Insert project completion date
INSERT INTO project_completion (project_id, actual_end_date)
SELECT src.project_id, src.actual_end_date
FROM @ProjectCompletion AS src
WHERE NOT EXISTS (
    SELECT 1 FROM project_completion AS tgt WHERE tgt.project_id = src.project_id
);

-- 3H. Insert KPI reference definition
INSERT INTO kpi_reference (kpi_name, description, target_threshold)
SELECT src.kpi_name, src.description, src.target_threshold
FROM @KpiReference AS src
WHERE NOT EXISTS (
    SELECT 1 FROM kpi_reference AS tgt WHERE tgt.kpi_name = src.kpi_name
);
/* ================================================================================================
   SECTION 4: Helpful completion message
   ----------------------------------------------------------------------------------------------
   Providing a short confirmation keeps the user informed when the script finishes executing.
   ================================================================================================ */

PRINT '03_insert_data.sql complete: manager, project, spend_log, milestone, forecast, purchase order, completion date, and KPI reference data are populated.';
GO