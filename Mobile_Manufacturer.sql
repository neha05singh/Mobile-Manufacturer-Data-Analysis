CREATE DATABASE SQL_ADVANCE

USE SQL_ADVANCE

SELECT * FROM DIM_MANUFACTURER
SELECT * FROM DIM_MODEL
SELECT * FROM DIM_CUSTOMER
SELECT * FROM DIM_LOCATION
SELECT * FROM DIM_DATE
SELECT * FROM FACT_TRANSACTIONS

--====================================================================================================================================================================



--1.	List all the states in which we have customers who have bought cellphones from 2005 till today.
SELECT Distinct l.[State] FROM DIM_LOCATION l LEFT JOIN FACT_TRANSACTIONS t on l.IDLocation = t.IDLocation
WHERE DATEPART(year,t.Date) BETWEEN '2005' and GETDATE()

--=====================================================================================================================================================================




--2.	What state in the US is buying more 'Samsung' cell phones?
SELECT top 1 t.[State], count(t.Quantity) [Number of Units Sold] FROM DIM_MODEL m LEFT JOIN (SELECT t.*, l.[State], l.Country 
FROM FACT_TRANSACTIONS t LEFT JOIN DIM_LOCATION l on t.IDLocation = l.IDLocation) t 
on m.IDModel = t.IDModel LEFT JOIN DIM_MANUFACTURER r on m.IDManufacturer = r.IDManufacturer
WHERE r.Manufacturer_Name = 'Samsung' and t.Country = 'US' 
GROUP BY t.[State] ORDER BY [Number of Units Sold] desc

--=====================================================================================================================================================================




--3.	Show the number of transactions for each model per zip code per state.
SELECT m.Model_Name, t.ZipCode, t.[State], COUNT(t.Quantity) [Number of Transaction] FROM DIM_MODEL m LEFT JOIN (SELECT l.ZipCode, l.[State], t.*
FROM FACT_TRANSACTIONS t LEFT JOIN DIM_LOCATION l on t.IDLocation = l.IDLocation) t 
on m.IDModel = t.IDModel GROUP BY m.Model_Name, t.ZipCode, t.[State]


--=====================================================================================================================================================================



--4.	Show the cheapest cellphone
SELECT *  FROM DIM_MODEL WHERE Unit_price = (SELECT min(Unit_price) FROM DIM_MODEL)

--=====================================================================================================================================================================




--5.	Find out the average price for each model in the top5 manufacturers in terms of sales quantity and ORDER BY average price.
SELECT t.IDModel, avg(t.TotalPrice) [Total Price] FROM FACT_TRANSACTIONS t LEFT JOIN DIM_MODEL m on t.IDModel = m.IDModel 
INNER JOIN DIM_MANUFACTURER r on m.IDManufacturer = r.IDManufacturer
WHERE r.Manufacturer_Name in (SELECT top 5 r.Manufacturer_Name FROM FACT_TRANSACTIONS t LEFT JOIN DIM_MODEL m on t.IDModel = m.IDModel 
INNER JOIN DIM_MANUFACTURER r on m.IDManufacturer = r.IDManufacturer
GROUP BY r.Manufacturer_Name ORDER BY SUM(t.Quantity)  desc)
GROUP BY t.IDModel ORDER BY [Total Price]

--=====================================================================================================================================================================



--6.	List the names of the customers and the average amount spent in 2009, WHERE the average is higher than 500
SELECT c.Customer_Name, d.[YEAR], AVG(t.TotalPrice) [Average Amount Spent] FROM DIM_CUSTOMER c LEFT JOIN FACT_TRANSACTIONS t on c.IDCustomer = t.IDCustomer 
INNER JOIN DIM_DATE d on t.[Date] = d.[DATE]
WHERE d.[YEAR] = '2009' GROUP BY c.Customer_Name, d.[YEAR]
HAVING AVG(t.TotalPrice) > 500


--=====================================================================================================================================================================



--7.	List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
SELECT top 5 IDModel, sum(quantity) [Quantity], DATEPART(YEAR,[Date]) [Year] FROM FACT_TRANSACTIONS
WHERE DATEPART(YEAR,[Date]) = '2008' 
GROUP BY IDModel, DATEPART(YEAR,[Date])
intersect
SELECT IDModel, sum(quantity) [Quantity], DATEPART(YEAR,[Date]) [Year] FROM FACT_TRANSACTIONS
WHERE DATEPART(YEAR,[Date]) = '2009' 
GROUP BY IDModel, DATEPART(YEAR,[Date])
intersect
SELECT  IDModel, sum(quantity) [Quantity], DATEPART(YEAR,[Date]) [Year] FROM FACT_TRANSACTIONS
WHERE DATEPART(YEAR,[Date]) = '2010' 
GROUP BY IDModel, DATEPART(YEAR,[Date]) ORDER BY [Quantity] desc


--=====================================================================================================================================================================



--8.	Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
SELECT r.Manufacturer_Name, DATEPART(year,[date]), SUM(t.TotalPrice) FROM DIM_MANUFACTURER r LEFT JOIN DIM_MODEL m on r.IDManufacturer = m.IDManufacturer INNER JOIN
FACT_TRANSACTIONS t on m.IDModel = t.IDModel
WHERE DATEPART(year,[date]) = '2009'
GROUP BY r.Manufacturer_Name, DATEPART(year,[date])
union
SELECT r.Manufacturer_Name, DATEPART(year,[date]), SUM(t.TotalPrice) FROM DIM_MANUFACTURER r LEFT JOIN DIM_MODEL m on r.IDManufacturer = m.IDManufacturer INNER JOIN
FACT_TRANSACTIONS t on m.IDModel = t.IDModel
WHERE DATEPART(year,[date]) = '2010'
GROUP BY r.Manufacturer_Name, DATEPART(year,[date]) ORDER BY SUM(t.TotalPrice) desc
offset 2 row fetch next 2 row only


--or

SELECT r.Manufacturer_Name, year([date])[Year], SUM(t.TotalPrice) [Total Sales] FROM DIM_MANUFACTURER r LEFT JOIN DIM_MODEL m on r.IDManufacturer = m.IDManufacturer INNER JOIN
FACT_TRANSACTIONS t on m.IDModel = t.IDModel
WHERE year([date]) between '2009' and '2010'
GROUP BY r.Manufacturer_Name, year([date]) order by [Total Sales] desc
offset 2 rows
fetch next 2 rows only

--=====================================================================================================================================================================



--9.	Show the manufacturers that sold cellphone in 2010 but didn’t in 2009.
SELECT Distinct r.Manufacturer_Name FROM DIM_MANUFACTURER r LEFT JOIN DIM_MODEL m on r.IDManufacturer = m.IDManufacturer
INNER JOIN FACT_TRANSACTIONS t on m.IDModel = t.IDModel WHERE DATEPART(YEAR, t.[Date]) = '2010'
except
SELECT Distinct r.Manufacturer_Name FROM DIM_MANUFACTURER r LEFT JOIN DIM_MODEL m on r.IDManufacturer = m.IDManufacturer
INNER JOIN FACT_TRANSACTIONS t on m.IDModel = t.IDModel WHERE DATEPART(YEAR, t.[Date]) = '2009'

--=====================================================================================================================================================================




--10.	Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
SELECT Top 100 t1.IDCustomer, t1.[YEAR] [Year], avg_Spend [Average Spend], avg_Qty [Average Quantity],
CASE WHEN Prev_Spend = 0 THEN NULL ELSE CONVERT(NUMERIC(8,0),((total_Spend-Prev_Spend)/Prev_Spend) * 100) END [% Change in Spend]
FROM ( SELECT c.IDCustomer, d.[YEAR], AVG(t.TotalPrice) avg_Spend, AVG(t.Quantity) avg_Qty,SUM(t.TotalPrice) [total_Spend]
       ,LAG(SUM(t.TotalPrice),1,0) OVER(PARTITION BY c.IDCustomer ORDER BY d.[YEAR]) [Prev_Spend]
		FROM DIM_CUSTOMER c LEFT JOIN FACT_TRANSACTIONS t on c.IDCustomer = t.IDCustomer 
		INNER JOIN DIM_DATE d on t.[Date] = d.[DATE]
		GROUP BY c.IDCustomer,d.[YEAR] ) t1
ORDER BY t1.[YEAR],t1.IDCustomer


--This is more appropriate

select top 100 Customer_Name, d.[Year], AVG(TotalPrice)[Avg Spend], AVG(Quantity)[Avg Qty],SUM(TotalPrice)[Total Spend],
LAG(SUM(t.TotalPrice),1,0) over(order by d.[Year])[Previous Spend] , 
(SUM(TotalPrice) - LAG(SUM(t.TotalPrice),1,0) over(order by d.[Year]))/(select sum(TotalPrice) from FACT_TRANSACTIONS)
from DIM_CUSTOMER c left join FACT_TRANSACTIONS t on c.IDCustomer = t.IDCustomer INNER JOIN DIM_DATE d on t.[Date] = d.[DATE]
group by Customer_Name, d.[Year]

--=====================================================================================================================================================================






