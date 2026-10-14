-- Verify the staging data scope.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_id) AS total_stores,
    COUNT(DISTINCT item_id) AS total_products,
    COUNT(DISTINCT sales_date) AS total_days,
    MIN(sales_date) AS start_date,
    MAX(sales_date) AS end_date
FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES;USE WAREHOUSE FMCG_WH;
USE DATABASE FMCG_ANALYTICS;
USE SCHEMA STAGING;

-- Create a standardized sales view for downstream analysis.
CREATE OR REPLACE VIEW FMCG_ANALYTICS.STAGING.STG_FMCG_SALES AS
SELECT
    date AS sales_date,
    d,
    wm_yr_wk,
    weekday,
    wday,
    month,
    year,
    series_id,
    item_id,
    dept_id,
    cat_id,
    store_id,
    state_id,
    units_sold,

    -- Preserve missing prices and revenue as NULL.
    sell_price,
    sales_revenue,
    is_available,

    -- Standardize empty event labels as NULL.
    NULLIF(TRIM(event_name_1), '') AS event_name_1,
    NULLIF(TRIM(event_type_1), '') AS event_type_1,

    snap_eligible,

    -- Identify dates with a recorded event.
    NULLIF(TRIM(event_name_1), '') IS NOT NULL AS is_event_day,

    -- Flag zero sales without assigning a business cause.
    units_sold = 0 AS is_zero_sales

FROM FMCG_ANALYTICS.RAW.FMCG_SALES;

-- Verify the staging data scope.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_id) AS total_stores,
    COUNT(DISTINCT item_id) AS total_products,
    COUNT(DISTINCT sales_date) AS total_days,
    MIN(sales_date) AS start_date,
    MAX(sales_date) AS end_date
FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES;

-- Compare sales performance across stores.
SELECT
    state_id,
    store_id,
    SUM(units_sold) AS total_units_sold,
    ROUND(SUM(sales_revenue), 2) AS total_sales_revenue,
    ROUND(
        SUM(sales_revenue) / COUNT(DISTINCT sales_date),
        2
    ) AS avg_daily_revenue,
    ROUND(
        SUM(sales_revenue) / NULLIF(SUM(units_sold), 0),
        2
    ) AS revenue_per_unit
FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
GROUP BY
    state_id,
    store_id
ORDER BY
    total_sales_revenue DESC;

    -- Summarize monthly sales and account for partial months.
SELECT
    DATE_TRUNC('MONTH', sales_date)::DATE AS sales_month,
    COUNT(DISTINCT sales_date) AS days_in_data,
    SUM(units_sold) AS total_units_sold,
    ROUND(SUM(sales_revenue), 2) AS total_sales_revenue,
    ROUND(
        SUM(sales_revenue) / COUNT(DISTINCT sales_date),
        2
    ) AS avg_daily_revenue
FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
GROUP BY
    DATE_TRUNC('MONTH', sales_date)::DATE
ORDER BY
    sales_month;


-- Aggregate monthly sales.
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('MONTH', sales_date)::DATE AS sales_month,
        COUNT(DISTINCT sales_date) AS days_in_data,
        SUM(units_sold) AS total_units_sold,
        SUM(sales_revenue) AS total_sales_revenue
    FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
    GROUP BY
        DATE_TRUNC('MONTH', sales_date)::DATE
),

-- Keep complete calendar months only.
complete_months AS (
    SELECT *
    FROM monthly_sales
    WHERE days_in_data = DAY(LAST_DAY(sales_month))
)

-- Compare each month with the same month last year.
SELECT
    current_month.sales_month,
    ROUND(current_month.total_sales_revenue, 2)
        AS current_revenue,
    ROUND(previous_year.total_sales_revenue, 2)
        AS prior_year_revenue,
    ROUND(
        100.0 * (
            current_month.total_sales_revenue
            / NULLIF(previous_year.total_sales_revenue, 0) - 1
        ),
        2
    ) AS revenue_yoy_pct,
    ROUND(
        100.0 * (
            current_month.total_units_sold
            / NULLIF(previous_year.total_units_sold, 0) - 1
        ),
        2
    ) AS units_yoy_pct
FROM complete_months AS current_month
INNER JOIN complete_months AS previous_year
    ON current_month.sales_month =
       DATEADD('YEAR', 1, previous_year.sales_month)
ORDER BY
    current_month.sales_month;

    -- Compare revenue contribution across food departments.
WITH department_sales AS (
    SELECT
        dept_id,
        COUNT(DISTINCT item_id) AS total_products,
        SUM(units_sold) AS total_units_sold,
        SUM(sales_revenue) AS total_sales_revenue
    FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
    GROUP BY dept_id
)
SELECT
    dept_id,
    total_products,
    total_units_sold,
    ROUND(total_sales_revenue, 2) AS total_sales_revenue,
    ROUND(
        100.0 * total_sales_revenue
        / NULLIF(SUM(total_sales_revenue) OVER (), 0),
        2
    ) AS revenue_share_pct,
    ROUND(
        total_sales_revenue / NULLIF(total_units_sold, 0),
        2
    ) AS revenue_per_unit
FROM department_sales
ORDER BY total_sales_revenue DESC;

-- Identify the top 10 products by revenue across all stores.
WITH product_sales AS (
    SELECT
        item_id,
        dept_id,
        SUM(units_sold) AS total_units_sold,
        SUM(sales_revenue) AS total_sales_revenue
    FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
    GROUP BY item_id, dept_id
)
SELECT
    item_id,
    dept_id,
    total_units_sold,
    ROUND(total_sales_revenue, 2) AS total_sales_revenue,
    ROUND(
        100.0 * total_sales_revenue
        / NULLIF(SUM(total_sales_revenue) OVER (), 0),
        2
    ) AS revenue_share_pct
FROM product_sales
ORDER BY total_sales_revenue DESC, item_id
LIMIT 10;

-- Aggregate sales across all stores for each date.
WITH daily_sales AS (
    SELECT
        sales_date,
        weekday,
        wday,
        SUM(units_sold) AS daily_units_sold,
        SUM(sales_revenue) AS daily_sales_revenue
    FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
    GROUP BY sales_date, weekday, wday
)

-- Compare average daily performance by weekday.
SELECT
    weekday,
    wday,
    COUNT(*) AS total_days,
    ROUND(AVG(daily_units_sold), 2) AS avg_daily_units,
    ROUND(AVG(daily_sales_revenue), 2) AS avg_daily_revenue
FROM daily_sales
GROUP BY weekday, wday
ORDER BY avg_daily_revenue DESC;

-- Create daily store-department metrics for reporting.
CREATE OR REPLACE VIEW
    FMCG_ANALYTICS.ANALYTICS.DAILY_STORE_DEPT_SALES AS
SELECT
    sales_date,
    state_id,
    store_id,
    dept_id,
    SUM(units_sold) AS total_units_sold,
    SUM(sales_revenue) AS total_sales_revenue,
    COUNT(*) AS product_rows,
    SUM(
        CASE WHEN is_available THEN 1 ELSE 0 END
    ) AS products_with_price
FROM FMCG_ANALYTICS.STAGING.STG_FMCG_SALES
GROUP BY
    sales_date,
    state_id,
    store_id,
    dept_id;

-- Verify row count and reconcile totals with staging.
SELECT
    COUNT(*) AS total_rows,
    SUM(total_units_sold) AS total_units_sold,
    ROUND(SUM(total_sales_revenue), 2) AS total_sales_revenue
FROM FMCG_ANALYTICS.ANALYTICS.DAILY_STORE_DEPT_SALES;