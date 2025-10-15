# Air-Quality-Insights-Analysis-of-PM2.5-Trends-Across-Germany
MySQL database and Power BI reporting project for analyzing PM2.5 air quality trends across German states and stations.


##  Dashboard Previe

## Project Overview
This project tracks and analyzes PM2.5 air-quality levels across Germany from 2021 to 2024.
It integrates data engineering (MySQL schema design, data cleaning, transformations) and data visualization (Power BI dashboards) to uncover pollution trends, compliance issues, and performance insights.
## Project Workflow

### 1. Data Collection & Preparation
- Downloaded official datasets from [UBA](https://www.umweltbundesamt.de/en/topics/air/measuringobservingmonitoring/air-monitoring-networks).  
- Cleaned CSV files for states, stations, and PM2.5 readings.  
- Imported data into temporary MySQL tables for transformation.

### 2. Database Design
Snowflake-style schema:  
- `states` – German states  
- `stations` – Monitoring stations metadata  
- `air_quality_measurements` – Annual PM2.5 readings  
- Temporary tables: `temp_stations`, `raw_air_quality`

### 3. Data Cleaning & Transformation
- Fixed UTF-8 encoding issues (e.g., “LÃ¼beck” → “Lübeck”).  
- Created **views** for yearly averages, compliance summaries, and rankings.  
- Built **stored procedures** for automated yearly reports.

### 4. Analysis (SQL)
- Rank polluted and cleanest stations.  
- Detect stations exceeding WHO (5 µg/m³) and EU (25 µg/m³) guidelines.  
- Multi-year trend analysis and network coverage by state.

### 5. Power BI Visualization
- Heatmaps for WHO/EU compliance.  
- Year-over-Year trend lines.  
- Top/Bottom 5 performing states and stations.  
- KPI cards for compliance.  
- Dynamic slicers for year, state, and station type.

---

##  Key Features

**Data-Driven Compliance & Benchmarking**  
Interactive Power BI dashboard using DAX and conditional formatting to benchmark PM2.5 levels across states.

**Scalable Data Modeling**  
Snowflake-based schema ensures data integrity, efficient relationships, and scalable reporting.

**Actionable Insights**  
YoY trend visuals, rankings, and stored procedures reveal performance shifts and compliance patterns.
## Tech Stack
- MySQL
- SQL (DDL, DML, JOINs, GROUP BY, HAVING, Window functions)
- Data analysis
- Power BI Reports

## Database Schema
- `states` – List of German states
- `stations` – Monitoring stations and their details
- `air_quality_measurements` – Annual pollutant measurements
- `temp_stations` – Temporary table for importing station data
- `raw_air_quality` – Temporary table for raw measurement data

## Sample Data
The repository includes sample CSV files to replicate the database setup , data is taken from official german air quality measurements website https://www.umweltbundesamt.de/en/topics/air/measuringobservingmonitoring/air-monitoring-networks.
- `stations.csv`
- `Annual-tabulation_Particulate matter_PM2.5.csv`
- `States.csv`

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

**Fixing Mis-encoded Station Names in MySQL**
 Problem: Some station names in the stations table were mis-encoded, showing LÃ¼beck-St. JÃ¼rgen instead of Lübeck-St. Jürgen
Approach:

  - 1.Added a temporary column to store corrected values.
  - 2.Used CONVERT and CAST to re-interpret the mis-encoded text as UTF-8.
  - 3.erified the fixed values before updating the original column.
  - 4.Replaced the original column with the corrected data and removed the temporary column.

```sql
ALTER TABLE stations ADD COLUMN temp_name VARCHAR(255) DEFAULT NULL;

UPDATE stations
SET temp_name = CONVERT(CAST(CONVERT(station_name USING latin1) AS BINARY) USING utf8mb4)
WHERE station_name LIKE '%Ã%';

SELECT station_name, temp_name FROM stations WHERE temp_name IS NOT NULL;

UPDATE stations SET station_name = temp_name WHERE temp_name IS NOT NULL;

ALTER TABLE stations DROP COLUMN temp_name;
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
**Q10.In the most recent year, show all states with the highest recorded PM2.5?**
```sql
SELECT 
    s.name AS state_name,
    MAX(a.annual_mean_value_ug_m³) AS highest_average_PM25,
    (SELECT MAX(year) FROM air_quality_measurements) AS Most_recent_year
FROM states s
JOIN stations st ON s.state_id = st.state_id
JOIN air_quality_measurements a ON st.station_id = a.station_id
WHERE a.year = (SELECT MAX(year) FROM air_quality_measurements)
GROUP BY s.name
ORDER BY highest_average_PM25 DESC
LIMIT 1;
```
 **Q11 Which are the top 5 most polluted PM2.5 stations in the latest year?**
```sql
SELECT 
    st.station_name AS station_name,
    MAX(a.annual_mean_value_ug_m³) AS highest_average_PM25,
    (SELECT MAX(year) FROM air_quality_measurements) AS Most_recent_year
FROM stations st
JOIN air_quality_measurements a ON st.station_id = a.station_id
WHERE a.year = (SELECT MAX(year) FROM air_quality_measurements)
GROUP BY st.station_name
ORDER BY highest_average_PM25 DESC
LIMIT 5;
```
**Q12 Which are the top 5 cleanest PM2.5 stations in the latest year?**
```sql
SELECT st.station_name AS TOP_Clean_Stations
FROM Stations st
JOIN air_quality_measurements a ON st.station_id=a.station_id
WHERE a.year=(SELECT MAX(year) FROM air_quality_measurements)
ORDER BY a.annual_mean_value_ug_m³ ASC
LIMIT 5;
```
**Q13 Which station type tend to exceed WHO guideline levels(5) more often?**
```sql
SELECT st.station_type ,
SUM(CASE WHEN a.annual_mean_value_ug_m³>5 THEN 1 ELSE 0 END) AS Exceed_count,
COUNT(*) AS Total_Count ,
ROUND(100*(SUM(CASE WHEN a.annual_mean_value_ug_m³>5 THEN 1 ELSE 0 END))/COUNT(*),2) AS Exceed_Percent
FROM stations st 
JOIN air_quality_measurements a ON st.station_id=a.station_id
GROUP BY 1;
```	
**Q14.How many stations exceeded the WHO annual PM2.5 guideline value (5 µg/m³) in the last year(2024)?**
```sql
SELECT COUNT(DISTINCT st.station_id) AS Total_Stations
FROM stations st 
JOIN air_quality_measurements a
ON st.station_id=a.station_id
WHERE a.annual_mean_value_ug_m³>5
AND a.year=2024;
```
**Q15.How many exceeded the EU limit (25 µg/m³) in the last year?**
```sql
SELECT COUNT(DISTINCT st.station_id) AS Total_Stations
FROM stations st 
JOIN air_quality_measurements a
ON st.station_id=a.station_id
WHERE a.annual_mean_value_ug_m³>25
AND a.year=2024;
```
**Q16 Which stations repeatedly exceed PM2.5 guidelines year after year?**
```sql
SELECT st.station_name
FROM stations st JOIN air_quality_measurements a ON
st.station_id=a.station_id
WHERE a.year IN(2021,2022,2023,2024) 
AND a.annual_mean_value_ug_m³>25
GROUP BY 1
HAVING COUNT(DISTINCT a.year)=4;

```

## 📊 Power BI Dashboard Highlights
- **Heatmaps**: Regional compliance against WHO and EU PM2.5 limits.  
- **Year-over-Year Trends**: Track PM2.5 levels across years.  
- **Rankings**: Top and bottom performing stations and states.  
- **KPI Cards**: Quick view of WHO/EU guideline exceedances.  
- **Interactive Slicers**: Filter by year, state, or station type.

---

## ⚙️ Tech Stack
- **Database:** MySQL  
- **Visualization:** Power BI  
- **Languages:** SQL, DAX  
- **Techniques:** Views, stored procedures, data cleaning, transformation, analytical querying, interactive dashboards

---

## 📂 Data Source
Official German Environment Agency (UBA):  
[https://www.umweltbundesamt.de/en/topics/air/measuringobservingmonitoring/air-monitoring-networks]

Sample CSVs included for replication:  
- `stations.csv`  
- `Annual-tabulation_Particulate matter_PM2.5.csv`  
- `states.csv`

---

## 📈 Results & Insights
- PM2.5 levels vary sharply between industrial and rural regions.  
- Multiple urban stations exceed WHO’s 5 µg/m³ guideline.  
- EU compliance is stable; WHO compliance is still low in dense regions.  
- Power BI dashboards make non-compliance instantly visible.

---

## ✅ Summary
End-to-end project showcasing:  
- Database design & normalization  
- Data cleaning & transformation  
- Views & stored procedures  
- SQL analysis & reporting  
- Dynamic Power BI dashboards for decision-making


## Data Source
Official German environmental data from the [German Environment Agency (UBA)](https://www.umweltbundesamt.de/en).

## Author Vidyasagar Panugothu
## LinkedIn; https://www.linkedin.com/in/vidyasagar-panugothu/

