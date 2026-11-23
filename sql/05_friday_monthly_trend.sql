-- Friday ticket: net revenue trend, June – September 2026
-- Months are cut in UTC (Priya's definition).

-- Step 1: Sales by month
SELECT monthname(o.order_ts)            AS sales_month,
       SUM(oi.quantity * oi.unit_price) AS gross_sales
FROM orders o
JOIN order_items oi
  ON oi.order_id = o.order_id
WHERE o.order_ts >= TIMESTAMP '2026-06-01'
  AND o.order_ts <  TIMESTAMP '2026-10-01'
  AND o.status <> 'cancelled'
GROUP BY monthname(o.order_ts);


-- Step 2: Refunds by month
-- Count each refund once. Duplicates were logged at different times,
-- so dedupe on the month rather than the exact timestamp.
WITH unique_refunds AS (
  SELECT DISTINCT order_id, amount, monthname(refund_ts) AS refund_month
  FROM refunds
  WHERE refund_ts >= '2026-06-01'
    AND refund_ts <  '2026-10-01'
)
SELECT refund_month,
       SUM(amount) AS refund_dollars
FROM unique_refunds
GROUP BY refund_month;


-- Step 3: Net revenue by month, with the previous month alongside
WITH sales AS (
  SELECT monthname(o.order_ts)            AS sales_month,
         month(o.order_ts)                AS month_num,
         SUM(oi.quantity * oi.unit_price) AS gross_sales
  FROM orders o
  JOIN order_items oi
    ON oi.order_id = o.order_id
  WHERE o.order_ts >= TIMESTAMP '2026-06-01'
    AND o.order_ts <  TIMESTAMP '2026-10-01'
    AND o.status <> 'cancelled'
  GROUP BY monthname(o.order_ts), month(o.order_ts)
),
unique_refunds AS (
  SELECT DISTINCT order_id, amount, monthname(refund_ts) AS refund_month
  FROM refunds
  WHERE refund_ts >= '2026-06-01'
    AND refund_ts <  '2026-10-01'
),
refunded AS (
  SELECT refund_month,
         SUM(amount) AS refund_dollars
  FROM unique_refunds
  GROUP BY refund_month
)
SELECT s.sales_month,
       s.gross_sales,
       r.refund_dollars,
       s.gross_sales - r.refund_dollars AS net_revenue,
       LAG(s.gross_sales - r.refund_dollars)
         OVER (ORDER BY s.month_num)    AS prev_month_net_revenue
FROM sales s
JOIN refunded r
  ON r.refund_month = s.sales_month
ORDER BY s.month_num;
