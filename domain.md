# Domain: Sales — Online Bakery Shop

## Business Intent

Track revenue and order performance for an online bakery. The domain answers:
- How much revenue is being generated, and how is it trending?
- What is the volume and mix of orders?

## Primary Consumers

| Consumer | Use case |
|---|---|
| Finance / Exec | Revenue KPIs, top-line reporting |
| Marketing | Customer segmentation, acquisition, retention |

## Key Entities

| Entity | Source table | Description |
|---|---|---|
| Customer | `raw_customers` | Identified by `customer_id`; unique per email address |
| Order | `raw_orders` | A purchase transaction placed by a customer |
| Order Item | `raw_order_items` | Line items within an order; links orders to products |
| Product | `raw_products` | Bakery items available for sale; has a category and active flag |

## Business Rules

### Revenue Recognition
Revenue is counted only on orders with status `completed`.
> Note: `delivered` was initially considered — clarify with business if these are equivalent or if `delivered` should be a separate status in the lifecycle.

### Order Status Lifecycle
```
placed → processing → completed
                    → cancelled
```
Cancellations can occur from `placed` or `processing`. `completed` is the terminal success state.

### Customer Identity
One customer per email address. `customer_id` is the primary key; deduplication is by `email`.

### Product Categorisation
Products belong to one of four categories: `bread`, `cakes`, `pastries`, `drinks`.
The `is_active` flag distinguishes current vs retired products.

## Mart Consumer Areas

| Area | Purpose |
|---|---|
| `revenue` | Order-level and time-series revenue facts |
| `customers` | Customer dimension and behavioural metrics |
| `products` | Product dimension with category rollups |
