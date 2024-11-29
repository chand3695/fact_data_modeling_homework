--A monthly, reduced fact table DDL host_activity_reduced
--month
--host
--hit_array - think COUNT(1)
--unique_visitors array - think COUNT(DISTINCT user_id)

-- Table to store monthly aggregated activity data for each host
CREATE TABLE host_activity_reduced (
    month DATE NOT NULL,                       -- Represents the month (e.g., '2023-01-01' for January 2023)
    host TEXT NOT NULL,                        -- The host identifier (e.g., domain name)
    hit_array BIGINT[] NOT NULL,               -- Stores daily hit counts as an array (COUNT(1) per day)
    unique_visitors_array BIGINT[] NOT NULL,   -- Stores daily unique visitor counts as an array (COUNT(DISTINCT user_id) per day)
    PRIMARY KEY (month, host)                  -- Ensures each host has a unique record for each month
);

