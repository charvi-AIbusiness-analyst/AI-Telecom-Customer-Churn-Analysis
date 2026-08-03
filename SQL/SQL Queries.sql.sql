/*
================================================================================
RETAIL SALES ANALYTICS - ADVANCED SQL INTERVIEW QUESTIONS & SOLUTIONS
Target Audience: Data Engineers, Senior Data Analysts, and Business Intelligence Engineers
Dataset Schema: 
  - customers (customer_id, customer_name, region_id, signup_date)
  - stores (store_id, store_name, region_id, store_type)
  - products (product_id, product_name, category_id, unit_price, cost_price)
  - categories (category_id, category_name, department)
  - transactions (transaction_id, customer_id, store_id, transaction_date, payment_method)
  - transaction_items (item_id, transaction_id, product_id, quantity, discount_amount)
================================================================================
*/

--------------------------------------------------------------------------------
-- CATEGORY 1: BASIC FILTERING & AGGREGATION (SELECT, WHERE, GROUP BY, ORDER BY)
--------------------------------------------------------------------------------

-- Q1 [SELECT & WHERE]: List all transactions that occurred in the 'North' region during the year 2025 with a total bill exceeding $500.
SELECT 
    t.transaction_id,
    t.transaction_date,
    c.customer_name,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS total_amount
FROM transactions t
JOIN customers cust ON t.customer_id = cust.customer_id
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
WHERE t.transaction_date >= '2025-01-01' 
  AND t.transaction_date < '2026-01-01'
  AND cust.region_id = 1
GROUP BY t.transaction_id, t.transaction_date, c.customer_name
HAVING SUM((ti.quantity * p.unit_price) - ti.discount_amount) > 500;


-- Q2 [GROUP BY & ORDER BY]: Find the top 5 product categories by total gross revenue generated all-time.
SELECT 
    cat.category_name,
    SUM(ti.quantity * p.unit_price) AS gross_revenue
FROM transaction_items ti
JOIN products p ON ti.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
GROUP BY cat.category_name
ORDER BY gross_revenue DESC
LIMIT 5;


-- Q3 [WHERE & ORDER BY]: Retrieve all products in the 'Electronics' category whose unit price is between $50 and $200, ordered from cheapest to most expensive.
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE c.category_name = 'Electronics'
  AND p.unit_price BETWEEN 50.00 AND 200.00
ORDER BY p.unit_price ASC;


-- Q4 [GROUP BY & HAVING]: Identify stores that have processed more than 1,000 individual transactions since January 1, 2025.
SELECT 
    s.store_id,
    s.store_name,
    COUNT(t.transaction_id) AS total_transactions
FROM stores s
JOIN transactions t ON s.store_id = t.store_id
WHERE t.transaction_date >= '2025-01-01'
GROUP BY s.store_id, s.store_name
HAVING COUNT(t.transaction_id) > 1000
ORDER BY total_transactions DESC;


-- Q5 [SELECT & WHERE]: Calculate the total discount amount given away per payment method for transactions completed via 'Credit Card' or 'Digital Wallet'.
SELECT 
    t.payment_method,
    SUM(ti.discount_amount) AS total_discounts_given
FROM transactions t
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
WHERE t.payment_method IN ('Credit Card', 'Digital Wallet')
GROUP BY t.payment_method;


--------------------------------------------------------------------------------
-- CATEGORY 2: CONDITIONAL LOGIC & ADVANCED FILTERING (CASE, HAVING)
--------------------------------------------------------------------------------

-- Q6 [CASE]: Categorize every transaction into revenue tiers: 'High Value' (> $1000), 'Medium Value' ($500 - $1000), and 'Low Value' (< $500). Count transactions in each tier.
SELECT 
    revenue_tier,
    COUNT(transaction_id) AS transaction_count
FROM (
    SELECT 
        t.transaction_id,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS net_revenue,
        CASE 
            WHEN SUM((ti.quantity * p.unit_price) - ti.discount_amount) > 1000 THEN 'High Value'
            WHEN SUM((ti.quantity * p.unit_price) - ti.discount_amount) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS revenue_tier
    FROM transactions t
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    GROUP BY t.transaction_id
) t_tiered
GROUP BY revenue_tier
ORDER BY transaction_count DESC;


-- Q7 [CASE & GROUP BY]: Compute the profit margin category for each product based on (unit_price - cost_price) / unit_price. Flag as 'High Margin' (>40%), 'Standard Margin' (20%-40%), or 'Low Margin' (<20%).
SELECT 
    margin_category,
    COUNT(product_id) AS product_count
FROM (
    SELECT 
        product_id,
        CASE 
            WHEN (unit_price - cost_price) / NULLIF(unit_price, 0) > 0.40 THEN 'High Margin'
            WHEN (unit_price - cost_price) / NULLIF(unit_price, 0) BETWEEN 0.20 AND 0.40 THEN 'Standard Margin'
            ELSE 'Low Margin'
        END AS margin_category
    FROM products
) p_margins
GROUP BY margin_category;


-- Q8 [HAVING & GROUP BY]: Find customers who have made purchases across more than 3 distinct store locations.
SELECT 
    c.customer_id,
    cust.customer_name,
    COUNT(DISTINCT t.store_id) AS distinct_stores_visited
FROM transactions t
JOIN customers cust ON t.customer_id = cust.customer_id
GROUP BY c.customer_id, cust.customer_name
HAVING COUNT(DISTINCT t.store_id) > 3;


-- Q9 [CASE & SELECT]: Generate a report showing total sales broken down by store type ('Flagship', 'Standard', 'Express') for the year 2025.
SELECT 
    s.store_type,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS total_sales
FROM stores s
JOIN transactions t ON s.store_id = t.store_id
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
WHERE t.transaction_date >= '2025-01-01' AND t.transaction_date < '2026-01-01'
GROUP BY s.store_type;


-- Q10 [HAVING & WHERE]: Find product categories where the average discount given per item exceeds 15% of the unit price.
SELECT 
    cat.category_name,
    AVG(ti.discount_amount / p.unit_price) AS avg_discount_ratio
FROM transaction_items ti
JOIN products p ON ti.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
GROUP BY cat.category_name
HAVING AVG(ti.discount_amount / p.unit_price) > 0.15;


--------------------------------------------------------------------------------
-- CATEGORY 3: COMPLEX JOINS & SUBQUERIES
--------------------------------------------------------------------------------

-- Q11 [JOINS]: List all customers who have never made a purchase (Left Anti-Join).
SELECT 
    c.customer_id,
    c.customer_name,
    c.signup_date
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.transaction_id IS NULL;


-- Q12 [SUBQUERIES]: Find products whose unit price is higher than the average unit price of all products within their respective category.
p.product_name,
    p.unit_price,
    p.category_id
FROM products p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
);


-- Q13 [JOINS & AGGREGATION]: Retrieve the store name and total sales for the single store that generated the highest revenue in Q4 2025.
SELECT 
    s.store_name,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS q4_revenue
FROM stores s
JOIN transactions t ON s.store_id = t.store_id
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
WHERE t.transaction_date >= '2025-10-01' AND t.transaction_date < '2026-01-01'
GROUP BY s.store_id, s.store_name
ORDER BY q4_revenue DESC
LIMIT 1;


-- Q14 [SUBQUERIES]: Identify customers who spent more than the overall average customer lifetime spend.
SELECT 
    c.customer_id,
    c.customer_name,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS total_spend
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM((ti.quantity * p.unit_price) - ti.discount_amount) > (
    SELECT AVG(customer_spend.spend)
    FROM (
        SELECT 
            t2.customer_id,
            SUM((ti2.quantity * p2.unit_price) - ti2.discount_amount) AS spend
        FROM transactions t2
        JOIN transaction_items ti2 ON t2.transaction_id = ti2.transaction_id
        JOIN products p2 ON ti2.product_id = p2.product_id
        GROUP BY t2.customer_id
    ) customer_spend
);


-- Q15 [JOINS]: Find pairs of products that were bought together in the exact same transaction at least 50 times.
SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(DISTINCT ti1.transaction_id) AS times_bought_together
FROM transaction_items ti1
JOIN transaction_items ti2 ON ti1.transaction_id = ti2.transaction_id AND ti1.product_id < ti2.product_id
JOIN products p1 ON ti1.product_id = p1.product_id
JOIN products p2 ON ti2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
HAVING COUNT(DISTINCT ti1.transaction_id) >= 50
ORDER BY times_bought_together DESC;


--------------------------------------------------------------------------------
-- CATEGORY 4: COMMON TABLE EXPRESSIONS (CTEs)
--------------------------------------------------------------------------------

-- Q16 [CTE]: Use a CTE to calculate monthly sales for 2025, then write an outer query to compute month-over-month (MoM) revenue growth percentage.
WITH monthly_sales AS (
    SELECT 
        EXTRACT(MONTH FROM t.transaction_date) AS sales_month,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS revenue
    FROM transactions t
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    WHERE t.transaction_date >= '2025-01-01' AND t.transaction_date < '2026-01-01'
    GROUP BY EXTRACT(MONTH FROM t.transaction_date)
)
SELECT 
    sales_month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY sales_month) AS prev_month_revenue,
    ROUND(((revenue - LAG(revenue, 1) OVER (ORDER BY sales_month)) / NULLIF(LAG(revenue, 1) OVER (ORDER BY sales_month), 0)) * 100, 2) AS mom_growth_pct
FROM monthly_sales;


-- Q17 [CTE]: Find the top-selling product in each category by total quantity sold using a CTE and window ranking function.
WITH ranked_products AS (
    SELECT 
        cat.category_name,
        p.product_name,
        SUM(ti.quantity) AS total_qty,
        ROW_NUMBER() OVER (PARTITION BY cat.category_id ORDER BY SUM(ti.quantity) DESC) AS rn
    FROM transaction_items ti
    JOIN products p ON ti.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    GROUP BY cat.category_id, cat.category_name, p.product_id, p.product_name
)
SELECT 
    category_name,
    product_name,
    total_qty
FROM ranked_products
WHERE rn = 1;


-- Q18 [CTE]: Identify high-value customer segments using a CTE that tags customers by total spend, then output the customer count per segment.
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS total_spent
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    GROUP BY c.customer_id
),
segmented_customers AS (
    SELECT 
        customer_id,
        total_spent,
        CASE 
        WHEN total_spent > 5000 THEN 'VIP Platinum'
        WHEN total_spent BETWEEN 2000 AND 5000 THEN 'Gold'
        ELSE 'Standard'
        END AS tier
    FROM customer_spending
)
SELECT 
    tier,
    COUNT(customer_id) AS customer_count,
    SUM(total_spent) AS tier_total_revenue
FROM segmented_customers
GROUP BY tier
ORDER BY tier_total_revenue DESC;


-- Q19 [CTE]: Use a CTE to find stores whose total revenue is below the median store revenue.
WITH store_revenues AS (
    SELECT 
        s.store_id,
        s.store_name,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS revenue,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SUM((ti.quantity * p.unit_price) - ti.discount_amount)) OVER () AS median_revenue
    FROM stores s
    JOIN transactions t ON s.store_id = t.store_id
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    GROUP BY s.store_id, s.store_name
)
SELECT 
    store_name,
    revenue,
    median_revenue
FROM store_revenues
WHERE revenue < median_revenue;


-- Q20 [CTE]: Find the longest streak of consecutive days with at least one transaction for each store.
WITH daily_store_sales AS (
    SELECT DISTINCT
        store_id,
        CAST(transaction_date AS DATE) AS sale_date
    FROM transactions
),
numbered_days AS (
    SELECT 
        store_id,
        sale_date,
        sale_date - INTERVAL '1 day' * ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY sale_date) AS streak_group
    FROM daily_store_sales
)
SELECT 
    store_id,
    MIN(sale_date) AS streak_start,
    MAX(sale_date) AS streak_end,
    COUNT(*) AS consecutive_days
FROM numbered_days
GROUP BY store_id, streak_group
ORDER BY consecutive_days DESC
LIMIT 5;


--------------------------------------------------------------------------------
-- CATEGORY 5: WINDOW FUNCTIONS
--------------------------------------------------------------------------------

-- Q21 [WINDOW FUNCTIONS]: Rank stores within each region based on total annual revenue using RANK().
SELECT 
    s.region_id,
    s.store_name,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS store_revenue,
    RANK() OVER (PARTITION BY s.region_id ORDER BY SUM((ti.quantity * p.unit_price) - ti.discount_amount) DESC) AS regional_rank
FROM stores s
JOIN transactions t ON s.store_id = t.store_id
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
GROUP BY s.region_id, s.store_name;


-- Q22 [WINDOW FUNCTIONS]: Calculate a 3-moving average of daily revenue across all stores.
WITH daily_revenue AS (
    SELECT 
        CAST(t.transaction_date AS DATE) AS tx_date,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS daily_rev
    FROM transactions t
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    GROUP BY CAST(t.transaction_date AS DATE)
)
SELECT 
    tx_date,
    daily_rev,
    AVG(daily_rev) OVER (ORDER BY tx_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3d
FROM daily_revenue;


-- Q23 [WINDOW FUNCTIONS]: Find the running total of cumulative sales for each store ordered chronologically by transaction date.
SELECT 
    t.store_id,
    t.transaction_id,
    t.transaction_date,
    SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS transaction_amount,
    SUM(SUM((ti.quantity * p.unit_price) - ti.discount_amount)) OVER (PARTITION BY t.store_id ORDER BY t.transaction_date, t.transaction_id) AS cumulative_store_sales
FROM transactions t
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
GROUP BY t.store_id, t.transaction_id, t.transaction_date;


-- Q24 [WINDOW FUNCTIONS]: For each customer, find their very first purchase date and their most recent purchase date using FIRST_VALUE() or MIN/MAX with over clause.
SELECT DISTINCT
    c.customer_id,
    cust.customer_name,
    MIN(t.transaction_date) OVER (PARTITION BY c.customer_id) AS first_purchase,
    MAX(t.transaction_date) OVER (PARTITION BY c.customer_id) AS latest_purchase
FROM customers cust
JOIN transactions t ON cust.customer_id = t.customer_id
JOIN customers c ON c.customer_id = cust.customer_id;


-- Q25 [WINDOW FUNCTIONS]: Assign quartile buckets (1 to 4) to products based on their unit price using NTILE(4).
SELECT 
    product_id,
    product_name,
    unit_price,
    NTILE(4) OVER (ORDER BY unit_price DESC) AS price_quartile
FROM products;


--------------------------------------------------------------------------------
-- CATEGORY 6: BUSINESS SCENARIO QUESTIONS
--------------------------------------------------------------------------------

-- Q26 [BUSINESS SCENARIO - CHURN ANALYSIS]: Identify 'Churned Customers'—defined as customers who made at least one purchase in 2024 but have zero purchase transactions in 2025.
SELECT 
    c.customer_id,
    c.customer_name,
    MAX(t.transaction_date) AS last_purchase_date
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING MAX(t.transaction_date) >= '2024-01-01' 
   AND MAX(t.transaction_date) < '2025-01-01'
   AND NOT EXISTS (
       SELECT 1 
       FROM transactions t2 
       WHERE t2.customer_id = c.customer_id 
         AND t2.transaction_date >= '2025-01-01'
   );


-- Q27 [BUSINESS SCENARIO - MARKET BASKET / AFFINITY]: Find the top 3 product pairs bought together most frequently across all transactions.
WITH product_pairs AS (
    SELECT 
        ti1.product_id AS prod1_id,
        ti2.product_id AS prod2_id,
        COUNT(DISTINCT ti1.transaction_id) as pair_count
    FROM transaction_items ti1
    JOIN transaction_items ti2 ON ti1.transaction_id = ti2.transaction_id 
      AND ti1.product_id < ti2.product_id
    GROUP BY ti1.product_id, ti2.product_id
)
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    pp.pair_count
FROM product_pairs pp
JOIN products p1 ON pp.prod1_id = p1.product_id
JOIN products p2 ON pp.prod2_id = p2.product_id
ORDER BY pair_count DESC
LIMIT 3;


-- Q28 [BUSINESS SCENARIO - ABC INVENTORY ANALYSIS]: Categorize inventory items into ABC classes based on cumulative revenue contribution: Class A (top 80% revenue), Class B (next 15%), Class C (bottom 5%).
WITH product_revenue AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS rev
    FROM products p
    JOIN transaction_items ti ON p.product_id = ti.product_id
    GROUP BY p.product_id, p.product_name
),
cumulative_calc AS (
    SELECT 
        product_id,
        product_name,
        rev,
        SUM(rev) OVER (ORDER BY rev DESC) AS running_rev,
        SUM(rev) OVER () AS total_rev
    FROM product_revenue
)
SELECT 
    product_id,
    product_name,
    rev,
    ROUND((running_rev / total_rev) * 100, 2) AS cumulative_pct,
    CASE 
        WHEN (running_rev / total_rev) <= 0.80 THEN 'Class A'
        WHEN (running_rev / total_rev) <= 0.95 THEN 'Class B'
        ELSE 'Class C'
    END AS abc_class
FROM cumulative_calc
ORDER BY rev DESC;


-- Q29 [BUSINESS SCENARIO - REFUND & DISCOUNT AUDIT]: Find transactions where total discount given exceeded 30% of the gross transaction value.
SELECT 
    t.transaction_id,
    t.transaction_date,
    SUM(ti.quantity * p.unit_price) AS gross_value,
    SUM(ti.discount_amount) AS total_discount,
    ROUND((SUM(ti.discount_amount) / NULLIF(SUM(ti.quantity * p.unit_price), 0)) * 100, 2) AS discount_percentage
FROM transactions t
JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
JOIN products p ON ti.product_id = p.product_id
GROUP BY t.transaction_id, t.transaction_date
HAVING (SUM(ti.discount_amount) / NULLIF(SUM(ti.quantity * p.unit_price), 0)) > 0.30
ORDER BY discount_percentage DESC;


-- Q30 [BUSINESS SCENARIO - STORE PERFORMANCE & GROWTH]: Calculate Year-over-Year (YoY) revenue growth per store comparing 2024 to 2025.
WITH store_yearly AS (
    SELECT 
        s.store_id,
        s.store_name,
        EXTRACT(YEAR FROM t.transaction_date) AS tx_year,
        SUM((ti.quantity * p.unit_price) - ti.discount_amount) AS annual_revenue
    FROM stores s
    JOIN transactions t ON s.store_id = t.store_id
    JOIN transaction_items ti ON t.transaction_id = ti.transaction_id
    JOIN products p ON ti.product_id = p.product_id
    WHERE EXTRACT(YEAR FROM t.transaction_date) IN (2024, 2025)
    GROUP BY s.store_id, s.store_name, EXTRACT(YEAR FROM t.transaction_date)
)
SELECT 
    y25.store_name,
    y24.annual_revenue AS revenue_2024,
    y25.annual_revenue AS revenue_2025,
    ROUND(((y25.annual_revenue - y24.annual_revenue) / NULLIF(y24.annual_revenue, 0)) * 100, 2) AS yoy_growth_pct
FROM store_yearly y25
JOIN store_yearly y24 ON y25.store_id = y24.store_id AND y25.tx_year = 2025 AND y24.tx_year = 2024
ORDER BY yoy_growth_pct DESC;
