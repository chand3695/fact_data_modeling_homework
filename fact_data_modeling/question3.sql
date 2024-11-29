--A cumulative query to generate device_activity_datelist from events

-- Step 1: Extract distinct combinations of user_id, device_id, browser_type, and activity_date
WITH distinct_dates AS (
    SELECT 
        user_id,
        device_id,
        browser_type,                           -- Assuming browser_type is present in the events table
        DATE(event_time::timestamp) AS activity_date -- Extract the date part from event_time
    FROM 
        events
    WHERE 
        DATE(event_time::timestamp) BETWEEN '2023-01-01' AND '2023-01-31' -- Filter events within the desired date range
        AND user_id IS NOT NULL
        AND device_id IS NOT NULL
        AND browser_type IS NOT NULL
    GROUP BY 
        user_id, device_id, browser_type, DATE(event_time::timestamp)
),
-- Step 2: Aggregate activity dates into an array per user, device, and browser type
aggregated_activity AS (
    SELECT 
        user_id,
        device_id,
        browser_type,
        ARRAY_AGG(activity_date ORDER BY activity_date) AS activity_dates -- Group dates into an array per browser
    FROM 
        distinct_dates
    GROUP BY 
        user_id, device_id, browser_type
),
-- Step 3: Build the JSONB object for each user and device, mapping browser_type to its array of activity dates
jsonb_activity AS (
    SELECT 
        user_id,
        device_id,
        jsonb_object_agg(browser_type, activity_dates::JSONB) AS device_activity_datelist -- Build JSONB object
    FROM 
        aggregated_activity
    GROUP BY 
        user_id, device_id
)
-- Step 4: Insert the aggregated JSONB object into the user_devices_cumulated table
INSERT INTO user_devices_cumulated (user_id, device_id, device_activity_datelist)
SELECT 
    user_id,
    device_id,
    device_activity_datelist -- The JSONB object containing browser_type and corresponding activity dates
FROM 
    jsonb_activity
ON CONFLICT (user_id, device_id) DO NOTHING; -- Avoiding inserting duplicates for the same user_id and device_id
