--A DDL for an user_devices_cumulated table that has:
--a device_activity_datelist which tracks a users active days by browser_type
--data type here should look similar to MAP<STRING, ARRAY[DATE]>
--or you could have browser_type as a column with multiple rows for each user (either way works, just be consistent!)


-- Table to store user-device activity information, tracking active days per browser type
CREATE TABLE user_devices_cumulated (
    user_id NUMERIC ,                      -- Unique identifier for the user
    device_id NUMERIC ,                    -- Unique identifier for the device
    device_activity_datelist JSONB ,       -- Tracks active days by browser_type in a MAP-like format
    PRIMARY KEY (user_id, device_id)               -- Ensures one record per user-device pair
);