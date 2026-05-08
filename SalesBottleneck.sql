-- ============================================================
-- SalesBottleneck.sql
-- Project: Unlocking Revenue – Identifying Bottlenecks in
--          Regional Sales Pipeline
-- Dataset: RegionalSales2025.csv
-- Author:  Business Analyst Report
-- Date:    2025
-- ============================================================

-- TABLE SETUP (if importing into SQL Server / MySQL)
-- CREATE TABLE RegionalSales2025 (
--     OrderID     VARCHAR(10),
--     Date        DATE,
--     CustomerID  VARCHAR(10),
--     Region      VARCHAR(10),
--     ProductName VARCHAR(50),
--     Category    VARCHAR(20),
--     Quantity    INT,
--     UnitPrice   DECIMAL(10,2),
--     TotalAmount DECIMAL(12,2),
--     OrderStatus VARCHAR(15),
--     SalesAgent  VARCHAR(50)
-- );

-- ============================================================
-- QUERY 1: Monthly Trend of Sales Across All Regions
-- ============================================================
SELECT
    SUBSTR(Date, 1, 7)              AS Month,
    COUNT(*)                        AS TotalOrders,
    SUM(
        CASE WHEN OrderStatus = 'Completed'
             THEN TotalAmount ELSE 0 END
    )                               AS CompletedRevenue,
    SUM(TotalAmount)                AS GrossSales
FROM RegionalSales2025
GROUP BY SUBSTR(Date, 1, 7)
ORDER BY Month;

/*
RESULT SUMMARY (2025):
  - Peak revenue months: November (5,889,624), July (5,811,807), May (5,781,807)
  - Lowest revenue months: April (3,262,158), August (3,777,747)
  - Seasonal dip visible in Q2 (April) — needs investigation
*/

-- ============================================================
-- QUERY 2: Percentage of Cancelled and Returned Orders per Region
-- ============================================================
SELECT
    Region,
    COUNT(*)                                                        AS TotalOrders,
    SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END)     AS Cancellations,
    SUM(CASE WHEN OrderStatus = 'Returned'  THEN 1 ELSE 0 END)     AS Returns,
    ROUND(
        100.0 * SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )                                                               AS CancelPct,
    ROUND(
        100.0 * SUM(CASE WHEN OrderStatus = 'Returned'  THEN 1 ELSE 0 END)
        / COUNT(*), 2
    )                                                               AS ReturnPct
FROM RegionalSales2025
GROUP BY Region
ORDER BY CancelPct DESC;

/*
RESULT SUMMARY:
  Region | Cancel% | Return%
  South  | 24.26%  | 14.99%  ← WORST PERFORMER
  West   | 23.06%  | 10.61%
  East   | 17.97%  |  8.98%
  North  | 13.44%  |  7.94%  ← BEST PERFORMER
  → South region is the biggest bottleneck
*/

-- ============================================================
-- QUERY 3: Top 3 Regions/Products with Most Revenue Loss
--          (Cancelled + Returned Orders)
-- ============================================================
SELECT
    Region,
    ProductName,
    COUNT(*)              AS LostOrders,
    SUM(TotalAmount)      AS RevenueLost
FROM RegionalSales2025
WHERE OrderStatus IN ('Cancelled', 'Returned')
GROUP BY Region, ProductName
ORDER BY RevenueLost DESC
LIMIT 10;

/*
RESULT SUMMARY (Top 3):
  1. East   – Laptop      → ₹22,70,475 lost
  2. West   – Laptop      → ₹14,55,432 lost
  3. East   – Smartphone  → ₹13,02,085 lost
  → Electronics (Laptop, Smartphone) drive the most revenue loss
*/

-- ============================================================
-- QUERY 4: Average Order Value by Product Category
-- ============================================================
SELECT
    Category,
    COUNT(*)                            AS TotalOrders,
    ROUND(AVG(TotalAmount), 2)          AS AvgOrderValue,
    SUM(TotalAmount)                    AS TotalSales
FROM RegionalSales2025
GROUP BY Category
ORDER BY AvgOrderValue DESC;

/*
RESULT SUMMARY:
  Electronics → Avg ₹1,20,050  (highest ticket)
  Furniture   → Avg ₹54,327
  Sports      → Avg ₹11,205
  Clothing    → Avg ₹10,508
  Food        → Avg ₹3,060    (lowest ticket)
*/

-- ============================================================
-- QUERY 5: Top 5 Performing Sales Agents (by Completed Revenue)
-- ============================================================
SELECT
    SalesAgent,
    Region,
    COUNT(CASE WHEN OrderStatus = 'Completed' THEN 1 END)       AS CompletedOrders,
    SUM(
        CASE WHEN OrderStatus = 'Completed'
             THEN TotalAmount ELSE 0 END
    )                                                           AS CompletedRevenue,
    ROUND(
        100.0 * COUNT(CASE WHEN OrderStatus = 'Completed' THEN 1 END)
        / COUNT(*), 1
    )                                                           AS SuccessRate
FROM RegionalSales2025
GROUP BY SalesAgent, Region
ORDER BY CompletedRevenue DESC
LIMIT 5;

/*
RESULT SUMMARY:
  1. Neha Gupta   (North) → ₹77,11,354  | 155 orders
  2. Divya Menon  (South) → ₹62,91,225  | 110 orders
  3. Ankit Joshi  (East)  → ₹60,49,525  | 131 orders
  4. Rahul Mehta  (East)  → ₹54,28,394  | 131 orders
  5. Vijay Kumar  (North) → ₹52,79,791  | 116 orders
*/

-- ============================================================
-- QUERY 6: Category-wise Total Sales & Contribution to Grand Total
-- ============================================================
SELECT
    Category,
    SUM(
        CASE WHEN OrderStatus = 'Completed'
             THEN TotalAmount ELSE 0 END
    )                                   AS CategoryRevenue,
    ROUND(
        100.0 *
        SUM(CASE WHEN OrderStatus = 'Completed' THEN TotalAmount ELSE 0 END)
        / (
            SELECT SUM(TotalAmount)
            FROM RegionalSales2025
            WHERE OrderStatus = 'Completed'
        ),
        2
    )                                   AS ContributionPct
FROM RegionalSales2025
GROUP BY Category
ORDER BY CategoryRevenue DESC;

/*
RESULT SUMMARY:
  Electronics → ₹3,64,31,525  (63.45% of total revenue)
  Furniture   → ₹1,41,56,084  (24.66%)
  Sports      → ₹29,84,168    ( 5.20%)
  Clothing    → ₹29,46,858    ( 5.13%)
  Food        → ₹8,96,884     ( 1.56%)
  → Electronics dominates; Food needs strategic push
*/

-- ============================================================
-- QUERY 7: Customers with Highest Return Frequency (≥ 3 times)
-- ============================================================
SELECT
    CustomerID,
    COUNT(*)            AS ReturnCount,
    SUM(TotalAmount)    AS TotalReturnedValue,
    GROUP_CONCAT(DISTINCT ProductName) AS ReturnedProducts
FROM RegionalSales2025
WHERE OrderStatus = 'Returned'
GROUP BY CustomerID
HAVING COUNT(*) >= 2
ORDER BY ReturnCount DESC;

/*
NOTE: No single customer returned ≥3 times (spread of 5000 customer IDs).
Customers with 2 returns are flagged as at-risk and listed above.
Recommendation: Implement post-purchase follow-up for Electronics buyers.
*/

-- ============================================================
-- KPI SUMMARY VIEW (for Dashboard Integration)
-- ============================================================
SELECT
    COUNT(CASE WHEN OrderStatus = 'Completed' THEN 1 END)     AS TotalCompletedSales,
    SUM(CASE WHEN OrderStatus = 'Completed'
             THEN TotalAmount ELSE 0 END)                      AS TotalRevenue,
    COUNT(CASE WHEN OrderStatus = 'Cancelled' THEN 1 END)     AS TotalCancellations,
    COUNT(CASE WHEN OrderStatus = 'Returned'  THEN 1 END)     AS TotalReturns,
    ROUND(AVG(TotalAmount), 2)                                 AS AvgOrderValue,
    (
        SELECT ProductName
        FROM RegionalSales2025
        WHERE OrderStatus = 'Returned'
        GROUP BY ProductName
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )                                                          AS MostReturnedProduct
FROM RegionalSales2025;

-- ============================================================
-- END OF SalesBottleneck.sql
-- ============================================================
