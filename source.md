# Sources: Bronze Layer

Bronze tables are loaded into SQLite via `setup_bronze.sql` and consumed by staging models via `source()`.

## dbt Source Config

| Property | Value |
|---|---|
| Source name | `bakery` |
| Database | `bakery` |
| Schema | `main` (SQLite default) |

---

## Tables

### `raw_customers`
**Grain:** One row per customer. Unique by `email`.

| Column | Type | Description |
|---|---|---|
| `customer_id` | integer | Primary key |
| `first_name` | text | |
| `last_name` | text | |
| `email` | text | Unique — used for deduplication |
| `city` | text | Customer city |
| `created_at` | date | Account creation date |

---

### `raw_products`
**Grain:** One row per product. Includes retired products (`is_active = false`).

| Column | Type | Description |
|---|---|---|
| `product_id` | integer | Primary key |
| `product_name` | text | Display name |
| `category` | text | `bread` \| `pastry` \| `cake` \| `drink` |
| `price` | decimal(6,2) | Current list price |
| `is_active` | boolean | `false` = retired; exclude from active product lists |

---

### `raw_orders`
**Grain:** One row per order.

| Column | Type | Description |
|---|---|---|
| `order_id` | integer | Primary key |
| `customer_id` | integer | FK → `raw_customers.customer_id` |
| `order_date` | date | Date the order was placed |
| `status` | text | `placed` \| `processing` \| `completed` \| `cancelled` |
| `total_amount` | decimal(8,2) | Pre-calculated order total; equals sum of line items |

> Revenue is recognised on `completed` orders only.

---

### `raw_order_items`
**Grain:** One row per line item within an order. An order has one or more items.

| Column | Type | Description |
|---|---|---|
| `order_item_id` | integer | Primary key |
| `order_id` | integer | FK → `raw_orders.order_id` |
| `product_id` | integer | FK → `raw_products.product_id` |
| `quantity` | integer | Number of units |
| `unit_price` | decimal(6,2) | Price at time of order (may differ from current `raw_products.price`) |
