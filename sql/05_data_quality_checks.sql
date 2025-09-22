USE FinanceReporting;
GO
-- =================================================================================================
-- Script: data_quality_checks.sql
-- Title : Scan Finance Reporting tables for duplicates, gaps, and outliers
-- Author: Arun Acharya 
-- Purpose: Provide a human-friendly dashboard of quality checks that highlight data hygiene issues
--          beyond strict relational rules. Each section describes the intent so business users and
--          analysts can act quickly on the findings.
-- How to use: Run the script end-to-end after refreshing or importing data. Read the printed label
--             that precedes each query and investigate any rows returned. An empty result means the
--             dataset currently passes that check.
-- =================================================================================================

PRINT '===============================================================';
PRINT 'Data Quality Suite: Duplicates, Nulls, Outliers, and Gaps';
PRINT '===============================================================';

/* ================================================================================================
   CHECK 1: Duplicate spend_log entry identifiers
   ================================================================================================ */
PRINT '1. Duplicate spend_log entry_id values';
SELECT entry_id,
       COUNT(*) AS duplicate_count
FROM   spend_log
GROUP BY entry_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC,
         entry_id;

/* ================================================================================================
   CHECK 2: Duplicate milestone names within the same project
   ================================================================================================ */
PRINT '2. Duplicate milestone names per project';
SELECT project_id,
       milestone_name,
       COUNT(*) AS duplicate_count
FROM   milestone
GROUP BY project_id,
         milestone_name
HAVING COUNT(*) > 1
ORDER BY project_id,
         milestone_name;

/* ================================================================================================
   CHECK 3: Duplicate forecast dates per project
   ================================================================================================ */
PRINT '3. Duplicate forecast dates for a single project';
SELECT project_id,
       forecast_date,
       COUNT(*) AS duplicate_count
FROM   forecast
GROUP BY project_id,
         forecast_date
HAVING COUNT(*) > 1
ORDER BY project_id,
         forecast_date;

/* ================================================================================================
   CHECK 4: Missing financial values
   ================================================================================================ */
PRINT '4a. Projects missing a budget amount';
SELECT project_id
FROM   project
WHERE  budget IS NULL;

PRINT '4b. Spend entries missing category or amount';
SELECT entry_id,
       project_id,
       category,
       amount
FROM   spend_log
WHERE  amount  IS NULL
   OR  category IS NULL;

PRINT '4c. Forecast entries missing forecast or actual values';
SELECT forecast_id,
       project_id,
       forecast_amount,
       actual_amount
FROM   forecast
WHERE  forecast_amount IS NULL
   OR  actual_amount   IS NULL;

/* ================================================================================================
   CHECK 5: Projects without assigned managers
   ================================================================================================ */
PRINT '5. Projects without a manager_id';
SELECT project_id,
       project_name
FROM   project
WHERE  manager_id IS NULL;

/* ================================================================================================
   CHECK 6: Spend entries with blank or invalid categories
   ================================================================================================ */
PRINT '6. Spend entries missing valid category labels';
SELECT entry_id,
       project_id,
       category
FROM   spend_log
WHERE  category IS NULL
   OR  LTRIM(RTRIM(category)) = '';

/* ================================================================================================
   CHECK 7: Spend outliers (amount greater than 3x the project average)
   ================================================================================================ */
PRINT '7. Spend entries that exceed three times the project average';
WITH SpendAverages AS (
    SELECT project_id,
           AVG(amount * 1.0) AS avg_amount
    FROM   spend_log
    WHERE  amount IS NOT NULL
    GROUP BY project_id
)
SELECT s.project_id,
       s.entry_id,
       s.amount,
       sa.avg_amount
FROM   spend_log s
JOIN   SpendAverages sa
       ON sa.project_id = s.project_id
WHERE  sa.avg_amount > 0
   AND s.amount > 3 * sa.avg_amount
ORDER BY s.project_id,
         s.amount DESC;

/* ================================================================================================
   CHECK 8: Forecast deviations greater than 50%
   ================================================================================================ */
PRINT '8. Forecast rows with deviations greater than 50 percent';
SELECT forecast_id,
       project_id,
       forecast_date,
       forecast_amount,
       actual_amount,
       ABS(forecast_amount - actual_amount) / NULLIF(forecast_amount, 0.0) AS deviation
FROM   forecast
WHERE  forecast_amount > 0
   AND ABS(forecast_amount - actual_amount) / NULLIF(forecast_amount, 0.0) > 0.50
ORDER BY project_id,
         forecast_date;

/* ================================================================================================
   CHECK 9: Projects lacking milestones
   ================================================================================================ */
PRINT '9. Projects that do not yet have milestones';
SELECT p.project_id,
       p.project_name
FROM   project p
LEFT JOIN milestone m
       ON p.project_id = m.project_id
WHERE  m.project_id IS NULL
ORDER BY p.project_id;

/* ================================================================================================
   CHECK 10: Projects without spend activity
   ================================================================================================ */
PRINT '10. Projects that have no spend_log entries';
SELECT p.project_id,
       p.project_name
FROM   project p
LEFT JOIN spend_log s
       ON p.project_id = s.project_id
WHERE  s.project_id IS NULL
ORDER BY p.project_id;

PRINT '---------------------------------------------------------------';
PRINT 'Data quality review complete. Investigate any result sets above.';
PRINT '---------------------------------------------------------------';
