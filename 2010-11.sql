-- OVER VIEW PAGE 

-- total revenue 
select round(sum(Quantity*Price),2) as total_revenue from year_2010_2011 y 

-- total orders 
select count(Invoice) as total_orders from year_2010_2011 y 

-- total customers 
select count(distinct `Customer ID`) as total_customers from year_2010_2011 y 

-- best selling product by revenue 

select Description,round(sum(Quantity*price),0) as revenue from year_2010_2011 y
group by Description 
order by revenue desc 
limit 5


-- average order value per month 

 SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
    round( SUM(Quantity * Price) / COUNT(DISTINCT Invoice),0) AS AverageOrderValue
FROM 
   year_2010_2011 y 
GROUP BY 
    YearMonth
ORDER BY 
    YearMonth;

   -- top 5 cpountry by purchase amount 
   
   select Country,round( sum(Quantity * Price),0) as total_purchase from year_2010_2011 y 
   group by Country 
   order by total_purchase desc 
   limit 5
   
-- top 5 customer by purchase amount
   
   select `Customer ID`,round( sum(Quantity*price),0) as total_purchase from year_2010_2011 y
   group by `Customer ID` 
   order by total_purchase desc 
   limit 5
   
-- -- total sold amount per month 

select Description,DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,  round( sum(Quantity*price),0) as total_amount from year_2010_2011 y
group by Description,YearMonth
order by YearMonth 

-- --monthly growth rate 

SELECT 
    YearMonth,
    TotalSales,
    LAG(TotalSales, 1) OVER (ORDER BY YearMonth) AS PreviousMonthSales,
   ROUND(((TotalSales - LAG(TotalSales, 1) OVER (ORDER BY YearMonth)) / 
    LAG(TotalSales, 1) OVER (ORDER BY YearMonth)) * 100, 2) AS MonthlyGrowthRate
FROM (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
       round(SUM(Quantity * Price),2) AS TotalSales
    FROM 
        year_2010_2011 y
    GROUP BY 
        YearMonth
    order by YearMonth 
) AS MonthlySales; 


-- CUSTOMER INSIGHTS 

-- Total customers 

select count(distinct `Customer ID`) from year_2010_2011 y 

-- average purchase frequency 

   SELECT
    COUNT(DISTINCT Invoice) * 1.0 / COUNT(DISTINCT `Customer ID`) AS average_purchase_frequency
FROM
    year_2010_2011 y
    
-- customer lifetime value 
WITH CustomerMetrics AS (
    -- Calculate revenue, orders, and first/last purchase dates per customer
    SELECT 
        `Customer ID`,
        COUNT(Invoice) AS total_orders,
        SUM(Price * Quantity) AS total_revenue,
        MIN(InvoiceDate) AS first_order_date,
        MAX(InvoiceDate) AS last_order_date
    FROM 
         year_2010_2011 y
    GROUP BY 
        `Customer ID`
), 
AverageMetrics AS (
    -- Calculate average metrics for all customers
    SELECT
        AVG(total_revenue / total_orders) AS avg_purchase_value,  -- Average Purchase Value
        AVG(total_orders) AS purchase_frequency,                 -- Purchase Frequency
        AVG(DATEDIFF(last_order_date, first_order_date)) / 395 AS avg_lifespan -- Customer Lifespan in months
    FROM 
        CustomerMetrics
)
SELECT
    ROUND(avg_purchase_value * purchase_frequency * avg_lifespan, 2) AS CustomerLifetimeValue
FROM 
    AverageMetrics; 
    
 -- all customer purchases amount 
    
    select `Customer ID`,round(sum(Quantity * Price),0) as total_purchase from year_2010_2011 y 
    group by `Customer ID` 
    
-- --top 5 customer by revenue  
    
    select `Customer ID`,round( sum(Quantity*Price),0) as total_purchase from year_2010_2011 y
    group by `Customer ID` 
    order by total_purchase desc 
    limit 5
    
  -- customer churn rate
    
    WITH ActiveCustomers AS (
    SELECT 
        `Customer ID`, 
        MAX(InvoiceDate) AS last_order_date
    FROM 
        year_2010_2011 y
    GROUP BY 
        `Customer ID`
),
ChurnedCustomers AS (
    SELECT 
        `Customer ID`
    FROM 
        ActiveCustomers
    WHERE 
        last_order_date < DATE_SUB(CURDATE(), INTERVAL 395 DAY)
)
SELECT 
    COUNT(*) AS ChurnedCount,
    (SELECT COUNT(*) FROM ActiveCustomers) AS TotalCustomers,
    ROUND(
        (COUNT(*) / (SELECT COUNT(*) FROM ActiveCustomers)) * 100, 2
    ) AS ChurnRate
FROM 
    ChurnedCustomers;
   
--  --customer segment(RFM analysis) 
   
   WITH rfm AS (
    SELECT 
          `Customer ID`,
        DATEDIFF('2024-01-01', MAX(InvoiceDate)) AS Recency,
        COUNT(DISTINCT Invoice) AS Frequency,
        SUM(Quantity * Price) AS Monetary
    FROM 
        year_2010_2011 y
    WHERE 
          `Customer ID` IS NOT NULL
    GROUP BY 
          `Customer ID`
),
-- Scoring the RFM metrics using NTILE
rfm_scores AS (
    SELECT
        `Customer ID`,
        Recency,
        Frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM 
        rfm
)
SELECT 
    `Customer ID`,
    Recency,
    Frequency,
    Monetary,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
    CASE
        WHEN R_Score >= 4 AND F_Score >= 4 THEN 'Loyal Customers'
        WHEN R_Score = 5 THEN 'Recent Customers'
        WHEN F_Score = 5 THEN 'Frequent Customers'
        WHEN M_Score = 5 THEN 'Big Spenders'
        WHEN R_Score <= 2 THEN 'At Risk'
        ELSE 'Others'
    END AS Segment
FROM 
    rfm_scores
ORDER BY 
    RFM_Score DESC; 
   
   
-- Product Insight 
   
-- total low performing product
   
    select count(*) as lowperforming_products from (SELECT 
    distinct Description AS product, 
    ROUND(SUM(Quantity * Price), 0) AS totalSales
FROM 
     year_2010_2011 y
GROUP BY 
    product
HAVING 
    ROUND(SUM(Quantity * Price), 0) < 50) as t

    
SELECT 
    distinct Description AS product, 
    ROUND(SUM(Quantity * Price), 0) AS totalSales
FROM 
     year_2010_2011 y
GROUP BY 
    product
HAVING 
    ROUND(SUM(Quantity * Price), 0) < 50
    
    
-- best selling product by unit
    
select Description,count(Quantity) as prducts from year_2010_2011 y 
group by Description 
order by prducts desc 
limit 5


-- TOTAL sold amount by each product 

select Description,round(sum(Quantity*price),0) as total_purchase from year_2010_2011 y 
group by Description 

-- --sales amount over month by product 
select Description,DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,round(sum(Quantity*Price),0) as total_revenue from year_2010_2011 y 
group by Description,YearMonth 


-- REGIONAL INSIGHT 

-- total revenue by country

select Country,round(sum(Quantity*Price),0) as total_revenue  from year_2010_2011 y 
group by Country 

-- --total orders by country 

select Country,count(Invoice) as orders from year_2010_2011 y
group by Country 

-- --total customers by country 
select Country,count(distinct `Customer ID`) as customer from year_2010_2011 y
group by Country 

-- average order value by country 

SELECT 
    Country , 
    round(SUM(Quantity * Price),0) AS TotalRevenue, 
    COUNT(DISTINCT Invoice) AS TotalOrders, 
    ROUND(SUM(Quantity * Price) / COUNT(DISTINCT Invoice), 0) AS AverageOrderValue
FROM 
    year_2010_2011 y
GROUP BY 
    Country 
ORDER BY 
    AverageOrderValue DESC; 
   
-- --revenue contribution percentage 
      SELECT 
    Country ,
    ROUND(SUM(Quantity * Price), 2) AS RevenueByRegion,
    ROUND(
        (SUM(Quantity * Price) / (SELECT SUM(Quantity * Price) FROM year_2010_2011 y)) * 100, 2
    ) AS RevenueContributionPercentage
FROM 
  year_2010_2011 y
GROUP BY 
    Country 
ORDER BY 
    RevenueContributionPercentage DESC;
   
-- product popularity 
   
    SELECT 
    Country , 
    Description AS Product,
    SUM(Quantity) AS TotalUnitsSold,
    round(SUM(Quantity * Price),0) AS TotalRevenue
FROM 
   year_2010_2011 y
GROUP BY 
    Country , 
    Description
ORDER BY 
    TotalRevenue DESC;

   
   

   
   



    
    
