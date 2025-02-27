-- Specifies that the result of this query will be stored as a table in the database.
{{
    config(
        materialized='table'
    )
}}

-- Extracts all columns from the staging table for green taxi trips and adds a column indicating the service type as 'Green'.
with green_tripdata as (
    select *, 
        'Green' as service_type
    from {{ ref('stg_green_tripdata') }}
), 

-- Extracts all columns from the staging table for yellow taxi trips and adds a column indicating the service type as 'Yellow'.
yellow_tripdata as (
    select *, 
        'Yellow' as service_type
    from {{ ref('stg_yellow_tripdata') }}
), 

-- Combines both datasets (green and yellow taxi trips) into a single dataset using UNION ALL (keeping duplicates).
trips_unioned as (
    select * from green_tripdata
    union all 
    select * from yellow_tripdata
), 

-- Selects all columns from the dimension table for location zones, excluding records where the borough is 'Unknown'.
dim_zones as (
    select * from {{ ref('dim_zones') }}
    where borough != 'Unknown'
)

-- Final selection of relevant columns, joining trip data with location zone details.
select trips_unioned.tripid,  -- Unique trip identifier
    trips_unioned.vendorid,  -- ID of the vendor providing the trip
    trips_unioned.service_type,  -- Indicates whether the trip was a 'Green' or 'Yellow' taxi
    trips_unioned.ratecodeid,  -- Code indicating the rate applied to the trip
    trips_unioned.pickup_locationid,  -- Pickup location ID
    pickup_zone.borough as pickup_borough,  -- Borough corresponding to the pickup location
    pickup_zone.zone as pickup_zone,  -- Zone corresponding to the pickup location
    trips_unioned.dropoff_locationid,  -- Dropoff location ID
    dropoff_zone.borough as dropoff_borough,  -- Borough corresponding to the dropoff location
    dropoff_zone.zone as dropoff_zone,  -- Zone corresponding to the dropoff location  
    trips_unioned.pickup_datetime,  -- Timestamp for when the trip started
     -- Extracting the new time dimensions
    extract(year from trips_unioned.pickup_datetime) as pickup_year,
    extract(quarter from trips_unioned.pickup_datetime) as pickup_quarter,
    concat(extract(year from trips_unioned.pickup_datetime), '/Q', extract(quarter from trips_unioned.pickup_datetime)) as pickup_year_quarter,
    extract(month from trips_unioned.pickup_datetime) as pickup_month,
    trips_unioned.dropoff_datetime,  -- Timestamp for when the trip ended
    trips_unioned.store_and_fwd_flag,  -- Indicates whether the trip record was stored and forwarded due to connectivity issues
    trips_unioned.passenger_count,  -- Number of passengers in the trip
    trips_unioned.trip_distance,  -- Distance of the trip in miles
    trips_unioned.trip_type,  -- Type of trip (specific to green taxis)
    trips_unioned.fare_amount,  -- Base fare amount
    trips_unioned.extra,  -- Extra charges (e.g., surcharge for late-night trips)
    trips_unioned.mta_tax,  -- MTA tax applied to the trip
    trips_unioned.tip_amount,  -- Tip amount given by the passenger
    trips_unioned.tolls_amount,  -- Amount paid for tolls during the trip
    trips_unioned.ehail_fee,  -- Electronic hailing fee (if applicable)
    trips_unioned.improvement_surcharge,  -- Additional surcharge applied to trips
    trips_unioned.total_amount,  -- Total amount paid for the trip
    trips_unioned.payment_type,  -- Payment method used (cash, credit card, etc.)
    trips_unioned.payment_type_description  -- Description of the payment method

-- Joins the trip data with the pickup location details using the location ID.
from trips_unioned
inner join dim_zones as pickup_zone
on trips_unioned.pickup_locationid = pickup_zone.locationid

-- Joins the trip data with the dropoff location details using the location ID.
inner join dim_zones as dropoff_zone
on trips_unioned.dropoff_locationid = dropoff_zone.locationid
