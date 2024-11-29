--The incremental query to generate host_activity_datelist

-- Step 1: Extract distinct host and activity_date combinations
WITH distinct_host_dates AS (
    SELECT 
        host,
        DATE(event_time::timestamp) AS activity_date -- Extract the date part from event_time
    FROM 
        events
    WHERE 
        event_time IS NOT NULL AND host IS NOT NULL -- Ensure valid data for event_time and host
    GROUP BY 
        host, DATE(event_time::timestamp) -- Group by host and date to remove duplicates
),

-- Step 2: Aggregate new activity dates into arrays per host
aggregated_new_activity AS (
    SELECT 
        host,
        ARRAY_AGG(DISTINCT activity_date ORDER BY activity_date) AS new_activity_datelist 
        -- ARRAY_AGG: Aggregates unique (DISTINCT) activity dates into an array.
        -- ORDER BY: Ensures the dates in the array are sorted chronologically.
    FROM 
        distinct_host_dates
    GROUP BY 
        host -- Grouping ensures one array per host
),

-- Step 3: Merge existing host_activity_datelist with new activity
merged_activity AS (
    SELECT 
        a.host,
        ARRAY(
            SELECT DISTINCT unnest(
                COALESCE(h.host_activity_datelist, '{}') || a.new_activity_datelist
            )
        ) AS updated_host_activity_datelist
        -- COALESCE: If the host already exists but has no previous activity (NULL), initialize with an empty array '{}'.
        -- || (Array Concatenation): Combines the existing activity dates with the new ones.
        -- DISTINCT unnest(...): Deduplicates the merged array, ensuring no duplicate dates are present.
    FROM 
        aggregated_new_activity a
    LEFT JOIN 
        hosts_cumulated h
    ON 
        a.host = h.host -- Join to find existing activity data for the same host
)

-- Step 4: Insert new hosts or update existing ones
INSERT INTO hosts_cumulated (host, host_activity_datelist)
SELECT 
    merged_activity.host,
    merged_activity.updated_host_activity_datelist
FROM 
    merged_activity
ON CONFLICT (host) DO UPDATE
SET 
    host_activity_datelist = EXCLUDED.host_activity_datelist; 
    -- ON CONFLICT: Ensures no duplicate rows are inserted for the same host.
    -- DO UPDATE: Updates the host_activity_datelist with the merged array.
