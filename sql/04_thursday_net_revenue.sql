-- Thursday ticket: why do Marcus and Priya disagree on September revenue?

-- Step 1: Marcus's number
-- Gross sales with months cut 4 hours after UTC midnight, cancelled orders included.
SELECT SUM(oi.quantity * oi.unit_price) AS gross_sales_sep
FROM orders o
JOIN order_items oi
  ON oi.order_id = o.order_id
WHERE o.order_ts >= TIMESTAMP '2026-09-01' + INTERVAL 4 HOUR
  AND o.order_ts <  TIMESTAMP '2026-10-01' + INTERVAL 4 HOUR;


-- Step 2: Priya's sales
-- UTC months, cancelled orders excluded.
SELECT SUM(oi.quantity * oi.unit_price) AS gross_sales_sep
FROM orders o
JOIN order_items oi
  ON oi.order_id = o.order_id
WHERE o.order_ts >= TIMESTAMP '2026-09-01'
  AND o.order_ts <  TIMESTAMP '2026-10-01'
  AND o.status <> 'cancelled';


-- Step 3: Subtract the refunds
-- Priya's sales minus September refunds, counting each duplicate refund once.
WITH sales AS (
  SELECT SUM(oi.quantity * oi.unit_price) AS sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status <> 'cancelled'
    AND o.order_ts >= '2026-09-01'
    AND o.order_ts <  '2026-10-01'
),
refunded AS (
  SELECT SUM(amount) AS refunds
  FROM (
    SELECT DISTINCT order_id, amount
    FROM refunds
    WHERE refund_ts >= '2026-09-01'
      AND refund_ts <  '2026-10-01'
  ) AS unique_refunds
)
SELECT sales - refunds AS net_revenue
FROM sales, refunded;
