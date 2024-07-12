
---CREATING THE DATABASE
CREATE DATABASE Railway

USE Railway

----CREATING THE TABLE NAME RAILWAY_DATA
CREATE TABLE railway_data (
    Transaction_ID VARCHAR(25),
    Date_of_Purchase DATETIME,
    Time_of_Purchase DATETIME,
	Purchase_Type CHAR,
	Payment_Method CHAR,
	Railcard CHAR,
	Ticket_Class CHAR,
	Ticket_Type CHAR,
	Price INT,
	Departure_Station CHAR,
	Arrival_Destination CHAR,
	Date_of_Journey DATETIME,
	Departure_Time DATETIME,
	Arrival_Time DATETIME,
	Actual_Arrival_Time DATETIME,
	Journey_Status CHAR,
	Reason_for_Delay CHAR,
	Refund_Request CHAR
);

----IMPORTING THE RAILWAY_ DATA AS DBO.RAILWAY INTO THE TABLE NAME RALWAY
BULK INSERT railway
FROM 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\railway.csv'
WITH (
    FIELDTERMINATOR = ',', -- Specify the field terminator (e.g., ',' for CSV)
    ROWTERMINATOR = '\n' -- Specify the row terminator (e.g., '\n' for CSV)
);

select * from railway

------------------------------------------------------------------

----CORRECTING THE DATE_OF_PURCHASE FORMAT 

ALTER TABLE railway -- Create a new column to store the converted date temporarily
ADD Date_of_Purchase_Converted DATE;

UPDATE railway   -- Update the new column with the converted dates
SET Date_of_Purchase_Converted = 
    CASE
        WHEN Date_of_Purchase LIKE '%/%/%' THEN 
            TRY_CONVERT(DATE, Date_of_Purchase, 103) -- 103 is the style for 'dd/mm/yyyy'
        WHEN Date_of_Purchase LIKE '%-%-%' THEN 
            TRY_CONVERT(DATE, Date_of_Purchase, 105) -- 105 is the style for 'dd-mm-yyyy'
        ELSE NULL
    END;

-- Checking the dates which are failing to convert
SELECT * FROM railway 
WHERE Date_of_Purchase_Converted IS NULL 
AND Date_of_Purchase IS NOT NULL;

UPDATE Railway -- replace the original column with the new one
SET Date_of_Purchase = CONVERT(VARCHAR, Date_of_Purchase_Converted, 23); -- 23 is the style for 'yyyy-mm-dd'
; -- 23 is the style for 'yyyy-mm-dd'

-- Drop the temporary column
ALTER TABLE railway 
DROP COLUMN Date_of_Purchase_Converted;

-----------------------------------------------------------------------------------------------------------------------

------CORRECTING AND CLEANING THE DATE_OF_JOURNEY FORMAT 

ALTER TABLE railway
ADD Time_of_Purchase_Converted TIME;

UPDATE railway
SET Time_of_Purchase_Converted =              
    CASE
        WHEN Time_of_Purchase LIKE '%:%:%' THEN 
            TRY_CONVERT(TIME, Time_of_Purchase, 8) -- 8 is the style for 'HH:MM:SS'
        ELSE NULL
    END;

----CORRECTING THE TIME_OF_PURCHASE FORMAT 
SELECT * FROM railway 
WHERE Time_of_Purchase_Converted IS NULL
AND Time_of_Purchase IS NOT NULL -- Checking the dates which are failing to convert

UPDATE railwayrt
SET Time_of_Purchase = CONVERT(VARCHAR, Time_of_Purchase_Conveed, 8) -- 8 is the style for 'HH:MM:SS'

ALTER TABLE railway
DROP COLUMN Time_of_Purchase_Converted;

------------------------------------------------------------------------------

---Q1-> Identify Peak Purchase Times and Their Impact on Delays ---

-- Step 1: Find peak purchase times
WITH Purchase_Counts AS (
    SELECT 
        DATEPART(HOUR, CAST(Time_of_Purchase AS DATETIME)) AS Purchase_Hour,     
        COUNT(*) AS Purchase_Count
    FROM 
        railway
    GROUP BY 
        DATEPART(HOUR, CAST((Time_of_Purchase) AS DATETIME))
),
-- Step 2: Calculate average delay for each purchase hour
Delay_Analysis AS (
    SELECT
        DATEPART(HOUR, CAST(Time_of_Purchase AS DATETIME)) AS Purchase_Hour,
        AVG(DATEDIFF(MINUTE, CAST(Departure_Time AS DATETIME), CAST(Actual_Arrival_Time AS DATETIME))) AS Average_Delay_Minutes
    FROM 
        railway
    WHERE 
        Journey_Status = 'Delayed'       
    GROUP BY 
        DATEPART(HOUR, CAST(Time_of_Purchase AS DATETIME))
)
-- Step 3: Combine results
SELECT
    PC.Purchase_Hour,                      
    PC.Purchase_Count,
    DA.Average_Delay_Minutes
FROM
    Purchase_Counts PC
LEFT JOIN
    Delay_Analysis DA ON PC.Purchase_Hour = DA.Purchase_Hour
ORDER BY
    DA.Average_Delay_Minutes DESC;

-//*This query calculates the average delay in minutes between departure and 
actual arrival times for each hour of the day when tickets were purchased. 
It aims to identify peak times for ticket purchases and analyze if there's any correlation with journey delays.*///

------------------------------------------------------------------------------------

----QUESTION-2 Analyze Journey Patterns of Frequent Travelers:
/*NO DATA AVAILABLE*/

------------------------------------------------------------------------------------

----QUESTION-3 Revenue Loss Due to Delays with Refund Requests

SELECT Price
FROM railway
WHERE PRICE LIKE '31&^'

DELETE FROM railway
WHERE Price = '31&^'

DELETE FROM railway
WHERE Price = '3--'

DELETE FROM railway
WHERE Price = '4£' 

DELETE FROM railway
WHERE Price = '3$'

DELETE FROM railway
WHERE Price = '16A'

ALTER TABLE Railway
ALTER COLUMN PRICE INT

SELECT Journey_Status, SUM(PRICE) AS 'TOTAL_PRICE' ,Refund_Request
FROM railway
WHERE Refund_Request = 'Yes'  
AND Journey_Status = 'Delayed' 
GROUP BY Journey_Status , Refund_Request
ORDER BY TOTAL_PRICE

/*Total_Revenue_Loss: This value represents the total amount of money lost due to refunds issued for delayed journeys. 
A higher value indicates significant financial impact due to train delays and refund requests*/

----------------------------------------------------------------------------

----QUESTION 4 Impact of Railcards on Ticket Prices and Journey Delays:

-- Calculate the average ticket price and delay rate for journeys with and without railcards

-- Average ticket prices
SELECT
    CASE
        WHEN Railcard IS NOT NULL AND Railcard != 'None' THEN 'With Railcard'
        ELSE 'Without Railcard'
    END AS Railcard_Status,
    AVG(CAST(Price AS FLOAT)) AS Average_Price,                                             
	  AVG(CASE
            WHEN Journey_Status != 'On Time' THEN 1
            ELSE 0
        END) AS Delay_Rate
FROM railway
GROUP BY
    CASE
        WHEN Railcard IS NOT NULL AND Railcard != 'None' THEN 'With Railcard'
        ELSE 'Without Railcard'
    END;

 /*Average_Price: This value shows the average ticket price for journeys with and without railcards.
 It highlights how much passengers save on average by using railcards.
 Delay_Rate:It indicates whether there is any noticeable 
 difference in the punctuality of journeys between these two groups.*/

-------------------------------------------------------------------------------------

--QUESTION NO. 5- Journey Performance by Departure and Arrival Stations

/*checking wheather there is any values in string*/

SELECT * FROM railway 
WHERE ISDATE(Actual_Arrival_Time) = 0; 

SELECT Arrival_Time FROM railway 
WHERE ISDATE(Arrival_Time) = 0; 

/*Converting the string value into the null*/ 

SELECT Actual_Arrival_Time FROM railway
WHERE TRY_CONVERT(DATETIME, Actual_Arrival_Time) IS NULL; 

UPDATE railway 
SET Actual_Arrival_Time = NULL 
WHERE TRY_CONVERT(DATETIME, Actual_Arrival_Time) IS NULL; 

SELECT Arrival_Time FROM railway 
WHERE TRY_CONVERT(DATETIME, Arrival_Time) IS NULL;

UPDATE railway 
SET Arrival_Time = NULL 
WHERE TRY_CONVERT(DATETIME, Arrival_Time) IS NULL; 

/*Cnverting the Datatype*/ 

ALTER TABLE railway 
ALTER COLUMN Actual_Arrival_Time DATETIME; 

ALTER TABLE railway 
ALTER COLUMN Arrival_Time DATETIME 

SELECT Departure_Station, Arrival_Destination,
AVG(DATEDIFF(MINUTE, CAST(Actual_Arrival_Time AS DATETIME), CAST(Arrival_Time AS DATETIME))) AS Average_Delay_Minutes
FROM railway 
GROUP BY Departure_Station, Arrival_Destination
ORDER BY Average_Delay_Minutes DESC;

select * from railway

/*Departure_Station and Arrival_Destination: These columns identify each unique pair of
departure and arrival stations being analyzed.
Average_Delay_Time:This value represents the average delay time, in minutes, for journeys between 
each pair of departure and arrival stations. It helps to identify which routes have the most significant delays,
guiding operational improvements.*/
------------------------------------------------------------------------------

--QUESTION 6 Revenue and Delay Analysis by Railcard and Station

SELECT
    Departure_Station, Arrival_Destination,
    CASE
        WHEN Railcard IS NOT NULL AND Railcard != 'None' THEN 'With Railcard'
        ELSE 'Without Railcard'
    END AS Railcard_Status,
    SUM(CAST(Price AS FLOAT)) AS Total_Revenue,
    AVG(
        CASE
            WHEN Journey_Status != 'On Time' THEN 1
            ELSE 0
        END
    ) AS Delay_Rate
FROM railway
GROUP BY
    Departure_Station,Arrival_Destination,
    CASE
        WHEN Railcard IS NOT NULL AND Railcard != 'None' THEN 'With Railcard'
        ELSE 'Without Railcard'
    END;

/*Total_Revenue: This value shows the total revenue generated from journeys 
with and without railcards at each station, highlighting the financial contribution 
of different types of tickets.

Delay_Rate: This value represents the average delay rate for journeys with and without railcards at each station,
providing insights into the punctuality of trains and identifying potential problem areas*/
-----------------------------------------------------------------------------


--QUESTION 7. Journey Delay Impact Analysis by Hour of Day


ALTER TABLE railway
ADD delay_time DATETIME;

ALTER TABLE RAILWAY
DROP COLUMN DELAY_TIME

UPDATE railway
SET delay_time = DATEDIFF(MINUTE, CAST(Actual_Arrival_Time AS DATETIME), CAST(Arrival_Time AS DATETIME)) 



SELECT 
    DATEPART(HOUR, Departure_Time) AS hour_of_day,
	AVG(CAST(DELAY_TIME AS FLOAT)) AS AVERAGE_DELAY_MINUTES
    
FROM 
    railway
WHERE 
    DELAY_TIME > 0
GROUP BY 
    DATEPART(HOUR, Departure_Time)
ORDER BY 
    AVERAGE_DELAY_MINUTES DESC;
-------------------------------------------------------------
update railway
set Date_of_Journey = REPLACE(Date_of_Journey,'*')
where Date_of_Journey

select * from railway

/*hour_of_day: This column represents each hour of the day (0 to 23) 
during which journeys depart.

Average_Delay: This value shows the average delay time, in minutes, 
for journeys departing during each hour. 
It helps identify peak hours when delays are most significant, which can inform scheduling and operational adjustments.*/
