C
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS items;

use ankit_bansal


CREATE TABLE transactions (
    buyer_id INT,
    store_id VARCHAR(5),
    item_id VARCHAR(10),
    gross_transaction_value INT,
    purchase_time DATETIME,
    refund_item DATETIME DEFAULT NULL
);

INSERT INTO transactions VALUES
(4, 'a', 'D2', 58, '2019-09-04 04:48:35', NULL),
(3, 'b', 'b2', 475, '2020-04-11 19:24:47', NULL),
(12, 'b', 'b2', 475, '2020-04-11 19:24:47', '2020-04-16 22:28:00'),
(3, 'f', 'f9', 33, '2020-09-01 23:59:46', '2020-09-03 05:00:00'),
(7, 'd', 'd3', 250, '2020-10-23 21:35:09', NULL),
(9, 'e', 'e7', 24, '2020-04-02 15:38:25', NULL),
(5, 'g', 'g6', 61, '2020-10-15 12:13:02', '2020-10-18 02:53:00');


CREATE TABLE items (
    item_id VARCHAR(10),
    item_name VARCHAR(50)
);

INSERT INTO items VALUES
('D2', 'jeans'),
('b2', 'shirt'),
('f9', 'denim pants'),
('d3', 't-shirt'),
('e7', 'crocs'),
('g6', 'wall paint');

-- 1. What is the count of purchases per month (excluding refunded purchases)?
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS purchase_month,
    COUNT(*) AS total_purchases
FROM transactions
WHERE refund_item IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY purchase_month;

-- 2. How many stores receive at least 5 orders/transactions in October 2020?
SELECT store_id, COUNT(*) AS order_count
FROM transactions
WHERE refund_item IS NULL
AND purchase_time BETWEEN '2020-10-01' AND '2020-10-31'
GROUP BY store_id
HAVING order_count >= 5;

-- 3. For each store, what is the shortest interval (in min) from purchase to refund time?
SELECT 
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_item)) AS shortest_refund_min
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;

#Gross transaction value of each store’s first order
SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN (
    SELECT store_id, MIN(purchase_time) AS first_time
    FROM transactions
    GROUP BY store_id
) x ON t.store_id = x.store_id
AND t.purchase_time = x.first_time
ORDER BY t.store_id;

-- Most popular item name on buyers’ first purchase
WITH fp AS (
    SELECT buyer_id, item_id
    FROM transactions t
    WHERE purchase_time = (
        SELECT MIN(purchase_time)
        FROM transactions
        WHERE buyer_id = t.buyer_id
    )
)
SELECT i.item_name, COUNT(*) AS frequency
FROM fp
JOIN items i USING (item_id)
GROUP BY item_name
ORDER BY frequency DESC
LIMIT 1;


-- Refund eligibility flag (must be within 72 hours)
SELECT 
    buyer_id, item_id, purchase_time, refund_item,
    CASE 
        WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_item) <= 72
        THEN 'Refund Allowed'
        ELSE 'Not Allowed'
    END AS refund_status
FROM transactions
WHERE refund_item IS NOT NULL;


-- 7. Create a rank by buyer_id column in the transaction items table and filter for only the second
-- purchase per buyer. (Ignore refunds here)
-- Second purchase per buyer (ignore refunds)
WITH ranked AS (
    SELECT
        buyer_id,
        purchase_time,
        store_id,
        item_id,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS purchase_rank
    FROM transactions
)
SELECT buyer_id, purchase_time, store_id, item_id, purchase_rank
FROM ranked
WHERE purchase_rank = 2;


-- 8. How will you find the second transaction time per buyer (don’t use min/max; assume there
-- were more transactions per buyer in the table)
WITH seq AS (
    SELECT buyer_id, purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rnk
    FROM transactions
)
SELECT buyer_id, purchase_time AS second_transaction_time
FROM seq
WHERE rnk = 2;



