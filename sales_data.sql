/*
 Data Exploration in SQL Queries and Visualization in Tableau_Sales Data
*/


--Inspecting Data
Select *
From PortfolioProject..sales_data



--Checking unique value

Select distinct status 
From PortfolioProject..sales_data

Select distinct year_id 
From PortfolioProject..sales_data

Select distinct productline 
From PortfolioProject..sales_data

Select distinct country 
From PortfolioProject..sales_data

Select distinct territory 
From PortfolioProject..sales_data

Select distinct dealsize 
From PortfolioProject..sales_data

-- Analysis
-- * 1.	What is the status of the total orders

Select status,count(ordernumber) as OrderStatus
From PortfolioProject..sales_data
group by status 
order by OrderStatus

/*  Orders needed to be take care by (regional )account manager
  Spain, Austrlia, Denmark*/
Select Country, count(status)
From PortfolioProject..sales_data
where status='Disputed'
group by Country 
order by count(status) desc



-- * 2.	The most popular product lines
-- Classic Cars, plot this
Select productline, sum(cast (sales as float))  as revenue
From PortfolioProject..sales_data
group by productline 
order by revenue desc

-- *3.what was the best month for sales in a specific year? How much was earned that month?
--  November is the great month in 2003,2004. the data in 2005 only last until May
Select MONTH_id, sum(cast (sales as float))  as revenue, count(ordernumber)as frequency
From PortfolioProject..sales_data
where year_id = 2004 
group by MONTH_id, year_id
order by revenue desc

--  Which prduct line sells the best in NOV ? will it be classic car?
--  yes in both 2003 and 2004
Select productline, sum(cast (sales as float))  as revenue
From PortfolioProject..sales_data
Where MONTH_id = 11 and year_id = 2004
group by productline
order by revenue desc


-- *4 Who is our best customer (this could be best answered with RFM)

alter table PortfolioProject..sales_data -- change the type of ORDERDATE from varchar to datetime  
alter column ORDERDATE datetime 

alter table PortfolioProject..sales_data -- change the type of ORDERDATE from varchar to float  
alter column SALES FLOAT; --remove the "cast"function below

DROP TABLE IF EXISTS #rfm

with CTE_RFM AS
(
Select customername,
       sum(sales) as MonetaryValue,
	   avg(sales) as AvgMonetaryValue,
       COUNT(ORDERNUMBER) as Frequency,
	   max(orderdate) as LastOrderDate,	  
	   (select max(orderdate) From PortfolioProject..sales_data ) as Max_order_date,
	   DATEDIFF(DD,max(orderdate),(select max(orderdate) From PortfolioProject..sales_data )) Recency
From PortfolioProject..sales_data
group by customername 
),
CTE_RFM_Cal AS --second cte from rfm calculation
(
Select r.*,
ntile(4) over(order by Frequency) AS RFM_Frequency,
ntile(4) over(order by Recency desc) AS RFM_Recency,
ntile(4) over(order by MonetaryValue ) AS RFM_MonetaryValue
from CTE_RFM r
)

Select rc.*, RFM_Recency+RFM_Frequency+RFM_MonetaryValue as RFM_Cell,
cast(RFM_Recency as varchar)+cast(RFM_Frequency as varchar)+cast(RFM_MonetaryValue as varchar) as RFM_Cell_String
into #rfm -- after creating the cte, creating the table to avoid calling cte every time
From CTE_RFM_Cal rc

-- take differentiate actions 
Select CUSTOMERNAME, RFM_Recency,RFM_Frequency,RFM_MonetaryValue,RFM_Cell_String,
	CASE
		WHEN RFM_Cell_String in(111,112,121,122,123,132,141,144,211,212,221) THEN 'LostCustomer' -- lost customer
		WHEN RFM_Cell_String in(133,134,143,232,244,334,343,344) THEN 'slipping,win back' -- big spenders who haven't purchased yet
		WHEN RFM_Cell_String in(311,331,411,412,421,423) THEN 'NewCustomer'
		WHEN RFM_Cell_String in(222,223,233,234,322)THEN 'PotentialChurners'
		WHEN RFM_Cell_String in(323,333,321,422,332,432)THEN 'Active'  -- buy recently,but low price
		WHEN RFM_Cell_String in(433,434,443,444) THEN 'Royal'
	end rfm_segemnet 
From #rfm



