# Phase 1 — Scaffolding dbt Project

> Source: https://www.notion.so/8c518ff8c53a49458088d2502926c0b4

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

## Rollout Checklist — Phase 1 (run once)

- [ ] **4.1** — Define repo structure & layer boundaries → generate `project_standards.md`
- [ ] **4.2** — Set materialization defaults + override policy
- [ ] **8.1** — Enforce metadata & docs standard
- [ ] **8.2** — Set Fabric access control & PII baseline
