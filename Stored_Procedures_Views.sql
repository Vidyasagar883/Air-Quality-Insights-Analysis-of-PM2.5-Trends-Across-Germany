
DELIMITER $$

CREATE PROCEDURE state_most_stations()
BEGIN
	SELECT State, Highest_No_of_stations
	FROM (
	SELECT s.name AS State,
	COUNT(DISTINCT st.station_id) AS Highest_No_of_stations,
	RANK() OVER(ORDER BY COUNT(DISTINCT st.station_id) DESC) AS t_rank
	FROM states s JOIN stations st ON s.state_id=st.state_id
	GROUP BY s.name
	) ranked
	WHERE t_rank=1;
END $$

DELIMITER ;

CALL state_most_stations();

DELIMITER $$

CREATE PROCEDURE worst_polution_station_setting()
BEGIN

	SELECT st.station_setting AS station_setting,
	MAX(a.annual_mean_value_ug_m³) as Highest_value
	FROM stations st JOIN air_quality_measurements a
	ON st.station_id=a.station_id
	GROUP BY 1
	HAVING station_setting IS NOT NULL
	ORDER BY 2 DESC;

END$$
DELIMITER ;

CALL worst_polution_station_setting();

-- Stored Procedure: Get Station Details by Code

DELIMITER $$
CREATE PROCEDURE GetStationDetails(IN p_station_code VARCHAR(20))
BEGIN
   SELECT * 
   FROM stations WHERE station_code=p_station_code;
END$$
DELIMITER ;

CALL GetStationDetails('DEBB110');

-- Top N Polluted Stations in a Given Year

DELIMITER $$
CREATE PROCEDURE Top_N_poll_stations(IN p_year INT, IN p_TopN INT)
BEGIN
	SELECT st.station_name, a.annual_mean_value_ug_m³
    FROM stations st JOIN air_quality_measurements a
    ON st.station_id=a.station_id
    WHERE a.year=p_year
	ORDER BY a.annual_mean_value_ug_m³ DESC
    LIMIT p_TopN;
END$$
DELIMITER ;

CALL Top_N_poll_stations(2023, 6);

-- Stations Exceeding WHO Guidelines
DELIMITER $$
CREATE PROCEDURE Stations_Exceed_WHO_Guidelines(IN p_Guideline_Value FLOAT, IN p_Year INT)
BEGIN
	SELECT st.station_name,s.name
	FROM stations st 
	JOIN states s 
	ON st.state_id=s.state_id
	JOIN air_quality_measurements a
	ON st.station_id=a.station_id
	WHERE a.annual_mean_value_ug_m³ > p_Guideline_Value
	AND a.year = p_Year;
END$$
DELIMITER ;

CALL Stations_Exceed_WHO_Guidelines(5.0,2022);

-- Highest PM2.5 Station Per State
DELIMITER $$
CREATE PROCEDURE Highest_PM2_Value_State_Year(IN p_Year INT)
BEGIN
	SELECT s.name,MAX(a.annual_mean_value_ug_m³) Highest_Value
	FROM states s 
    JOIN stations st
	ON st.state_id=s.state_id
	JOIN air_quality_measurements a
	ON st.station_id=a.station_id
    WHERE a.year = p_Year
	GROUP BY 1
    ORDER BY 2;

END$$
DELIMITER ;

CALL Highest_PM2_Value_State_Year(2024);

-- Repeated WHO Exceeding Stations
DELIMITER //
CREATE PROCEDURE RepeatedExceedingStations(IN p_startYear INT, IN p_endYear INT, IN p_limitValue FLOAT)
BEGIN
    SELECT st.station_name,
           COUNT(DISTINCT a.year) AS years_exceeded
    FROM stations st
    JOIN air_quality_measurements a ON st.station_id = a.station_id
    WHERE a.year BETWEEN p_startYear AND p_endYear
      AND a.annual_mean_value_ug_m³ > p_limitValue
    GROUP BY st.station_name;
END //
DELIMITER ;

CALL RepeatedExceedingStations(2021, 2024,4);

  -- VIEWS
  -- Station details with measurements
  
CREATE VIEW Station_Measurements AS
SELECT m.measurement_id, m.year, m.pollutant_code, m.annual_mean_value_ug_m³,
       st.station_code, st.station_name, s.name AS state_name
FROM air_quality_measurements m
JOIN stations st ON m.station_id = st.station_id
JOIN states s ON st.state_id = s.state_id;

SELECT * FROM Station_Measurements WHERE station_code = 'DEHH064';

-- Air quality in Hamburg

CREATE VIEW Hamburg_AirQuality AS
SELECT s.name AS state_name, st.station_name, a.year, a.pollutant_code, 
       a.annual_mean_value_ug_m³
FROM states s 
JOIN stations st ON s.state_id = st.state_id
JOIN air_quality_measurements a ON st.station_id = a.station_id
WHERE s.name = 'Hamburg';

SELECT * FROM Hamburg_AirQuality WHERE pollutant_code = 'PM2.5' ORDER BY year;

-- Average PM2.5 per state per year

CREATE VIEW State_Avg_PM25 AS
SELECT s.name AS state_name, a.year,
       AVG(a.annual_mean_value_ug_m³) AS avg_PM25
FROM air_quality_measurements a
JOIN stations st ON a.station_id = st.station_id
JOIN states s ON st.state_id = s.state_id
WHERE a.pollutant_code = 'PM2.5'
GROUP BY s.name, a.year;

SELECT * FROM State_Avg_PM25 WHERE year = 2024 ORDER BY avg_PM25 DESC;

-- Stations exceeding WHO guideline

CREATE VIEW Exceed_WHO_PM25 AS
SELECT st.station_name, s.name AS state_name, a.year, a.annual_mean_value_ug_m³
FROM air_quality_measurements a
JOIN stations st ON a.station_id = st.station_id
JOIN states s ON st.state_id = s.state_id
WHERE a.pollutant_code = 'PM2.5' 
  AND a.annual_mean_value_ug_m³ > 5;


SELECT * FROM Exceed_WHO_PM25 WHERE year = 2024;

-- Most polluted station per state in latest year

CREATE VIEW Top_Polluted_Stations AS
SELECT state_name, station_name, year, annual_mean_value_ug_m³
FROM (
    SELECT s.name AS state_name, st.station_name, a.year, a.annual_mean_value_ug_m³,
           RANK() OVER(PARTITION BY s.name ORDER BY a.annual_mean_value_ug_m³ DESC) AS rnk
    FROM air_quality_measurements a
    JOIN stations st ON a.station_id = st.station_id
    JOIN states s ON st.state_id = s.state_id
    WHERE a.year = (SELECT MAX(year) FROM air_quality_measurements)
      AND a.pollutant_code = 'PM2.5'
) ranked
WHERE rnk = 1;

SELECT * FROM Top_Polluted_Stations;

