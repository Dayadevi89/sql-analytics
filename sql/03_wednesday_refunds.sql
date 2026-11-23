-- Wednesday ticket: September refunds and the product behind them

-- Step 1: Count September's refunds
SELECT COUNT(*) AS refund_count
FROM refunds
WHERE refund_ts >= '2026-09-01'
  AND refund_ts <  '2026-10-01';


-- Step 2: Look for duplicates
-- Orders with more than one refund logged in September.
SELECT COUNT(*) AS orders_with_multiple_refunds
FROM (
    SELECT order_id
    FROM refunds
    WHERE refund_ts >= '2026-09-01'
      AND refund_ts <  '2026-10-01'
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS multi;


-- Step 3: Find the real culprit
-- Drop duplicate refunds (same order, same amount, within 1 hour),
-- spread each order's refund across its items by line value,
-- and find the product with the most refunded dollars.
WITH sep AS (
    SELECT order_id, amount, refund_ts,
           LAG(refund_ts) OVER (PARTITION BY order_id, amount
                                ORDER BY refund_ts) AS prev_ts
    FROM refunds
    WHERE refund_ts >= '2026-09-01'
      AND refund_ts <  '2026-10-01'
),
deduped AS (                          -- drop same-amount repeats within 1 hour
    SELECT order_id, SUM(amount) AS refund_amount
    FROM sep
    WHERE prev_ts IS NULL
       OR refund_ts - prev_ts > INTERVAL '1 hour'
    GROUP BY order_id                 -- one row per order
),
item_share AS (                       -- each item's share of its order's value
    SELECT order_id, product_id,
           quantity * unit_price
             / SUM(quantity * unit_price) OVER (PARTITION BY order_id) AS share
    FROM order_items
)
SELECT p.product_id,
       p.product_name,
       ROUND(SUM(d.refund_amount * s.share), 2) AS refund_dollars
FROM deduped d
JOIN item_share s ON s.order_id   = d.order_id
JOIN products   p ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY refund_dollars DESC
LIMIT 1;
