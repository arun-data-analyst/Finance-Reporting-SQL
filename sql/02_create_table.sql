USE FinanceReporting;
GO

-- =================================================================================================
-- Script: 02_create_table.sql
-- Title : Build the Finance Reporting schema with easy-to-follow explanations
-- Author: Arun Acharya
-- Purpose: Create the lookup and main tables that power the Finance Reporting solution. The script is
--          safe to re-run because each CREATE statement is wrapped with existence checks. Messages are
--          printed along the way so both technical and non-technical readers can see what happens.
-- How to use: Execute the entire file in SQL Server Management Studio (SSMS). Each section introduces
--             the upcoming table, explains its role, and then creates it only if it is currently absent.
-- =================================================================================================

SET NOCOUNT ON;

PRINT 'Preparing to create Finance Reporting tables in schema: dbo...';

/* ================================================================================================
   SECTION 2: Create lookup tables first
   -----------------------------------------------------------------------------------------------
   Lookup tables store reference data that other tables point to. We start with them so the foreign
   key relationships in subsequent tables remain valid.
   ================================================================================================ */

-- 2A. Manager: the people accountable for each project
IF OBJECT_ID('dbo.manager', N'U') IS NULL
BEGIN
    PRINT 'Creating lookup table dbo.manager (one row per manager)...';

    CREATE TABLE dbo.manager (
        manager_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
        manager_name NVARCHAR(100) NOT NULL,
        email        NVARCHAR(100) NOT NULL UNIQUE
    );
END
ELSE
BEGIN
    PRINT 'Lookup table dbo.manager already exists. No changes were made.';
END;

/* ================================================================================================
   SECTION 3: Create the main project tracking tables
   -----------------------------------------------------------------------------------------------
   These tables rely on the manager lookup table for their foreign keys. Each subsection explains
   the type of data captured and the business questions it helps answer.
   ================================================================================================ */

-- 3A. Project: high-level portfolio view
IF OBJECT_ID('dbo.project', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.project (portfolio overview)...';

    CREATE TABLE dbo.project (
        project_id  VARCHAR(10)  NOT NULL PRIMARY KEY,
        project_name NVARCHAR(100) NOT NULL,
        budget      DECIMAL(12, 2) NOT NULL CHECK (budget >= 0),
        start_date  DATE         NOT NULL,
        end_date    DATE         NOT NULL,
        manager_id  VARCHAR(10)  NOT NULL,
        CONSTRAINT CK_project_date_range CHECK (end_date > start_date),
        CONSTRAINT FK_project_manager FOREIGN KEY (manager_id)
            REFERENCES dbo.manager(manager_id)
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.project already exists. No changes were made.';
END;

-- 3B. Spend Log: transaction-level cost tracking
IF OBJECT_ID('dbo.spend_log', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.spend_log (detailed spending entries)...';

    CREATE TABLE dbo.spend_log (
        entry_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
        project_id VARCHAR(10)  NOT NULL,
        spend_date     DATE     NOT NULL,
        category   VARCHAR(50)  NOT NULL,
        amount     DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
        CONSTRAINT FK_spend_log_project FOREIGN KEY (project_id)
            REFERENCES dbo.project(project_id)
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.spend_log already exists. No changes were made.';
END;

-- 3C. Milestone: delivery checkpoints for each project
IF OBJECT_ID('dbo.milestone', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.milestone (project delivery checkpoints)...';

    CREATE TABLE dbo.milestone (
        milestone_id   VARCHAR(10)  NOT NULL PRIMARY KEY,
        project_id     VARCHAR(10)  NOT NULL,
        milestone_name NVARCHAR(100) NOT NULL,
        due_date       DATE         NOT NULL,
        status         NVARCHAR(20)  NOT NULL CHECK (status IN ('Completed', 'Delayed', 'On Track')),
        CONSTRAINT FK_milestone_project FOREIGN KEY (project_id)
            REFERENCES dbo.project(project_id)
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.milestone already exists. No changes were made.';
END;

-- 3D. Forecast: compare future expectations with actuals
IF OBJECT_ID('dbo.forecast', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.forecast (financial outlook vs actuals)...';

    CREATE TABLE dbo.forecast (
        forecast_id     VARCHAR(10)  NOT NULL PRIMARY KEY,
        project_id      VARCHAR(10)  NOT NULL,
        forecast_date   DATE         NOT NULL,
        forecast_amount DECIMAL(12, 2) NOT NULL CHECK (forecast_amount >= 0),
        actual_amount   DECIMAL(12, 2) NOT NULL CHECK (actual_amount >= 0),
        CONSTRAINT FK_forecast_project FOREIGN KEY (project_id)
            REFERENCES dbo.project(project_id)
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.forecast already exists. No changes were made.';
END;

-- 3E. Purchase Order: commitments raised before spend hits the ledger
IF OBJECT_ID('dbo.purchase_order', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.purchase_order (project purchase commitments)...';

    CREATE TABLE dbo.purchase_order (
        po_id      VARCHAR(12)  NOT NULL PRIMARY KEY,
        project_id VARCHAR(10)  NOT NULL,
        po_date    DATE         NOT NULL,
        po_amount  DECIMAL(12, 2) NOT NULL CHECK (po_amount >= 0),
        CONSTRAINT FK_purchase_order_project FOREIGN KEY (project_id)
            REFERENCES dbo.project(project_id)
    );
END
ELSE
BEGIN
    PRINT 'Main table dbo.purchase_order already exists. No changes were made.';
END;

-- 3F. Project Completion: capture the actual completion date for schedule KPIs
IF OBJECT_ID('dbo.project_completion', N'U') IS NULL
BEGIN
    PRINT 'Creating main table dbo.project_completion (actual finish dates)...';

    CREATE TABLE dbo.project_completion (
        project_id       VARCHAR(10) NOT NULL PRIMARY KEY,
        actual_end_date  DATE        NOT NULL,
        CONSTRAINT FK_project_completion_project FOREIGN KEY (project_id)
            REFERENCES dbo.project(project_id)
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
IF OBJECT_ID('dbo.kpi_reference', N'U') IS NULL
BEGIN
    PRINT 'Creating lookup table dbo.kpi_reference (metric definitions and targets)...';

    CREATE TABLE dbo.kpi_reference (
        kpi_name         VARCHAR(50) NOT NULL PRIMARY KEY,
        description      NVARCHAR(MAX) NOT NULL,
        target_threshold NVARCHAR(60) NOT NULL
    );
END
ELSE
BEGIN
    PRINT 'Lookup table dbo.kpi_reference already exists. No changes were made.';
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
   SECTION 6: Friendly wrap-up message
   -----------------------------------------------------------------------------------------------
   The PRINT below confirms that the script completed its checks. If a table already existed, the
   message above it will remind the reader that nothing was changed.
   ================================================================================================ */
PRINT 'Finance Reporting schema check complete. Review the messages above to confirm whether each table was created or already present.';
GO
