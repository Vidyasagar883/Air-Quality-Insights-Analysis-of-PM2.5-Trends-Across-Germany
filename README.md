# Air-Quality-Insights-Analysis-of-PM2.5-Trends-Across-Germany
MySQL database project analyzing PM2.5 air quality trends across German states and stations.
# Germany Air Quality Analysis

**PostgreSQL database project analyzing PM2.5 air quality trends across German states and stations.**

## Description
This project involves building a MySQL database to manage and analyze air quality data across German states and monitoring stations. It focuses on PM2.5 measurements, tracking trends, identifying high-pollution areas, and generating insights at both station and state levels. The project demonstrates database design, SQL querying, and data analysis skills applied to real-world environmental data from the German Environment Agency (UBA).

## Objectives
- Build a structured database for German air quality data.
- Analyze PM2.5 trends to identify high-pollution areas.
- Track stations with increasing or decreasing PM2.5 levels.
- Identify states with the highest PM2.5 concentrations.
- Generate insights and reports for environmental monitoring.

## Tech Stack
- MySQL
- SQL (DDL, DML, JOINs, GROUP BY, HAVING, Window functions)
- Data analysis

## Database Schema
- `states` – List of German states
- `stations` – Monitoring stations and their details
- `air_quality_measurements` – Annual pollutant measurements
- `temp_stations` – Temporary table for importing station data
- `raw_air_quality` – Temporary table for raw measurement data

## Sample Data
The repository includes sample CSV files to replicate the database setup:
- `stations.csv`
- `Annual-tabulation_Particulate matter_PM2.5.csv`

## Queries and Analysis
The project includes SQL scripts to extract meaningful insights:
CREATE DATABASE Germany_Air_Quality;
USE Germany_Air_Quality;

**DATABASE Creation**
```sql
CREATE TABLE states(
state_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(40) NOT NULL
);

CREATE TABLE Stations (
station_id INT PRIMARY KEY AUTO_INCREMENT,
station_code VARCHAR(20) UNIQUE NOT NULL,
station_name VARCHAR(50) NOT NULL,
state_id INT NOT NULL,
station_setting VARCHAR(50),
station_type VARCHAR(50),
FOREIGN KEY (state_id) REFERENCES States(state_id)
);


CREATE TABLE air_quality_measurements (
    measurement_id INT AUTO_INCREMENT PRIMARY KEY,
    station_id INT NOT NULL,                     
    year YEAR NOT NULL,
    pollutant_code VARCHAR(20) NOT NULL,        
    annual_mean_value_ug_m³   FLOAT,
    FOREIGN KEY (station_id) REFERENCES Stations(station_id)
);


-- Temp table with stations data

CREATE TABLE  temp_stations (
state_name VARCHAR(50),
station_name VARCHAR(50),
station_code VARCHAR(20) UNIQUE,
Station_setting VARCHAR(30),
Station_type VARCHAR(40)
);
-- Temporary table with raw data
CREATE TABLE raw_air_quality (
    station_code VARCHAR(20),
    year YEAR,
    pollutant_code VARCHAR(20),
    annual_mean_value_ug_m³   FLOAT
);
```
**Inserting Data into the Tables**
```sql
INSERT INTO states (name) VALUES
('Baden-Württemberg'),
('Bavaria'),
('Berlin'),
('Brandenburg'),
('Bremen'),
('Hamburg'),
('Hesse'),
('Lower Saxony'),
('Mecklenburg-West Pomerania'),
('North Rhine-Westphalia'),
('Rhineland-Palatinate'),
('Saarland'),
('Saxony'),
('Saxony-Anhalt'),
('Schleswig-Holstein'),
('Thuringia'),
('UBA');


INSERT  INTO stations
    (station_code, station_name, state_id, station_setting, station_type)
SELECT t.station_code,
       t.station_name,
       s.state_id,
       t.station_setting,
       t.station_type
FROM temp_stations t
JOIN states s ON s.name = t.state_name;


INSERT INTO air_quality_measurements 
(station_id, year, pollutant_code, annual_mean_value_ug_m³)
SELECT 
s.station_id, r.year, r.pollutant_code, r.annual_mean_value_ug_m³
FROM 
raw_air_quality r
JOIN 
Stations s ON r.station_code = s.station_code;
```
 **RETRIEVING THE DATA** 	
 **Q1.Show the details of the station with code DEHH064.**
```sql
SELECT * FROM stations WHERE station_code='DEHH064';
```

**Q2.Get the air quality measurements for station DEHH064,along with its station details**.
```sql
SELECT * FROM air_quality_measurements m LEFT JOIN stations s 
ON m.station_id=s.station_id WHERE station_code='DEHH064';
```
**Q3.Get only the measurement values for station DEHH064 (no station details).**
```sql
SELECT m.*
FROM air_quality_measurements m
LEFT JOIN stations s
ON m.station_id = s.station_id
WHERE s.station_code = 'DEHH064';
```
**Q4.Show the air quality measurements for all stations in Hamburg, sorted by year.**
```sql
SELECT m.*,st.name FROM air_quality_measurements m 
LEFT JOIN stations s ON m.station_id = s.station_id
LEFT JOIN states st ON st.state_id=s.state_id
WHERE st.name='Hamburg' ORDER BY m.year;
```

**Q5. find top 5 states that have the most stations monitoring PM2.5?**
```sql
SELECT s.name , COUNT(DISTINCT st.station_code) AS No_Of_stations
FROM 
states s JOIN stations st ON s.state_id=st.state_id
GROUP BY 1 
ORDER BY 2 DESC LIMIT 5;

         OR

SELECT State, Highest_No_of_stations
FROM (
SELECT s.name AS State,
COUNT(DISTINCT st.station_id) AS Highest_No_of_stations,
RANK() OVER(ORDER BY COUNT(DISTINCT st.station_id) DESC) AS t_rank
FROM states s JOIN stations st ON s.state_id=st.state_id
GROUP BY s.name
) ranked
WHERE t_rank=1;
```
**Q6. Are there any states without any PM2.5 monitoring stations?**
```sql
SELECT s.name ,COUNT(DISTINCT st.station_code) AS No_Of_stations
FROM states s 
JOIN stations st ON s.state_id=st.state_id
GROUP BY 1
HAVING COUNT(DISTINCT st.station_code)  IS NULL;
```

**Q7. Which station in each state has the highest average PM2.5 concentration in 2023?**
```sql
SELECT s.name,
st.station_name,
MAX(a.annual_mean_value_ug_m³) AS Highest_station_avg_value,
a.year
FROM states s JOIN stations st ON
s.state_id=st.station_id
JOIN air_quality_measurements a ON
st.station_id=a.station_id
GROUP BY 1,2,4
HAVING a.year=2023
ORDER BY 3 ;
```

**Q8. Which type of monitoring setting experiences the worst PM2.5 pollution levels?**
```sql
SELECT st.station_setting AS station_setting,
MAX(a.annual_mean_value_ug_m³) as Highest_value
FROM stations st JOIN air_quality_measurements a
ON st.station_id=a.station_id
GROUP BY 1
HAVING station_setting IS NOT NULL
ORDER BY 2 DESC;
```

 **Hamburg Details**
```sql
SELECT s.name,
st.station_name,
a.annual_mean_value_ug_m³,
a.year
FROM states s JOIN stations st ON
s.state_id=st.station_id
JOIN air_quality_measurements a ON
st.station_id=a.station_id
WHERE s.name='Hamburg'  AND a.pollutant_code = 'PM2.5'
ORDER BY st.station_name ,a.year ;

SELECT station_id, station_code, station_name, state_id
FROM stations
WHERE state_id = (SELECT state_id FROM states WHERE name = 'Hamburg');

SELECT s1.name, st.station_name, a.annual_mean_value_ug_m³,a.year
FROM states s1 JOIN stations st ON s1.state_id=st.state_id JOIN
air_quality_measurements a  ON a.station_id=st.station_id
WHERE s1.state_id =(select s.state_id FROM states s WHERE s.name='Hamburg');
```



## How to Use
1. Set up a MySQL database.
2. Run `schema.sql` to create tables and relationships.
3. Import sample CSV files into respective tables.
4. Run `queries.sql` to explore PM2.5 trends and insights.

## Data Source
Official German environmental data from the [German Environment Agency (UBA)](https://www.umweltbundesamt.de/en).

## Author Vidyasagar Panugothu

