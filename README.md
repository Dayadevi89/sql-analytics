# SQL Analytics Tickets: A Week of E-commerce Analysis

A week of analyst tickets worked in SQL against an e-commerce dataset of customers, orders, order items, products and refunds. Each day's ticket builds on the one before: from exploring the data, to defining active customers, to tracking down duplicate refunds, to settling a revenue disagreement between two stakeholders, to a monthly net revenue trend.

These queries were written to resolve the tickets given my AnalystHive for my Week 1 as Junior Data Analyst at a virtual company.They're written for DuckDB.

## Tickets

| Day | Question | File |
|---|---|---|
| Monday | How many customers are there? | [`01_monday_explore.sql`](sql/01_monday_explore.sql) |
| Tuesday | How many active customers did we have in the last 12 months? | [`02_tuesday_active_customers.sql`](sql/02_tuesday_active_customers.sql) |
| Wednesday | Why are September refunds so high, and which product is behind them? | [`03_wednesday_refunds.sql`](sql/03_wednesday_refunds.sql) |
| Thursday | Why do Marcus's and Priya's September revenue numbers disagree? | [`04_thursday_net_revenue.sql`](sql/04_thursday_net_revenue.sql) |
| Friday | How has net revenue moved month by month, June to September 2026? | [`05_friday_monthly_trend.sql`](sql/05_friday_monthly_trend.sql) |

## Data model

```
customers   (customer_id, is_test_account, ...)
orders      (order_id, customer_id, status, order_ts)
order_items (order_id, product_id, quantity, unit_price)
products    (product_id, product_name)
refunds     (order_id, amount, refund_ts)
```

## What each ticket covers

**Monday: exploring the data.** A first look at the customers table before answering business questions.

**Tuesday: active customers.** An "active customer" is one with at least one non-cancelled order between Oct 2025 and Sep 2026, with internal test accounts excluded. The date range uses a half-open interval (`>= start AND < end`) so no timestamps on the last day are missed.

**Wednesday: duplicate refunds.** September's refund count looked inflated. Grouping by `order_id` showed orders with more than one refund. The duplicates were the same order and amount logged again shortly after, so step 3 uses `LAG()` to drop same-amount repeats within one hour. It then spreads each order's refund across its items in proportion to line value, which finds the product with the most refunded dollars.

**Thursday: reconciling two revenue numbers.** Marcus and Priya disagreed on September revenue for two reasons:
1. **Month boundaries:** Marcus cuts months 4 hours after UTC midnight, while Priya uses UTC.
2. **Cancelled orders:** Marcus includes them and Priya excludes them.

Step 3 takes Priya's definition and subtracts deduplicated refunds to get net revenue.

**Friday: monthly trend.** Gross sales, deduplicated refunds and net revenue for each month from June to September, with the previous month's net revenue next to each one (via `LAG()`) for month-over-month comparison.

## SQL techniques used

- Half-open date ranges for clean month and year boundaries
- `COUNT(DISTINCT ...)`, `GROUP BY ... HAVING` to find duplicates
- CTEs to build multi-step logic
- Window functions: `LAG()` for deduplication and month-over-month comparison, and `SUM() OVER (PARTITION BY ...)` for proportional allocation
- Reconciling metric definitions between stakeholders
