--A DDL for hosts_cumulated table
--a host_activity_datelist which logs to see which dates each host is experiencing any activity

CREATE TABLE hosts_cumulated (
    host TEXT ,                  
    host_activity_datelist DATE[] , 
    PRIMARY KEY (host)                  
);