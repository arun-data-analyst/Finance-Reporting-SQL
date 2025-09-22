USE FinanceReporting;
GO

-- =================================================================================================
-- Script: validation_checks.sql
-- Title : Validate referential integrity and financial rule compliance
-- Author: Arun Acharya
-- Purpose: Run a focused set of checks that confirm table relationships remain intact and that
--          numeric values comply with agreed business rules for the Finance Reporting solution.
-- How to use: Execute the entire script after loading or updating data. Each section prints a clear
--             label before running the inspection query so readers immediately know what is being
--             evaluated. If a result set returns zero rows, that rule is currently satisfied.
-- =================================================================================================

PRINT '===============================================================';
PRINT 'Validation Suite: Structural and Logical Integrity Checks';
PRINT '===============================================================';

/* ================================================================================================
   CHECK 1: Spend entries must point to valid projects
   ================================================================================================ */
PRINT '1. Orphaned spend_log.project_id references';
SELECT entry_id,
       project_id
FROM   spend_log
WHERE  project_id NOT IN (SELECT project_id FROM project);

/* ================================================================================================
   CHECK 2: Projects must be assigned to valid managers
   ================================================================================================ */
PRINT '2. Orphaned project.manager_id references';
SELECT project_id,
       manager_id
FROM   project
WHERE  manager_id NOT IN (SELECT manager_id FROM manager);

/* ================================================================================================
   CHECK 3: Milestone status must stay within the approved list
   ================================================================================================ */
PRINT '3. Milestones with invalid status values';
SELECT milestone_id,
       project_id,
       status
FROM   milestone
WHERE  status NOT IN ('Completed', 'Delayed', 'On Track')
       OR status IS NULL;

/* ================================================================================================
   CHECK 4: Key financial numbers must be non-negative
   ================================================================================================ */
PRINT '4a. Projects with negative budgets';
SELECT project_id,
       budget
FROM   project
WHERE  budget < 0;

PRINT '4b. Spend entries with negative amounts';
SELECT entry_id,
       project_id,
       amount
FROM   spend_log
WHERE  amount < 0;

PRINT '4c. Forecast rows with negative forecast or actual amounts';
SELECT forecast_id,
       project_id,
       forecast_amount,
       actual_amount
FROM   forecast
WHERE  forecast_amount < 0
   OR  actual_amount < 0;

/* ================================================================================================
   CHECK 5: Forecast accuracy should stay within +/-10%
   ================================================================================================ */
PRINT '5. Forecasts where actual spend deviates more than 10 percent';
SELECT forecast_id,
       project_id,
       forecast_amount,
       actual_amount,
       ABS(forecast_amount - actual_amount) / NULLIF(forecast_amount, 0.0) AS accuracy_gap
FROM   forecast
WHERE  forecast_amount > 0
   AND ABS(forecast_amount - actual_amount) / NULLIF(forecast_amount, 0.0) > 0.10;

PRINT '---------------------------------------------------------------';
PRINT 'Validation complete. Investigate any result sets returned above.';
PRINT '---------------------------------------------------------------';
