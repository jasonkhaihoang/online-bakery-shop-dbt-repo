# schema_contracts.md

Example Gold-tier YAML schema with enforced contracts.

## `models/marts/customers/_mart_customers.yml`

```yaml
version: 2

models:
  - name: fct_customer_orders
    description: >
      One row per customer with lifetime order aggregates.
      Grain: customer_id.
    config:
      contract:
        enforced: true
      meta:
        domain: customers
        owner: data-eng
        pii: false
        tier: 1
    columns:
      - name: customer_id
        description: Unique customer identifier (from Salesforce or Stripe).
        data_type: string
        tests:
          - not_null
          - unique
      - name: customer_name
        description: Display name of the customer.
        data_type: string
        tests:
          - not_null
      - name: total_orders
        description: Count of all completed orders.
        data_type: int
      - name: lifetime_revenue
        description: Sum of all payment amounts in base currency.
        data_type: decimal
      - name: first_order_date
        description: Date of the customer's first order.
        data_type: date
      - name: last_order_date
        description: Date of the customer's most recent order.
        data_type: date

  - name: dim_customer
    description: >
      Customer dimension with attributes from unified customer model.
      Grain: customer_id.
    config:
      contract:
        enforced: true
      meta:
        domain: customers
        owner: data-eng
        pii: true
        tier: 1
    columns:
      - name: customer_id
        description: Unique customer identifier.
        data_type: string
        tests:
          - not_null
          - unique
      - name: customer_name
        description: Display name.
        data_type: string
      - name: email
        description: Customer email address. PII.
        data_type: string
        meta:
          pii: true
      - name: industry
        description: Industry classification from Salesforce.
        data_type: string
      - name: first_seen_at
        description: Earliest known date across all source systems.
        data_type: timestamp
```