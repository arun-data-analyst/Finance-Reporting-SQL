-- Script: 01_create_database.sql
-- Title : Create the Finance Reporting database
-- Author: Arun Acharya
-- Purpose: Ensure the FinanceReporting database exists. 
--          Safe to re-run because it checks for existence before creating.
-- How to use: Run this script first in SQL Server Management Studio (SSMS). 
--             It will create the database only if it does not already exist.

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'FinanceReporting')
BEGIN
    PRINT 'Creating FinanceReporting database...';
    CREATE DATABASE FinanceReporting;
END
ELSE
BEGIN
    PRINT 'FinanceReporting database already exists. No action taken.';
END
GO
