-- ============================================================
-- Project: AI-Assisted FMCG Sales Forecasting & Decision Support
-- Script: 01_snowflake_setup_and_load.sql
-- Purpose: Set up Snowflake, load sales data, and validate quality
--
-- Source: Walmart M5 Forecasting Accuracy
-- Scope: FOODS category, 10 stores, 730 days
-- Date range: 2014-05-24 to 2016-05-22
-- Expected rows: 10,490,100
-- ============================================================


-- 1. Set up the warehouse, database, and schemas

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS FMCG_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS FMCG_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS FMCG_ANALYTICS.RAW;
CREATE SCHEMA IF NOT EXISTS FMCG_ANALYTICS.STAGING;
CREATE SCHEMA IF NOT EXISTS FMCG_ANALYTICS.ANALYTICS;

USE WAREHOUSE FMCG_WH;
USE DATABASE FMCG_ANALYTICS;
USE SCHEMA RAW;

SHOW SCHEMAS IN DATABASE FMCG_ANALYTICS;


-- 2. Define the compressed CSV file format

CREATE FILE FORMAT IF NOT EXISTS FMCG_ANALYTICS.RAW.FMCG_CSV_GZ
    TYPE = CSV
    COMPRESSION = GZIP
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('')
    ESCAPE_UNENCLOSED_FIELD = NONE
    DATE_FORMAT = 'YYYY-MM-DD';


-- 3. Create the internal upload stage

CREATE STAGE IF NOT EXISTS FMCG_ANALYTICS.RAW.FMCG_UPLOAD_STAGE
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    FILE_FORMAT = (
        FORMAT_NAME = 'FMCG_ANALYTICS.RAW.FMCG_CSV_GZ'
    );

SHOW STAGES IN SCHEMA FMCG_ANALYTICS.RAW;


-- 4. Create the sales table
-- Column order must match the exported CSV files.
-- Missing prices and revenue remain NULL.

CREATE TABLE IF NOT EXISTS FMCG_ANALYTICS.RAW.FMCG_SALES (
    date            DATE,
    d               VARCHAR,
    wm_yr_wk        INTEGER,
    weekday         VARCHAR,
    wday            INTEGER,
    month           INTEGER,
    year            INTEGER,
    series_id       VARCHAR,
    item_id         VARCHAR,
    dept_id         VARCHAR,
    cat_id          VARCHAR,
    store_id        VARCHAR,
    state_id        VARCHAR,
    units_sold      INTEGER,
    sell_price      NUMBER(18, 4),
    sales_revenue   NUMBER(18, 4),
    is_available    BOOLEAN,
    event_name_1    VARCHAR,
    event_type_1    VARCHAR,
    snap_eligible   INTEGER
);

DESCRIBE TABLE FMCG_ANALYTICS.RAW.FMCG_SALES;


-- 5. Upload files through the Snowflake web interface
-- Navigate to: Ingestion > Add Data > Load files into a Stage
-- Target: FMCG_ANALYTICS.RAW.FMCG_UPLOAD_STAGE
-- Local folder: D:\ai-fmcg-sales-insights\data\processed
--
-- Upload these 10 files without extracting them:
-- fmcg_sales_CA_1.csv.gz
-- fmcg_sales_CA_2.csv.gz
-- fmcg_sales_CA_3.csv.gz
-- fmcg_sales_CA_4.csv.gz
-- fmcg_sales_TX_1.csv.gz
-- fmcg_sales_TX_2.csv.gz
-- fmcg_sales_TX_3.csv.gz
-- fmcg_sales_WI_1.csv.gz
-- fmcg_sales_WI_2.csv.gz
-- fmcg_sales_WI_3.csv.gz

LIST @FMCG_ANALYTICS.RAW.FMCG_UPLOAD_STAGE;


-- 6. Validate files before loading
-- Expected result: zero error rows.
-- This statement does not insert data.

COPY INTO FMCG_ANALYTICS.RAW.FMCG_SALES
FROM @FMCG_ANALYTICS.RAW.FMCG_UPLOAD_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'FMCG_ANALYTICS.RAW.FMCG_CSV_GZ'
)
PATTERN = '.*fmcg_sales_.*[.]csv[.]gz'
VALIDATION_MODE = 'RETURN_ALL_ERRORS';


-- 7. Load files into the sales table
-- Expected: 10 files with status LOADED.
-- Expected per file: 1,049,010 rows loaded and zero errors.
-- Do not add FORCE = TRUE when rerunning this load.

COPY INTO FMCG_ANALYTICS.RAW.FMCG_SALES
FROM @FMCG_ANALYTICS.RAW.FMCG_UPLOAD_STAGE
FILE_FORMAT = (
    FORMAT_NAME = 'FMCG_ANALYTICS.RAW.FMCG_CSV_GZ'
)
PATTERN = '.*fmcg_sales_.*[.]csv[.]gz'
ON_ERROR = 'ABORT_STATEMENT';


-- 8. Verify the overall data scope
-- Expected:
-- total_rows     = 10,490,100
-- total_stores   = 10
-- total_products = 1,437
-- total_days     = 730
-- first_date     = 2014-05-24
-- last_date      = 2016-05-22

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_id) AS total_stores,
    COUNT(DISTINCT item_id) AS total_products,
    COUNT(DISTINCT date) AS total_days,
    MIN(date) AS first_date,
    MAX(date) AS last_date
FROM FMCG_ANALYTICS.RAW.FMCG_SALES;


-- 9. Check required fields and business consistency
-- Observed missing_prices: 282,492.
-- All other checks below returned zero.
-- Missing price means no matching weekly price record.
-- The source does not establish the exact reason.

SELECT
    SUM(CASE
        WHEN date IS NULL OR item_id IS NULL
          OR store_id IS NULL OR units_sold IS NULL
        THEN 1 ELSE 0
    END) AS missing_required_fields,

    SUM(CASE
        WHEN units_sold < 0
        THEN 1 ELSE 0
    END) AS negative_units,

    SUM(CASE
        WHEN cat_id IS NULL OR cat_id <> 'FOODS'
        THEN 1 ELSE 0
    END) AS invalid_category,

    SUM(CASE
        WHEN sell_price IS NULL
        THEN 1 ELSE 0
    END) AS missing_prices,

    SUM(CASE
        WHEN sell_price IS NULL AND units_sold > 0
        THEN 1 ELSE 0
    END) AS sales_without_price,

    SUM(CASE
        WHEN is_available IS NULL
          OR is_available <> (sell_price IS NOT NULL)
        THEN 1 ELSE 0
    END) AS availability_mismatch,

    SUM(CASE
        WHEN sell_price IS NOT NULL
         AND (
             sales_revenue IS NULL
             OR ABS(sales_revenue - units_sold * sell_price) > 0.0001
         )
        THEN 1 ELSE 0
    END) AS revenue_mismatch

FROM FMCG_ANALYTICS.RAW.FMCG_SALES;


-- 10. Check uniqueness at the daily product-store level
-- Expected and observed: duplicate_key_groups = 0.

SELECT COUNT(*) AS duplicate_key_groups
FROM (
    SELECT
        item_id,
        store_id,
        date
    FROM FMCG_ANALYTICS.RAW.FMCG_SALES
    GROUP BY item_id, store_id, date
    HAVING COUNT(*) > 1
) AS duplicates;


-- Next step: Build the STAGING sales layer.
