/*DATA PREPARATION AND UNDERSTANDING*/
Create Database SQL_BASIC
USE SQL_BASIC

SELECT * FROM Customer
SELECT * FROM Transactions
SELECT * FROM prod_cat_info

--=====================================================================================================================================================================


--1.	What is the total number of rows in each of the 3 tables in the database?
SELECT 'Customer Table' [Table], COUNT(*) as [CustomerRows] FROM Customer
UNION ALL
SELECT 'Transactions Table', COUNT(*) as [TransactionsRows] FROM transactions
UNION ALL
SELECT 'Product Table', COUNT(*) as [ProdRows] FROM prod_cat_info

--=====================================================================================================================================================================


--2.	What is the total number of transactions that have a return?
SELECT COUNT(transaction_id) [Total Transactions] FROM Transactions 
WHERE total_amt < 0

--=====================================================================================================================================================================


--3.	As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls convert the date variables into valid date formats before proceeding ahead.
/* THE TRAN_DATE IS IMPORTED AS 'DATE' DATA TYPE*/
SELECT * FROM Transactions

--For DML
SELECT convert(date,tran_date,105) [tran_date] FROM transactions

--=====================================================================================================================================================================


--4.	What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.
SELECT DATEDIFF(dd,MIN(tran_date),MAX(tran_date)) [Transaction Day], 
DATEDIFF(mm,MIN(tran_date),MAX(tran_date)) [Transaction Month],
DATEDIFF(yy,MIN(tran_date),MAX(tran_date)) [Transaction Year] 
FROM Transactions

--=====================================================================================================================================================================


--5.	Which product category does the sub-category “DIY” belong to?
SELECT Prod_Cat [Product Category] FROM prod_cat_info 
WHERE prod_subcat = 'DIY'

--=====================================================================================================================================================================


/* DATA ANALYSIS */

--1.	Which channel is most frequently used for transactions?
SELECT top 1 store_type [Channel], COUNT(transaction_id) [Number of Transactions] FROM transactions 
GROUP BY store_type ORDER BY [Number of Transactions] desc


--=====================================================================================================================================================================


--2.	What is the COUNT of Male and Female customers in the database?
SELECT Gender, COUNT(customer_Id) [COUNT of M/F] FROM Customer t2
GROUP BY Gender

--=====================================================================================================================================================================


--3.	FROM which city do we have the maximum number of customers and how many?
SELECT TOP 1 COUNT(customer_Id) [Number of Customers], city_code FROM Customer
GROUP BY city_code ORDER BY [Number of Customers] desc

--=====================================================================================================================================================================


--4.	How many sub-categories are there under the Books category?
SELECT prod_cat, COUNT(prod_subcat) [Books Sub Category] FROM prod_cat_info 
WHERE prod_cat = 'Books' GROUP BY prod_cat

--=====================================================================================================================================================================


--5.	What is the maximum quantity of products ever ordered?
SELECT MAX(qty) [Maximum Quantity] FROM Transactions

--=====================================================================================================================================================================


--6.	What is the net total revenue generated in categories Electronics and Books?
SELECT t2.prod_cat, SUM(t1.total_amt) [Net Total Revenue] FROM Transactions t1 left join prod_cat_info t2 on t1.prod_cat_code = t2.prod_cat_code and t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE t2.prod_cat = 'Electronics' OR t2.prod_cat = 'Books' GROUP BY t2.prod_cat

 --or

SELECT t2.prod_cat, SUM(t1.total_amt) [Net Total Revenue] FROM Transactions t1 left join prod_cat_info t2 on t1.prod_cat_code = t2.prod_cat_code and t1.prod_subcat_code = t2.prod_sub_cat_code
WHERE t2.prod_cat IN ('Electronics','Books') GROUP BY t2.prod_cat


--=====================================================================================================================================================================


--7.	How many customers have >10 transactions with us, excluding returns?
SELECT  t2.customer_Id, COUNT(t1.transaction_id) [Number of Transactions] FROM Transactions t1 left join Customer t2 on t1.cust_id = t2.customer_Id 
WHERE t1.total_amt > 0 GROUP BY t2.customer_Id 
HAVING  COUNT(t1.transaction_id) > 10 ORDER BY [Number of Transactions]

--=====================================================================================================================================================================


--8.	What is the combined revenue earned FROM the “Electronics” & “Clothing” categories, FROM “Flagship stores”?
SELECT t2.store_type, t1.prod_cat, SUM(t2.total_amt) [Combined Revenue] FROM prod_cat_info t1 LEFT JOIN Transactions t2 on t1.prod_cat_code = t2.prod_cat_code AND t1.prod_sub_cat_code = t2.prod_subcat_code
WHERE t2.store_type = 'Flagship Store' AND  t1.prod_cat = 'Electronics' OR t2.store_type = 'Flagship Store' AND  t1.prod_cat = 'Clothing'   
GROUP BY  t2.store_type , t1.prod_cat


--=====================================================================================================================================================================

--9.	What is the total revenue generated FROM “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.
SELECT t1.prod_subcat, SUM(t2.total_amt) [Total Revenue] FROM prod_cat_info t1 LEFT JOIN (SELECT t1.*, t2.Gender FROM Transactions t1 LEFT JOIN Customer t2 ON t1.cust_id = t2.customer_Id WHERE t2.Gender = 'M') t2
ON t1.prod_cat_code = t2.prod_cat_code AND t1.prod_sub_cat_code = t2.prod_subcat_code WHERE t1.prod_cat = 'Electronics' GROUP BY t1.prod_subcat


--=====================================================================================================================================================================

--10.	What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
SELECT TOP 5 t2.prod_subcat, SUM(total_amt)/ (SELECT SUM(total_amt) FROM Transactions) * 100 [Percent Sales], SUM(TOTAL_AMT)/(SELECT SUM(total_amt) FROM Transactions WHERE total_amt<0) * 100 [Percent Return]
FROM Transactions t1 LEFT JOIN prod_cat_info t2 ON t1.prod_cat_code = t2.prod_cat_code AND t1.prod_subcat_code = t2.prod_sub_cat_code GROUP BY t2.prod_subcat
ORDER BY [Percent Sales] DESC

--=====================================================================================================================================================================

--11.	For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?
SELECT DATEDIFF(YEAR, DOB,GETDATE()) [Age], SUM(t1.total_amt)  [Net Total Revenue]
FROM (SELECT t1.*, MAX(t1.tran_date) OVER () as max_tran_date FROM Transactions t1) t1 
LEFT JOIN Customer t2 ON t1.cust_id = t2.customer_Id
WHERE DATEDIFF(YEAR, DOB,GETDATE()) BETWEEN 25 AND 35 AND t1.tran_date >= DATEADD(day,-30, t1.max_tran_date)
GROUP BY DATEDIFF(YEAR, DOB,GETDATE())

--More Accurate
select DATEDIFF(YEAR,DOB,CURRENT_TIMESTAMP) [Age], sum(t.total_amt)[Total Revenue] from  Transactions t left join  Customer c on t.cust_id = c.customer_Id 
where DATEDIFF(YEAR,DOB,CURRENT_TIMESTAMP) between 25 and 35 and t.tran_date = DATEADD(DAY,-30,(select max(tran_date) from Transactions))
group by DATEDIFF(YEAR,DOB,CURRENT_TIMESTAMP)

--=====================================================================================================================================================================

--12. Which product category has seen the max value of returns in the last 3 months of transactions?
SELECT TOP 1 t2.prod_cat, SUM(Total_amt) [Total Returns] FROM Transactions t1 LEFT JOIN prod_cat_info t2 
ON t1.prod_cat_code = t2.prod_cat_code AND t1.prod_subcat_code = t2.prod_sub_cat_code WHERE Tran_date >= DATEADD(mm, -3, tran_date) AND Total_amt < 0
GROUP BY t2.prod_cat ORDER BY [Total Returns] ASC


--=====================================================================================================================================================================

--13.	Which store-type sells the maximum products; by value of sales amount and by quantity sold?
SELECT TOP 1 Store_type, SUM(total_amt) [Sales Amount], Count(Qty) [Quantity Sold] FROM Transactions 
GROUP BY Store_type ORDER BY [Sales Amount] DESC, [Quantity Sold] DESC


--=====================================================================================================================================================================

--14.	What are the categories for which average revenue is above the overall average.
SELECT t1.prod_cat, AVG(t2.total_amt) [Average Revenue] FROM prod_cat_info t1 left join Transactions t2 ON t1.prod_cat_code = t2.prod_cat_code
GROUP BY t1.prod_cat HAVING AVG(t2.total_amt) > (SELECT AVG(total_amt) FROM Transactions)


--=====================================================================================================================================================================

--15.	Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
SELECT t1.prod_subcat, AVG(t2.total_amt) [Average Revenue], SUM(t2.total_amt) [Total Revenue] FROM prod_cat_info t1 left join Transactions t2 ON t1.prod_cat_code = t2.prod_cat_code
WHERE t1.prod_cat IN (SELECT top 5 t1.prod_cat FROM  prod_cat_info t1 INNER JOIN Transactions t2 ON t1.prod_cat_code = t2.prod_cat_code GROUP BY prod_cat
ORDER BY SUM(t2.Qty))
GROUP BY t1.prod_subcat


--=====================================================================================================================================================================


