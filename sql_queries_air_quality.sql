CREATE DATABASE Germany_Air_Quality;
USE Germany_Air_Quality;

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


-- Temp table with states

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

-- INSERTING INTO STATIONS 
INSERT  INTO stations
    (station_code, station_name, state_id, station_setting, station_type)
SELECT t.station_code,
       t.station_name,
       s.state_id,
       t.station_setting,
       t.station_type
FROM temp_stations t
JOIN states s ON s.name = t.state_name;

--  INSERTING INTO air_quality_measurements

INSERT INTO air_quality_measurements 
(station_id, year, pollutant_code, annual_mean_value_ug_m³)
SELECT 
s.station_id, r.year, r.pollutant_code, r.annual_mean_value_ug_m³
FROM 
raw_air_quality r
JOIN 
Stations s ON r.station_code = s.station_code;

-- RETRIEVING THE DATA 	
-- Q1.Show the details of the station with code DEHH064.
SELECT * FROM stations WHERE station_code='DEHH064';

-- Q2.Get the air quality measurements for station DEHH064, along with its station details.
SELECT * FROM air_quality_measurements m LEFT JOIN stations s 
ON m.station_id=s.station_id WHERE station_code='DEHH064';

-- Q3.Get only the measurement values for station DEHH064 (no station details).

SELECT m.*
FROM air_quality_measurements m
LEFT JOIN stations s
ON m.station_id = s.station_id
WHERE s.station_code = 'DEHH064';

-- Q4.Show the air quality measurements for all stations in Hamburg, sorted by year.

SELECT m.*,st.name FROM air_quality_measurements m 
LEFT JOIN stations s ON m.station_id = s.station_id
LEFT JOIN states st ON st.state_id=s.state_id
WHERE st.name='Hamburg' ORDER BY m.year;


-- Q5. find top 5 states that have the most stations monitoring PM2.5?

SELECT s.name , COUNT(DISTINCT st.station_code) AS No_Of_stations
FROM 
states s JOIN stations st ON s.state_id=st.state_id
GROUP BY 1 
ORDER BY 2 DESC LIMIT 5;

-- Q6. Are there any states without any PM2.5 monitoring stations?
SELECT s.name ,COUNT(DISTINCT st.station_code) AS No_Of_stations
FROM states s 
JOIN stations st ON s.state_id=st.state_id
GROUP BY 1
HAVING COUNT(DISTINCT st.station_code)  IS NULL;

-- Q7. which state has the Highest Number of stations 

SELECT State, Highest_No_of_stations
FROM (
SELECT s.name AS State,
COUNT(DISTINCT st.station_id) AS Highest_No_of_stations,
RANK() OVER(ORDER BY COUNT(DISTINCT st.station_id) DESC) AS t_rank
FROM states s JOIN stations st ON s.state_id=st.state_id
GROUP BY s.name
) ranked
WHERE t_rank=1;

-- Q8. Which station in each state has the highest average PM2.5 concentration in 2023?

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


-- Q9. Which type of monitoring setting experiences the worst PM2.5 pollution levels?"?

SELECT st.station_setting AS station_setting,
MAX(a.annual_mean_value_ug_m³) as Highest_value
FROM stations st JOIN air_quality_measurements a
ON st.station_id=a.station_id
GROUP BY 1
HAVING station_setting IS NOT NULL
ORDER BY 2 DESC;


-- Hamburg Details

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

-- Which air-quality monitoring station(s) in Hamburg recorded the lowest annual mean particulate concentration, and in which year?”
SELECT state_name , air_quality, year,
station_name
FROM 
(SELECT s.name state_name,
a.annual_mean_value_ug_m³ air_quality,
a.year year,
st.station_name,
RANK() OVER(ORDER BY a.annual_mean_value_ug_m³ ASC) as low_rank
FROM states s JOIN stations st ON
s.state_id=st.state_id JOIN air_quality_measurements a
ON st.station_id=a.station_id
WHERE s.name='Hamburg'
ORDER BY 2
) min_val
WHERE low_rank=1;

-- Q10.In the most recent year, show all states with the highest recorded PM2.5?
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

-- Q11 Which are the top 5 most polluted PM2.5 stations in the latest year?

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

-- 	Q12 Which are the top 5 cleanest PM2.5 stations in the latest year?

SELECT st.station_name AS TOP_Clean_Stations
FROM Stations st
JOIN air_quality_measurements a ON st.station_id=a.station_id
WHERE a.year=(SELECT MAX(year) FROM air_quality_measurements)
ORDER BY a.annual_mean_value_ug_m³ ASC
LIMIT 5;

-- 	Q13 Which station type tend to exceed WHO guideline levels(5) more often?

SELECT st.station_type ,
SUM(CASE WHEN a.annual_mean_value_ug_m³>5 THEN 1 ELSE 0 END) AS Exceed_count,
COUNT(*) AS Total_Count ,
ROUND(100*(SUM(CASE WHEN a.annual_mean_value_ug_m³>5 THEN 1 ELSE 0 END))/COUNT(*),2) AS Exceed_Percent
FROM stations st 
JOIN air_quality_measurements a ON st.station_id=a.station_id
GROUP BY 1;
	
-- Q14.How many stations exceeded the WHO annual PM2.5 guideline value (5 µg/m³) in the last year(2024)?
SELECT COUNT(DISTINCT st.station_id) AS Total_Stations
FROM stations st 
JOIN air_quality_measurements a
ON st.station_id=a.station_id
WHERE a.annual_mean_value_ug_m³>5
AND a.year=2024;

-- Q15.How many exceeded the EU limit (25 µg/m³) in the last year?
SELECT COUNT(DISTINCT st.station_id) AS Total_Stations
FROM stations st 
JOIN air_quality_measurements a
ON st.station_id=a.station_id
WHERE a.annual_mean_value_ug_m³>25
AND a.year=2024;

-- 	Q16 Which stations repeatedly exceed PM2.5 guidelines year after year?

SELECT st.station_name
FROM stations st JOIN air_quality_measurements a ON
st.station_id=a.station_id
WHERE a.year IN(2021,2022,2023,2024) 
AND a.annual_mean_value_ug_m³>25
GROUP BY 1
HAVING COUNT(DISTINCT a.year)=4;

SELECT * FROM air_quality_measurements WHERE annual_mean_value_ug_m³ 
=(SELECT MAX(annual_mean_value_ug_m³) FROM air_quality_measurements);
 
INSERT INTO states VALUES
('VIENNA');
