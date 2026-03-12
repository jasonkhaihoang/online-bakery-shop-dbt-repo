# Claude Skills - v2 - Mar 2nd, 2026

> Source: https://www.notion.so/8c518ff8c53a49458088d2502926c0b4

A restructured reference of all **Claude Skills**, organized into two distinct phases based on whether they depend on business intent.

Each skill is produced by running the corresponding Skill Builder interview prompt.

---

## How this works

```
Phase 1 — Project Provisioning (run once)
        ↓ output: project_standards.md + empty project scaffold

Phase 2 — Intent Execution (run per business intent)
        ↓ input: business intent + project_standards.md
        ↓ output: dbt models + artefacts
```

> **Rule:** If a skill needs to know a specific business entity (orders, customers, products) to do its work → it belongs to Phase 2. If not → Phase 1.

---

# Phase 1 — Project Provisioning

_Business-agnostic. Run once per project (or when big refactoring occurs)._
_Output: a fully scaffolded dbt project structure with no models — only standards, configs, and conventions._

| Skill | Name | Description | Decided by the Skill | Input | Generated artefacts |
|-------|------|-------------|----------------------|-------|---------------------|
| 4.1 | **scaffolding-dbt-project-structure** — _True entry point. All other skills depend on this._ | Use when setting up a new dbt project from scratch, or performing a major structural refactor (layer boundaries, naming, connection config). | **Layers & folders:**<br>• source (bronze) ⇒ staging (`models/staging/{source}/`) ⇒ intermediate/silver (`models/intermediate/{concept}/`) ⇒ mart/gold (`models/marts/{consumer_area}/`)<br><br>**Bronze ownership:**<br>• Bronze is managed outside dbt (by DLT); dbt never touches it<br>• Staging is the dbt entry point — references bronze via `source()`, not `ref()`<br>• Seeds (`seeds/`) load bronze data; `_source.yml` declares those same tables for `source()` — they must stay in sync<br><br>**Naming conventions** (snake_case, double `__` separator):<br>• Staging: `stg_{source}__{entity}.sql`<br>• Intermediate: `int_{concept}__{descriptor}.sql`<br>• Mart fact: `fct_{entity}.sql` \| Mart dim: `dim_{entity}.sql`<br>• YAML co-files: `_{layer}_{source_or_area}.yml` — one per folder, not per model<br>• Sources file: `_source.yml`<br><br>**DAG rules (enforced):**<br>• `stg_*` → ONLY `source()` — never `ref()`<br>• `int_*` → ONLY `ref()` to `stg_*` or `int_*`<br>• `fct_*`/`dim_*` → ONLY `ref()` to `int_*` or `stg_*`<br>• No backwards refs; no cross-domain refs<br><br>**Testing baseline per layer:**<br>• Staging: `unique` + `not_null` on PK column<br>• Intermediate: `unique` + `not_null` on `unique_key`<br>• Mart: `unique` + `not_null` on PK; `not_null` on all contracted columns<br>• Approved test package: `dbt_utils` (only) — no additional test packages<br><br>**Materialization defaults per layer:**<br>• Staging → `view` (passthrough only; no storage cost, always fresh)<br>• Intermediate → `incremental` + `incremental_strategy: merge`<br>• Mart → `table` (consumer-ready; predictable query performance for SLA-bound consumers)<br>• Setting intermediate to `table` is a hard violation<br><br>**Fabric connection:**<br>• Adapter: dbt-fabric (ODBC) — not dbt-spark or dbt-synapse<br>• One SQL Analytics Endpoint per lakehouse (Bronze/Silver/Gold)<br>• Endpoint URL format: `{workspace}.datawarehouse.fabric.microsoft.com`<br>• Service principal auth (client_id, client_secret, tenant_id) for CI/prod; Entra ID interactive for local dev<br>• `dev` and `prod` targets defined in `profiles.yml`, each pointing to their respective lakehouse endpoints | _Walk through one topic at a time. After all topics, show a summary for confirmation before generating artefacts._<br><br>**Bronze ownership:**<br>→ Fill in: List bronze source tables and the schema/database they are loaded into<br><br>**Fabric connection:**<br>→ Fill in for each lakehouse:<br>&nbsp;&nbsp;• **Bronze** (source tables — referenced by `_source.yml`): endpoint URL<br>&nbsp;&nbsp;• **Silver** (intermediate models — `models/intermediate/`): endpoint URL<br>&nbsp;&nbsp;• **Gold** (mart models — `models/marts/`): endpoint URL<br>→ Fill in: Schema name for each layer (the schema dbt writes to *within* the lakehouse, e.g. `dbo`, `staging`, `silver`, `gold`)<br>→ Select: Where are service principal credentials stored? `.env file` \| `environment variables` \| `Azure Key Vault` \| `other`<br><br>**Metadata:**<br>→ Select / fill in: Which `meta` keys are required on every model? (e.g. `owner: "data-engineering"`, `domain: "sales"`, `sla: "07:00"`, `contains_pii: false`) | **Layers & folders:**<br>• **Config:** `dbt_project.yml` (folder/layer configs, materialization defaults, tag/meta defaults)<br><br>**Bronze ownership:**<br>• **Docs:** `source.md` (bronze table inventory)<br>• **YAML:** `models/staging/{source}/_source.yml` (source declarations)<br><br>**Naming conventions:**<br>• **Config:** `.sqlfluff` (naming/style enforcement per layer)<br><br>**Testing baseline:**<br>• **Config:** `packages.yml` (dbt_utils)<br><br>**Fabric connection:**<br>• **Config:** `profiles.yml` (dev + prod targets, ODBC endpoints, auth)<br>• **SQL:** `macros/generate_schema_name.sql` (dev/prod schema isolation)<br><br>**Metadata:**<br>• **YAML:** `models/**/schema.yml` (required `meta` keys template)<br><br>**Always-on:**<br>• **Docs:** `project_standards.md` (documents what dbt artefacts don't capture: DAG rules, layer placement logic, business logic placement rules, bronze ownership) |

> **`project_standards.md`** is the key output of Phase 1. It is the always-on context loaded by every Phase 2 skill. It answers three questions for any model:
> 1. _Which layer does this belong to?_ → 4.1
> 2. _How should it be materialized?_ → 4.2
> 3. _What does it depend on?_ → 4.1 (DAG rules)

> **Phase 1 file ownership — hard rule for agents and engineers**
>
> Phase 1 exclusively owns the following files. Phase 2 must never modify them:
> - `dbt_project.yml` — layer configs, materialization defaults, tag/meta defaults
> - `profiles.yml` — connection targets (dev/prod)
> - `.sqlfluff`, `packages.yml`, CI config skeleton
> - `project_standards.md`
>
> **Phase 2 may only:**
> - Create new files under `models/`, `tests/`, `seeds/`, `macros/`
> - Add `schema.yml` entries for new models
> - Create or update domain-specific docs under `docs/`
>
> If a business intent requires changes to Phase 1 files, **stop and escalate** — this is a refactoring decision, not an implementation decision. Return to Phase 1 Skill Builders to revise the project standards.

---

# Phase 2 — Intent Execution

_Business-driven. Run once per business intent (e.g. sales report, sales funnel, customer cohort)._
_Input: business intent + **`project_standards.md`**. Output: dbt models + paired artefacts._

## Entry Point

| Skill | Name | Description | Input | Generated artefacts |
|-------|------|-------------|-------|---------------------|
| — | **converting-business-intent-to-dbt-models** — _Master skill. Orchestrates all Phase 2 sub-skills. Start here for every new business intent._ | Use when a new business intent arrives (report, dashboard, metric, or analysis). Orchestrates all Phase 2 sub-skills from start to finish. | 1. What is the business intent? (e.g. "monthly revenue by product category", "customer retention cohort")<br>2. What are the expected consumers? (BI tool, semantic layer, ML pipeline, direct SQL)<br>3. What is the grain of the primary output? (e.g. one row per order, one row per customer per month) | • **SQL:** staging, intermediate, and mart model files<br>• **YAML:** paired schema files per layer<br>• **Docs:** `project_standards.md` read as always-on context |

## Section 4 — Materialization

| Skill | Name | Description | Input | Generated artefacts |
|-------|------|-------------|-------|---------------------|
| 4.2 | **Materialization Standards** — _Required before building any dbt model. Determines how each model is physically built in Fabric._ | Use when determining or overriding how a specific model is physically built (view, table, incremental). | 1. What is the business intent being built? (e.g. "sales funnel", "customer retention")<br>2. For each model in this intent, what is the expected data volume? (approximate row counts or GB)<br>3. What is the required refresh frequency for this intent's models?<br>4. What are the freshness/SLA requirements? (e.g. must be ready by 8am for the morning report)<br>5. Are any models expected to exceed the layer-default threshold, triggering an incremental override?<br>6. For any incremental models: what is the unique key and preferred strategy? (append, merge, delete+insert) | • **Config:** `dbt_project.yml` additions (model-level overrides, if any)<br>• **SQL:** `models/**/*.sql` (model config blocks with materialization)<br>• **Docs:** inline model config comments justifying any override |

## Section 5 — Gold / Marts Modeling

| Skill | Name | Description | Input | Generated artefacts |
|-------|------|-------------|-------|---------------------|
| 5.1 | **Gold/Mart Modeling & Contracts** | Use when designing a new fact or dimension table for a specific consumer area. | 1. What is the business intent? (e.g. "sales funnel analysis", "customer cohort report")<br>2. Who are the consumers of this mart — BI tool, semantic layer, ML pipeline, or direct SQL?<br>3. What is the grain of the primary fact table(s)? (e.g. one row per order line)<br>4. What is the preferred shape — star schema or OBT?<br>5. What are the SLA and freshness requirements for this mart?<br>6. What PK/FK columns are expected, and what naming conventions should they follow?<br>7. What tests and contracts are required at minimum? (e.g. PK uniqueness, not-null, referential integrity) | • **Docs:** `/docs/mart_contract.md`<br>• **YAML:** `models/marts/**/schema.yml` (contracts: descriptions, tests, meta)<br>• **SQL:** `models/_templates/mart_template.sql`<br>• **SQL:** `models/marts/**.sql` (example mart patterns)<br>• **Macros:** `macros/` (shared business logic helpers, if needed) |
| 5.2 | **Metrics Mapping** | Use when defining, registering, or governing business metrics tied to a specific intent. | 1. What are the metric definitions for this intent? (name, formula, grain, filters)<br>2. Is the dbt Semantic Layer being used to serve these metrics to consumers?<br>3. Who owns each metric — which team or individual?<br>4. How should metrics be versioned when their definition changes?<br>5. What is the deprecation process when a metric is retired?<br>6. Where should business logic live — in the dbt model SQL, or in the semantic layer definitions? | • **Docs:** `/docs/metrics_mapping.md`<br>• **Docs:** `/docs/metrics_registry.md` (living catalog)<br>• **YAML:** `metrics.yml` / `semantic_models.yml` (if Semantic Layer used)<br>• **YAML:** `models/**/schema.yml` (`tags`/`meta` conventions)<br>• **SQL:** `models/**.sql` (example metric-supporting models) |

## Section 6 — Business Logic Testing

_Section 6 protects merges/deploys. Section 7 protects production data correctness and publishing._

| Skill | Name | Description | Input | Generated artefacts |
|-------|------|-------------|-------|---------------------|
| 6.1 | **Unit Tests (Business Logic)** | Use when adding or reviewing tests for individual model business rules and column constraints. | 1. What are the key business rules each model must enforce? (e.g. revenue > 0, status must be in an allowed set)<br>2. What test coverage is required per layer or model type? (e.g. all Gold PK columns must have uniqueness + not-null)<br>3. Which test packages are approved for this project? (e.g. dbt_utils, dbt_expectations)<br>4. What fixture or seed strategy should be used? (inline YAML fixtures vs seed CSVs)<br>5. Are there known edge cases or tricky data conditions that must be covered? | • **Docs:** `/docs/testing/unit_tests.md`<br>• **Config:** `packages.yml`<br>• **YAML:** `models/**/schema.yml` (generic tests)<br>• **SQL:** `seeds/**.csv` (fixtures, when applicable)<br>• **Macros:** `macros/tests/**.sql` (custom assertions) |
| 6.2 | **Integration Tests (Cross-model Invariants)** | Use when validating relationships and data consistency across multiple models within the same intent. | 1. Which cross-model relationships are critical to validate for this intent? (e.g. fct_orders → dim_customers)<br>2. What cardinality rules must hold between joined models?<br>3. What reconciliation checks are needed across layers? (e.g. Silver row count ≈ Gold row count after filters)<br>4. What severity should each invariant carry — warn or error?<br>5. What are the known failure modes or edge cases for cross-model joins? | • **Docs:** `/docs/testing/integration_tests.md`<br>• **Config:** `selectors.yml`<br>• **SQL:** `tests/**.sql` (reconciliation, cardinality, multi-model invariants)<br>• **Macros:** `macros/**` (reusable reconciliation/join helpers) |
| 6.3 | **E2E Validation (Pipeline Slice)** | Use when validating the full pipeline from raw source through to final mart output against known reference values. | 1. What are the critical end-to-end journeys to validate? (e.g. raw order → fct_orders → revenue metric)<br>2. Do you have reference datasets or known expected values to compare against?<br>3. What numeric tolerance is acceptable for comparisons? (e.g. ±0.01%)<br>4. In which environments should E2E validation run? (dev, staging, prod)<br>5. How often should E2E validation run — per PR, nightly, or on deploy? | • **Docs:** `/docs/testing/e2e_validation.md`<br>• **Config:** `selectors.yml`<br>• **SQL:** `models/validation/**.sql`<br>• **SQL/YAML:** `tests/**.sql` and `models/validation/**/schema.yml` |
| 6.4 | **Local pre-push & CI Gating** | Use when configuring or updating CI pipelines, pre-push hooks, and local dev quality gates. | 1. What CI platform are you using? (Azure DevOps, GitHub Actions)<br>2. What is your branch strategy? (trunk-based, feature branches, gitflow)<br>3. Which test failures should block a merge, and which should only warn?<br>4. What does the local dev environment require to run CI checks? (Python version, dbt version, credentials approach)<br>5. Are there reproducibility constraints? (e.g. must pass on a clean clone with no local state) | • **Docs:** `README.md` (pre-push + CI commands + troubleshooting)<br>• **Config:** `selectors.yml`<br>• **Config:** CI pipeline definition (`azure-pipelines.yml` or `.github/workflows/dbt_ci.yml`)<br>• **Config:** `Makefile` or task runner<br>• **Config:** `.pre-commit-config.yaml` or git hook script<br>• **Macros:** `macros/ops/**.sql` |

## Section 7 — Data Quality & Observability

| Skill | Name | Description | Input | Generated artefacts |
|-------|------|-------------|-------|---------------------|
| 7.1 | **Core DQ Checks** | Use when implementing data quality checks (freshness, nulls, duplicates, volume anomalies) for a specific intent. | 1. What DQ dimensions matter most for this intent? (freshness, volume anomalies, null rates, duplicates, value drift)<br>2. What thresholds define a DQ failure for each check? (e.g. >5% null rate in a Gold column = error)<br>3. What severity applies to each check — warn (non-blocking) or error (blocks publish)?<br>4. What downstream systems or reports depend on this data? (helps prioritise severity)<br>5. Are you using any DQ tooling? (e.g. elementary, re_data, custom singular tests)<br>6. Should DQ checks run before publishing (pre-publish gate) or after (post-publish monitoring)? | • **Docs:** `/docs/dq/core_checks.md`<br>• **Config:** `dbt_project.yml` (vars, thresholds)<br>• **Config:** `selectors.yml` (`pre_publish_checks`, `post_publish_checks`)<br>• **YAML:** `models/**/schema.yml` (tests + `meta` contract)<br>• **SQL:** `tests/**.sql` (singular DQ checks) |
| 7.2 | **Automated Incident Response** | Use when configuring alerting, quarantine, and escalation workflows triggered by DQ failures. | 1. When a DQ check fails, who should be notified and through which channel? (Slack, email, PagerDuty)<br>2. What automated actions are safe to take on failure? (e.g. quarantine a model, skip a publish step, send alert)<br>3. How should dev failures be handled differently from prod failures?<br>4. Who is on-call and what are the escalation SLAs per severity level?<br>5. What auto-remediation is in scope? (retry, quarantine, rollback, or none) | • **Docs:** `/docs/incident_response.md` (policy + playbooks)<br>• **Config:** `selectors.yml`<br>• **SQL:** `models/quarantine/**.sql`<br>• **Macros:** `macros/ops/**.sql`<br>• **Macros:** `macros/on-run-end.sql` |

---

## Rollout Checklist for a New Organization

### Phase 1 — Run once

- [ ] **4.1** — Define repo structure & layer boundaries → generate `project_standards.md`
- [ ] **4.2** — Set materialization defaults + override policy
- [ ] **8.1** — Enforce metadata & docs standard
- [ ] **8.2** — Set Fabric access control & PII baseline

### Phase 2 — Run per business intent

- [ ] **4.2** — Confirm materialization strategy per model (override project defaults if needed)
- [ ] **5.1** — Establish mart blueprint & contracts
- [ ] **5.2** — Map metrics to dbt models/metrics
- [ ] **6.1** — Implement unit tests for business logic
- [ ] **6.2** — Implement integration tests
- [ ] **6.3** — Implement E2E validations
- [ ] **6.4** — Configure local pre-push and CI gating
- [ ] **7.1** — Implement core DQ checks
- [ ] **7.2** — Implement automated incident response

> **Tip:** Phase 1 produces `project_standards.md` — the always-on context loaded by every Phase 2 skill. Phase 2 skills read this file before generating any artefact. When a new business intent arrives, only Phase 2 is re-run.
