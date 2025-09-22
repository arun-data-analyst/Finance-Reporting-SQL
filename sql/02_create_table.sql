USE FinanceReporting;
GO

-- =================================================================================================
-- Script: 02_create_tables_mf.sql
-- Title : Build the Finance Reporting schema with easy-to-follow explanations
-- Author: Arun Acharya
-- Purpose: Create the lookup and main tables that power the Finance Reporting solution. The script is
--          safe to re-run because each CREATE statement is wrapped with existence checks. Messages are
--          printed along the way so both technical and non-technical readers can see what happens.
-- How to use: Execute the entire file in SQL Server Management Studio (SSMS). Each section introduces
--             the upcoming table, explains its role, and then creates it only if it is currently absent.
-- =================================================================================================

SET NOCOUNT ON;

/* ================================================================================================
   SECTION 1: Helpful context before creating anything
   -----------------------------------------------------------------------------------------------
   The tables live in the default schema named "dbo". The variable below keeps that name in one
   place, making it easier to update later if your environment uses a different schema.
   ================================================================================================ */
DECLARE @TargetSchema SYSNAME = N'dbo';

PRINT 'Preparing to create Finance Reporting tables in schema: ' + QUOTENAME(@TargetSchema) + '...';

/* ================================================================================================
   SECTION 2: Create lookup tables first
   -----------------------------------------------------------------------------------------------
   Lookup tables store reference data that other tables point to. We start with them so the foreign
   key relationships in subsequent tables remain valid.
   ================================================================================================ */

-- 2A. Managers: the people accountable for each project
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.managers', N'U') IS NULL
BEGIN
    PRINT 'Creating lookup table dbo.managers (one row per manager)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.managers (
            manager_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
            manager_name VARCHAR(100) NOT NULL,
            email        VARCHAR(100) NOT NULL UNIQUE
        );'
    );
END
ELSE
BEGIN
    PRINT 'Lookup table dbo.managers already exists. No changes were made.';
END;

/* ================================================================================================
   SECTION 3: Create the main project tracking tables
   -----------------------------------------------------------------------------------------------
   These tables rely on the managers lookup table for their foreign keys. Each subsection explains
   the type of data captured and the business questions it helps answer.
   ================================================================================================ */

-- 3A. Projects: high-level portfolio view
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.projects', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.projects (portfolio overview)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.projects (
            project_id  VARCHAR(10)  NOT NULL PRIMARY KEY,
            name        VARCHAR(100) NOT NULL,
            budget      DECIMAL(12, 2) NOT NULL CHECK (budget >= 0),
            start_date  DATE         NOT NULL,
            end_date    DATE         NOT NULL,
            manager_id  VARCHAR(10)  NOT NULL,
            CONSTRAINT CK_projects_date_range CHECK (end_date > start_date),
            CONSTRAINT FK_projects_manager FOREIGN KEY (manager_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.managers(manager_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.projects already exists. No changes were made.';
END;

-- 3B. Spend Log: transaction-level cost tracking
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.spend_log', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.spend_log (detailed spending entries)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.spend_log (
            entry_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
            project_id VARCHAR(10)  NOT NULL,
            [date]     DATE         NOT NULL,
            category   VARCHAR(50)  NOT NULL,
            amount     DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
            CONSTRAINT FK_spend_log_project FOREIGN KEY (project_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.projects(project_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.spend_log already exists. No changes were made.';
END;

-- 3C. Milestones: delivery checkpoints for each project
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.milestones', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.milestones (project delivery checkpoints)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.milestones (
            milestone_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
            project_id     VARCHAR(10)  NOT NULL,
            milestone_name VARCHAR(100) NOT NULL,
            due_date       DATE         NOT NULL,
            status         VARCHAR(20)  NOT NULL CHECK (status IN (''Completed'', ''Delayed'', ''On Track'')),
            CONSTRAINT FK_milestones_project FOREIGN KEY (project_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.projects(project_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.milestones already exists. No changes were made.';
END;

-- 3D. Forecast: compare future expectations with actuals
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.forecast', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.forecast (financial outlook vs actuals)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.forecast (
            forecast_id     VARCHAR(10)  NOT NULL PRIMARY KEY,
            project_id      VARCHAR(10)  NOT NULL,
            forecast_date   DATE         NOT NULL,
            forecast_amount DECIMAL(12, 2) NOT NULL CHECK (forecast_amount >= 0),
            actual_amount   DECIMAL(12, 2) NOT NULL CHECK (actual_amount >= 0),
            CONSTRAINT FK_forecast_project FOREIGN KEY (project_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.projects(project_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.forecast already exists. No changes were made.';
END;

-- 3E. Purchase Orders: commitments raised before spend hits the ledger
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.purchase_orders', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.purchase_orders (project purchase commitments)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.purchase_orders (
            po_id      VARCHAR(12)  NOT NULL PRIMARY KEY,
            project_id VARCHAR(10)  NOT NULL,
            po_date    DATE         NOT NULL,
            po_amount  DECIMAL(12, 2) NOT NULL CHECK (po_amount >= 0),
            CONSTRAINT FK_purchase_orders_project FOREIGN KEY (project_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.projects(project_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.purchase_orders already exists. No changes were made.';
END;

-- 3F. Project Completion: capture the actual completion date for schedule KPIs
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.project_completion', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.project_completion (actual finish dates)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.project_completion (
            project_id       VARCHAR(10) NOT NULL PRIMARY KEY,
            actual_end_date  DATE        NOT NULL,
            CONSTRAINT FK_project_completion_project FOREIGN KEY (project_id)
                REFERENCES ' + QUOTENAME(@TargetSchema) + N'.projects(project_id)
        );'
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.project_completion already exists. No changes were made.';
END;

/* ================================================================================================
   SECTION 4: Create remaining lookup tables that power dashboards and KPIs
   -----------------------------------------------------------------------------------------------
   The KPI reference table stores descriptive metadata so analytics teams know what each metric means
   and the target threshold they are striving to hit.
   ================================================================================================ */

-- 4A. KPI Reference: glossary of success measures
IF OBJECT_ID(QUOTENAME(@TargetSchema) + N'.kpi_reference', N'U') IS NULL
BEGIN
    PRINT 'Creating lookup table dbo.kpi_reference (metric definitions and targets)...';

    EXEC (
        N'CREATE TABLE ' + QUOTENAME(@TargetSchema) + N'.kpi_reference (
            kpi_name         VARCHAR(50) NOT NULL PRIMARY KEY,
            description      TEXT        NOT NULL,
            target_threshold VARCHAR(20) NOT NULL
        );'
    );
END
ELSE
BEGIN
    PRINT 'Lookup table dbo.kpi_reference already exists. No changes were made.';
END;

-- Make sure the target_threshold column can store descriptive targets (expand to NVARCHAR(60) when needed)
IF EXISTS (
    SELECT 1
    FROM sys.columns AS c
    WHERE
        c.[object_id] = OBJECT_ID(QUOTENAME(@TargetSchema) + N'.kpi_reference')
        AND c.name = 'target_threshold'
        AND (c.max_length < 120 OR c.system_type_id <> TYPE_ID(N'nvarchar'))
)
BEGIN
    PRINT 'Altering dbo.kpi_reference.target_threshold to NVARCHAR(60) for richer target descriptions...';
    EXEC (
        N'ALTER TABLE ' + QUOTENAME(@TargetSchema) + N'.kpi_reference
          ALTER COLUMN target_threshold NVARCHAR(60) NOT NULL;'
    );
END;

/* ================================================================================================
   SECTION 5: Roadmap placeholders for future earned value and benefits tracking
   -----------------------------------------------------------------------------------------------
   Why mention this: KPIs such as CPI (Cost Performance Index), SPI (Schedule Performance Index),
   and ROI (Return on Investment) require earned value and benefit realization data that the current
   schema does not yet capture. The comments below reserve logical table names so teams know where
   to extend the model when that information becomes available.
   ================================================================================================ */
PRINT 'Placeholder: Consider adding dbo.earned_value_tracking and dbo.project_benefits tables in future releases to support CPI/SPI/ROI.';

/* ================================================================================================
   SECTION 5: Friendly wrap-up message
   -----------------------------------------------------------------------------------------------
   The PRINT below confirms that the script completed its checks. If a table already existed, the
   message above it will remind the reader that nothing was changed.
   ================================================================================================ */
PRINT 'Finance Reporting schema check complete. Review the messages above to confirm whether each table was created or already present.';
GO