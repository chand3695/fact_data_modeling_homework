--An incremental query that loads host_activity_reduced day-by-day

-- Step 1: Aggregate daily data from the `events` table
WITH daily_aggregates AS (
    SELECT
        DATE_TRUNC('month', DATE(event_time)) AS month, -- Extract the month of the event
        host,                                          -- Host identifier
        EXTRACT(DAY FROM DATE(event_time))::INT AS day, -- Extract the day of the month
        COUNT(1) AS daily_hits,                        -- Total daily hits (COUNT(1))
        COUNT(DISTINCT user_id) AS daily_unique_visitors -- Unique daily visitors (COUNT DISTINCT user_id)
    FROM
        events
    WHERE
        event_time IS NOT NULL                          -- Ensure valid event_time
        AND host IS NOT NULL                            -- Ensure valid host
        AND user_id IS NOT NULL                         -- Ensure valid user_id
    GROUP BY
        DATE_TRUNC('month', DATE(event_time)),          -- Group by month
        host,                                           -- Group by host
        EXTRACT(DAY FROM DATE(event_time))              -- Group by day
),

merged_monthly_data AS (
    SELECT
        d.month,
        d.host,
        -- Generate the updated hit_array for the month
        ARRAY(
            SELECT 
                CASE 
                    -- Handle valid days for the current month
                    WHEN i <= EXTRACT(DAY FROM DATE_TRUNC('month', d.month) + INTERVAL '1 month' - INTERVAL '1 day') THEN
                        COALESCE(h.hit_array[i], 0) + CASE WHEN i = d.day THEN d.daily_hits ELSE 0 END
                    -- Ignore days beyond the end of the month
                    ELSE NULL
                END
            FROM generate_series(1, 31) AS i -- Generate an array for all possible days (up to 31)
        ) FILTER (WHERE i IS NOT NULL) AS hit_array, -- Filter out invalid days
        -- Generate the updated unique_visitors_array for the month
        ARRAY(
            SELECT 
                CASE 
                    WHEN i <= EXTRACT(DAY FROM DATE_TRUNC('month', d.month) + INTERVAL '1 month' - INTERVAL '1 day') THEN
                        COALESCE(h.unique_visitors_array[i], 0) + CASE WHEN i = d.day THEN d.daily_unique_visitors ELSE 0 END
                    ELSE NULL
                END
            FROM generate_series(1, 31) AS i
        ) FILTER (WHERE i IS NOT NULL) AS unique_visitors_array
    FROM
        daily_aggregates d
    LEFT JOIN
        host_activity_reduced h
    ON
        d.month = h.month AND d.host = h.host -- Match the existing monthly data for the same host
)

-- Step 3: Insert or update the aggregated data into the reduced fact table
INSERT INTO host_activity_reduced (month, host, hit_array, unique_visitors_array)
SELECT
    m.month,
    m.host,
    m.hit_array,
    m.unique_visitors_array
FROM
    merged_monthly_data m
ON CONFLICT (month, host) 
DO UPDATE
SET 
    hit_array = EXCLUDED.hit_array,                     -- Update hit_array with new data
    unique_visitors_array = EXCLUDED.unique_visitors_array; -- Update unique_visitors_array with new data