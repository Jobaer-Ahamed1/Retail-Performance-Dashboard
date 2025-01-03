-- sales data 
-- 1.most sales item(top 5)
-- 2.most sales item per month 
-- 3.total customer 
-- 4.how much purchased by each customer
-- 5.how much purchased by each country 
-- 6.most sales item by each country 
-- 7.most sales item by each country per month 
-- 8.total sold amount by item 
-- 9.total sold amount by item per month 
-- 10.total sold amount/revenue 
-- 11.total sold amount by each country and which item most sold  
-- 12 Monthly Sales  

SELECT Description,count(*) FROM year_2009_2010
group by Description 
order by count(*) desc 

truncate year_2009_2010 

select count(*) from year_2009_2010 y 

select count(*) from year_2010_2011 y 

select Description  from year_2009_2010 y 

-- 1.most sales item(top 5) 

select distinct Description ,count(Quantity) as total from year_2009_2010 y 
group by Description 
order by total desc
limit 5

-- 2.most sales item per month (top 10)

select Description,DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,count(Quantity) as total from year_2009_2010 y 
group by Description ,month 
order by total desc 
limit 10


select Description,DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,sum(Quantity * Price) as total from year_2009_2010 y 
group by Description ,month 
order by total desc 

-- 3.total customer  
select count(distinct `Customer ID`) as total_customer from year_2009_2010 y  

-- 4.how much purchased by each customer 

select `Customer ID`,round(sum(Quantity * Price),0) as total_purchase from year_2009_2010 y 
group by `Customer ID`
order by total_purchase

-- 5.how much purchased by each country 

select Country, round(sum(Quantity * Price),0) as total_purchase from year_2009_2010 y
group by Country 
order by total_purchase

-- 6.most sales item by each country  

select Country,Description,count(Quantity) as total  from year_2009_2010 y 
group by Country ,Description  
order by total 

-- 7.most sales item by each country per month 

select Country,DATE_FORMAT(InvoiceDate, '%Y-%m') AS month, count(Quantity) as total from year_2009_2010 y 
group by Country ,month
order by total  

-- 8.total top sold amount by item  
select Description,round(sum(Quantity * Price),0) as total_purchase from year_2009_2010 y 
group by Description 
order by total_purchase desc 

-- 9.total sold amount by item per month  
select date_format(InvoiceDate, '%Y-%m') as month ,round(sum(Quantity * Price),0) as total_purchase from year_2009_2010 y 
group by month 
order by month 

-- 10.total sold amount/revenue 
select round(sum(Quantity * Price),0) as total_sold from year_2009_2010 y 

-- 11.total sold amount by each country and which item most sold 

select Country,Description,round(sum(Quantity * Price),0) as total_sold from year_2009_2010 y
group by Country ,Description 
order by total_sold desc 

-- 12 Monthly Sales  

-- Extract year and month and calculate total monthly sales
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
     round(SUM(Quantity * Price),0) AS TotalSales,
    COUNT(DISTINCT Invoice) AS TotalTransactions,
    COUNT(DISTINCT `Customer ID`) AS TotalCustomers
FROM 
    year_2009_2010 y 
GROUP BY 
    YearMonth
ORDER BY 
    YearMonth; 
   
select DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
    SUM(Quantity * Price) AS TotalSales from year_2009_2010 y 
    group by YearMonth 
    
-- 13 Average Order Value (AOV) per month . Calculate average revenue per order to assess customer purchasing behavior.
    -- Purpose: The Average Order Value shows how much, on average, a customer spends per order during a specific month.
 
 SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
    round( SUM(Quantity * Price) / COUNT(DISTINCT Invoice),0) AS AverageOrderValue
FROM 
    year_2009_2010 y 
GROUP BY 
    YearMonth
ORDER BY 
    YearMonth; 
   
-- 14.Monthly Sales Growth Rate 
   -- Purpose: Calculates the percentage growth or decline in sales from the previous month to the current month. 
   
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
        year_2009_2010 y 
    GROUP BY 
        YearMonth
    order by YearMonth 
) AS MonthlySales; 


-- 15. Customer Churn Rate  

WITH ActiveCustomers AS (
    SELECT 
        `Customer ID`, 
        MAX(InvoiceDate) AS last_order_date
    FROM 
        year_2009_2010 y 
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



-- 16. customer segmentation (RFM analysis)
-- Recency: Number of days since the last purchase.
-- Frequency: Count of distinct invoices (unique purchases).
-- Monetary: Total amount spent by the customer. 

-- Create RFM Scores
WITH rfm AS (
    SELECT 
          `Customer ID`,
        DATEDIFF('2024-01-01', MAX(InvoiceDate)) AS Recency,
        COUNT(DISTINCT Invoice) AS Frequency,
        SUM(Quantity * Price) AS Monetary
    FROM 
        year_2009_2010 y
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
   
-- Total orders 
   
select count(Invoice) as total_Orders from year_2009_2010 y  

-- Top 5 product by country 

select Country,Description,round( sum(Quantity* Price),0) as total_amount from year_2009_2010 y 
group by Country ,Description 
order by total_amount desc
limit 5


-- top 5 customers 

select `Customer ID`,round(sum(Quantity * Price),0) as total_purchase from year_2009_2010 y 
group by `Customer ID` 
order by total_purchase desc 
limit 5 

-- TOP 5 country where they purchase 

select Country,round(sum(Quantity*price),0) as total_purchase  from year_2009_2010 y 
group by Country 
order by total_purchase desc 
limit 5  


-- top 5 item by revenue 

select Description as product ,round(sum(Quantity* Price),0) as total_revenue from  year_2009_2010 y 
group by product 
order  by total_revenue desc 
limit 5

-- customer lifetime value (CLV)

WITH AverageValues AS (
    SELECT 
        `Customer ID`, 
        AVG(Price * Quantity) AS AveragePurchaseValue,      -- Average amount spent per purchase
        COUNT(DISTINCT Invoice) AS TotalPurchases          -- Total number of purchases per customer
    FROM year_2009_2010
    group by `Customer ID`
),
CustomerLifespan AS (
    SELECT 
         `Customer ID`, 
        DATEDIFF(MAX(InvoiceDate), MIN(InvoiceDate)) / 30 AS CustomerLifespanInYears  -- Convert days to years
    FROM year_2009_2010 
    group by    `Customer ID`
   
)
SELECT 
    AVG(AVG(AveragePurchaseValue) * AVG(TotalPurchases) * AVG(CustomerLifespanInYears)) AS CustomerLifetimeValue
FROM AverageValues AS AV
JOIN CustomerLifespan AS CL 
    ON AV.`Customer ID` = CL.`Customer ID`; 
   WITH CustomerMetrics AS (
    -- Calculate revenue, orders, and first/last purchase dates per customer
    SELECT 
        `Customer ID`,
        COUNT(Invoice) AS total_orders,
        SUM(Price * Quantity) AS total_revenue,
        MIN(InvoiceDate) AS first_order_date,
        MAX(InvoiceDate) AS last_order_date
    FROM 
        year_2009_2010 
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

   
-- average purchase frequency 
   
   SELECT
    COUNT(DISTINCT Invoice) * 1.0 / COUNT(DISTINCT `Customer ID`) AS average_purchase_frequency
FROM
    year_2009_2010 y  
    
-- low performing product 
    
 select count(*) as lowperforming_products from (SELECT 
    distinct Description AS product, 
    ROUND(SUM(Quantity * Price), 0) AS totalSales
FROM 
    year_2009_2010 y
GROUP BY 
    product
HAVING 
    ROUND(SUM(Quantity * Price), 0) < 50) as t 
    

    SELECT 
    distinct Description AS product, 
    ROUND(SUM(Quantity * Price), 0) AS totalSales
FROM 
    year_2009_2010 y
GROUP BY 
    product
HAVING 
    ROUND(SUM(Quantity * Price), 0) < 50

    
-- how much 
    
    SELECT 
    COUNT(DISTINCT Description) AS ProductCount
FROM 
    year_2009_2010

HAVING 
    SUM(Quantity * Price) < 500;


   
select count(distinct Description)  from year_2009_2010 y 

-- Total order by each region 

select Country,count(Invoice) as orders from year_2009_2010 y 
group by Country 

-- CUSTOmer count by region 

select Country,count(distinct `Customer ID`) as customer from year_2009_2010 y 
group by Country 

select count( `Customer ID`) as customer from year_2009_2010 y 

-- average order value by region 

SELECT 
    Country , 
    SUM(Quantity * Price) AS TotalRevenue, 
    COUNT(DISTINCT Invoice) AS TotalOrders, 
    ROUND(SUM(Quantity * Price) / COUNT(DISTINCT Invoice), 2) AS AverageOrderValue
FROM 
    year_2009_2010
GROUP BY 
    Country 
ORDER BY 
    AverageOrderValue DESC; 
   
   
-- monthly growth rate by region 
   
   WITH MonthlyRevenue AS (
    SELECT 
        country,
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month, 
        SUM(Quantity * Price) AS TotalRevenue
    FROM 
        year_2009_2010
    GROUP BY 
        country, 
        DATE_FORMAT(InvoiceDate, '%Y-%m')
), 
GrowthRate AS (
    SELECT 
        country,
        Month,
        TotalRevenue,
        LAG(TotalRevenue) OVER (PARTITION BY country ORDER BY Month) AS PreviousMonthRevenue,
        ROUND(
            (TotalRevenue - LAG(TotalRevenue) OVER (PARTITION BY country ORDER BY Month)) 
            / LAG(TotalRevenue) OVER (PARTITION BY country ORDER BY Month) * 100, 
            2
        ) AS MoM_GrowthRate
    FROM 
        MonthlyRevenue
)
SELECT 
    country,
    Month,
    TotalRevenue,
    MoM_GrowthRate
FROM 
    GrowthRate
ORDER BY 
    country, Month;

   -- product popularoty by region 
   
   SELECT 
    Country , 
    Description AS Product,
    SUM(Quantity) AS TotalUnitsSold,
    SUM(Quantity * Price) AS TotalRevenue
FROM 
    year_2009_2010
GROUP BY 
    Country , 
    Description
ORDER BY 
    TotalRevenue DESC;

   -- profit mergin by region 
   
  SELECT 
    Country,
    ROUND(SUM(Quantity * Price), 2) AS TotalRevenue,
    ROUND(SUM(Quantity * Price) * 0.7, 2) AS TotalCost, -- Replace 0.7 with actual cost percentage if known
    ROUND((SUM(Quantity * Price) - SUM(Quantity * Price) * 0.7) / SUM(Quantity * Price) * 100, 2) AS ProfitMargin
FROM 
    year_2009_2010 y
GROUP BY 
    Country
ORDER BY 
    ProfitMargin DESC;

  -- revenue contribution percentege 
   SELECT 
    Country ,
    ROUND(SUM(Quantity * Price), 2) AS RevenueByRegion,
    ROUND(
        (SUM(Quantity * Price) / (SELECT SUM(Quantity * Price) FROM year_2009_2010)) * 100, 2
    ) AS RevenueContributionPercentage
FROM 
    year_2009_2010
GROUP BY 
    Country 
ORDER BY 
    RevenueContributionPercentage DESC;











