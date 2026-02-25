-- setup_bronze.sql
-- Creates and populates the bronze layer in SQLite.
-- Run with: sqlite3 bakery.db < setup_bronze.sql
-- Idempotent: safe to re-run. Schema is preserved; data is refreshed on each run.
-- Bronze is managed outside dbt; staging models consume these tables via source().

-- ============================================================
-- DDL — create tables if they don't already exist
-- ============================================================

CREATE TABLE IF NOT EXISTS raw_customers (
    customer_id  INTEGER PRIMARY KEY,
    first_name   TEXT    NOT NULL,
    last_name    TEXT    NOT NULL,
    email        TEXT    NOT NULL UNIQUE,
    city         TEXT,
    created_at   DATE    NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_products (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT           NOT NULL,
    category     TEXT           NOT NULL,  -- bread | pastry | cake | drink
    price        DECIMAL(6,2)   NOT NULL,
    is_active    BOOLEAN        NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS raw_orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER        NOT NULL,
    order_date   DATE           NOT NULL,
    status       TEXT           NOT NULL,  -- placed | processing | completed | cancelled
    total_amount DECIMAL(8,2)   NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER        NOT NULL,
    product_id    INTEGER        NOT NULL,
    quantity      INTEGER        NOT NULL,
    unit_price    DECIMAL(6,2)   NOT NULL
);

-- ============================================================
-- Data refresh — clear and reload in FK-safe order
-- ============================================================

DELETE FROM raw_order_items;
DELETE FROM raw_orders;
DELETE FROM raw_products;
DELETE FROM raw_customers;

-- ============================================================
-- Customers (10 rows)
-- ============================================================

INSERT INTO raw_customers VALUES
( 1, 'Alice',  'Johnson',  'alice.johnson@email.com',  'New York',     '2024-01-10'),
( 2, 'Bob',    'Smith',    'bob.smith@email.com',      'Los Angeles',  '2024-01-15'),
( 3, 'Carol',  'Williams', 'carol.williams@email.com', 'Chicago',      '2024-02-03'),
( 4, 'David',  'Brown',    'david.brown@email.com',    'Houston',      '2024-02-14'),
( 5, 'Emma',   'Davis',    'emma.davis@email.com',     'Phoenix',      '2024-03-01'),
( 6, 'Frank',  'Miller',   'frank.miller@email.com',   'Philadelphia', '2024-03-22'),
( 7, 'Grace',  'Wilson',   'grace.wilson@email.com',   'San Antonio',  '2024-04-05'),
( 8, 'Henry',  'Moore',    'henry.moore@email.com',    'San Diego',    '2024-04-18'),
( 9, 'Iris',   'Taylor',   'iris.taylor@email.com',    'Dallas',       '2024-05-02'),
(10, 'Jack',   'Anderson', 'jack.anderson@email.com',  'Seattle',      '2024-05-20');

-- ============================================================
-- Products (13 rows — 12 active, 1 retired)
-- ============================================================

INSERT INTO raw_products VALUES
-- bread
( 1, 'Sourdough Loaf',    'bread',   6.50, 1),
( 2, 'Baguette',          'bread',   3.25, 1),
( 3, 'Whole Wheat Bread', 'bread',   5.75, 1),
-- pastry
( 4, 'Croissant',         'pastry',  3.25, 1),
( 5, 'Pain au Chocolat',  'pastry',  3.75, 1),
( 6, 'Almond Croissant',  'pastry',  4.50, 1),
-- cake
( 7, 'Birthday Cake',     'cake',   45.00, 1),
( 8, 'Chocolate Cake',    'cake',   38.00, 1),
( 9, 'Carrot Cake',       'cake',   35.00, 1),
-- drink
(10, 'Filter Coffee',     'drink',   3.00, 1),
(11, 'Latte',             'drink',   4.50, 1),
(12, 'Orange Juice',      'drink',   4.00, 1),
-- retired
(13, 'Seasonal Pie',      'cake',   24.00, 0);

-- ============================================================
-- Orders (15 rows — mix of all 4 statuses)
-- total_amount = sum(quantity * unit_price) for each order
-- ============================================================

INSERT INTO raw_orders VALUES
-- completed orders (revenue-recognised)
( 1,  1, '2024-02-01', 'completed',  16.00),  -- sourdough x2 + coffee x1
( 2,  2, '2024-02-05', 'completed',  38.00),  -- chocolate cake x1
( 4,  4, '2024-02-14', 'completed',  45.00),  -- birthday cake x1
( 5,  5, '2024-02-20', 'completed',  15.50),  -- baguette x2 + latte x2
( 7,  7, '2024-03-05', 'completed',  50.50),  -- carrot cake x1 + latte x2 + croissant x2
( 8,  8, '2024-03-10', 'completed',  35.00),  -- carrot cake x1
(10, 10, '2024-03-20', 'completed',  48.00),  -- birthday cake x1 + coffee x1
(11,  1, '2024-04-01', 'completed',  17.50),  -- whole wheat x2 + coffee x2
(12,  3, '2024-04-10', 'completed',  38.00),  -- chocolate cake x1
(14,  2, '2024-04-20', 'completed',  45.00),  -- birthday cake x1
-- cancelled orders (excluded from revenue)
( 3,  3, '2024-02-10', 'cancelled',  13.00),  -- croissant x4
(13,  5, '2024-04-15', 'cancelled',   9.00),  -- almond croissant x2
-- in-flight orders
( 6,  6, '2024-03-01', 'processing', 23.75),  -- sourdough x1 + pain au choc x3 + coffee x2
( 9,  9, '2024-03-15', 'placed',     10.50),  -- baguette x2 + OJ x1
(15,  7, '2024-05-01', 'processing', 15.50);  -- pain au choc x2 + OJ x2

-- ============================================================
-- Order items (25 rows)
-- ============================================================

INSERT INTO raw_order_items VALUES
-- order 1: sourdough x2 + coffee x1 = 13.00 + 3.00 = 16.00
( 1,  1,  1, 2, 6.50),
( 2,  1, 10, 1, 3.00),
-- order 2: chocolate cake x1 = 38.00
( 3,  2,  8, 1,38.00),
-- order 3 (cancelled): croissant x4 = 13.00
( 4,  3,  4, 4, 3.25),
-- order 4: birthday cake x1 = 45.00
( 5,  4,  7, 1,45.00),
-- order 5: baguette x2 + latte x2 = 6.50 + 9.00 = 15.50
( 6,  5,  2, 2, 3.25),
( 7,  5, 11, 2, 4.50),
-- order 6 (processing): sourdough x1 + pain au choc x3 + coffee x2 = 6.50 + 11.25 + 6.00 = 23.75
( 8,  6,  1, 1, 6.50),
( 9,  6,  5, 3, 3.75),
(10,  6, 10, 2, 3.00),
-- order 7: carrot cake x1 + latte x2 + croissant x2 = 35.00 + 9.00 + 6.50 = 50.50
(11,  7,  9, 1,35.00),
(12,  7, 11, 2, 4.50),
(13,  7,  4, 2, 3.25),
-- order 8: carrot cake x1 = 35.00
(14,  8,  9, 1,35.00),
-- order 9 (placed): baguette x2 + OJ x1 = 6.50 + 4.00 = 10.50
(15,  9,  2, 2, 3.25),
(16,  9, 12, 1, 4.00),
-- order 10: birthday cake x1 + coffee x1 = 45.00 + 3.00 = 48.00
(17, 10,  7, 1,45.00),
(18, 10, 10, 1, 3.00),
-- order 11: whole wheat x2 + coffee x2 = 11.50 + 6.00 = 17.50
(19, 11,  3, 2, 5.75),
(20, 11, 10, 2, 3.00),
-- order 12: chocolate cake x1 = 38.00
(21, 12,  8, 1,38.00),
-- order 13 (cancelled): almond croissant x2 = 9.00
(22, 13,  6, 2, 4.50),
-- order 14: birthday cake x1 = 45.00
(23, 14,  7, 1,45.00),
-- order 15 (processing): pain au choc x2 + OJ x2 = 7.50 + 8.00 = 15.50
(24, 15,  5, 2, 3.75),
(25, 15, 12, 2, 4.00);
