-- Tuesday ticket: active customers
-- Customers with at least one non-cancelled order in the last 12 months
-- (Oct 2025 – Sep 2026), excluding internal test accounts.

SELECT COUNT(DISTINCT o.customer_id) AS active_customers
FROM orders o
JOIN customers c
  ON o.customer_id = c.customer_id
WHERE c.is_test_account = FALSE
  AND o.status <> 'cancelled'
  AND o.order_ts >= '2025-10-01'
  AND o.order_ts <  '2026-10-01';
