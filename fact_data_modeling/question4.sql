-A datelist_int generation query. Convert the device_activity_datelist column into a datelist_int column

-- Step 1: Add the datelist_int column
ALTER TABLE user_devices_cumulated
ADD COLUMN datelist_int INTEGER[] NOT NULL DEFAULT '{}';

-- Step 2: Populate datelist_int using a combination of POW and bitwise operations
UPDATE user_devices_cumulated
SET datelist_int = ARRAY(
    SELECT 
        CASE 
            -- Handle JSONB arrays
            WHEN jsonb_typeof(device_activity_datelist::jsonb) = 'array' THEN
                (SELECT ARRAY_AGG(
                    CAST(
                        (EXTRACT(YEAR FROM value::DATE)::INTEGER * POW(10, 4)::INTEGER) + -- YEAR * 10^4 (shift by 4 decimal places)
                        (EXTRACT(MONTH FROM value::DATE)::INTEGER * POW(10, 2)::INTEGER) + -- MONTH * 10^2 (shift by 2 decimal places)
                        EXTRACT(DAY FROM value::DATE)::INTEGER                           -- Add DAY (units place)
                    AS INTEGER)
                )
                FROM jsonb_array_elements_text(device_activity_datelist::jsonb))
            -- Handle standard ARRAYs
            ELSE
                ARRAY(
                    SELECT 
                        CAST(
                            (EXTRACT(YEAR FROM d)::INTEGER * POW(10, 4)::INTEGER) +  -- YEAR * 10^4
                            (EXTRACT(MONTH FROM d)::INTEGER * POW(10, 2)::INTEGER) + -- MONTH * 10^2
                            EXTRACT(DAY FROM d)::INTEGER                            -- DAY (units place)
                        AS INTEGER)
                    FROM unnest(device_activity_datelist) AS d
                )
        END
);