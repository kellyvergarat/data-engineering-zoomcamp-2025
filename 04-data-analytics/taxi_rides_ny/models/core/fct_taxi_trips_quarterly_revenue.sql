-- Specifies that the result of this query will be stored as a table in the database.
{{
    config(
        materialized='table'
    )
}}

-- Step 1: Compute the quarterly revenue for each year and service type
WITH quarterly_revenue AS (
    SELECT
        pickup_year,  -- Extract year from datetime
        pickup_quarter, -- Extract quarter from datetime
        pickup_year_quarter, -- Create a formatted year/quarter string
        service_type,  -- Identify the service type (Green/Yellow taxi)
        SUM(total_amount) AS quarterly_revenue  -- Compute total revenue for each quarter
    FROM {{ ref('fact_trips') }}  -- Use the taxi trips fact table
    WHERE pickup_year IN (2019, 2020)  -- Ensure only data from 2019 and 2020 is used
    GROUP BY 1, 2, 3, 4  -- Group by year, quarter, formatted year/quarter, and service type
)
-- Step 2: Compute the YoY growth by comparing each quarter to the previous year's same quarter
SELECT 
    q1.pickup_year,  -- Current year
    q1.pickup_quarter,  -- Current quarter
    q1.pickup_year_quarter,  -- Formatted year/quarter
    q1.service_type,  -- Taxi service type
    q1.quarterly_revenue,  -- Current quarter's revenue
    q2.quarterly_revenue AS prev_quarterly_revenue, -- Previous year's same quarter revenue
    -- Calculate the YoY growth percentage
    ROUND(((q1.quarterly_revenue - q2.quarterly_revenue) / q2.quarterly_revenue) * 100, 2) AS yoy_growth
FROM quarterly_revenue q1
LEFT JOIN quarterly_revenue q2 
    ON q1.service_type = q2.service_type  -- Match by service type
    AND q1.pickup_year = q2.pickup_year + 1  -- Compare with the previous year's same quarter
    AND q1.pickup_quarter = q2.pickup_quarter  -- Ensure it's the same quarter
