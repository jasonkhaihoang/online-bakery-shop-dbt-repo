# Skill Test Result: `scaffolding-dbt-project-v2`

**Test type:** RED vs GREEN (TDD for skills)
**Skill under test:** `specs/phase1/scaffolding-dbt-project-v2/SKILL.md`
**Domain inputs:** Interview answers (Bronze ownership, Fabric connection, Metadata) — no `domain.md` or `source.md` required

Both agents use `subagent_type: general-purpose` and produce a **plan** (list of artefacts + intended content) — no actual files are written to disk.

---

## Run History Progress

| Date | Run | Rubric | RED | GREEN | Skill delta | Key outcome |
|------|-----|--------|-----|-------|-------------|-------------|
| 2026-03-02 | r1 | 30 checks | **16/30** | **25/30** | **+9** | Skill fixes interview protocol, auth config, project_standards.md, source.md; gaps in meta key names and sqlfluff dialect |
| 2026-03-02 | r2 | 30 checks | **19/30** | **30/30** | **+11** | Post-fix run (garments domain). All 3 gaps from r1 closed. GREEN perfect. RED improved on B01–B03 but still fails interview, dialect, project_standards.md |

---

## Run 1 — 2026-03-02 · 30-check rubric

**Domain:** `finance` · **Source:** `finance_bronze` (`brz_invoices`, `brz_payments`)

| ID  | Group           | Check                                               | RED | GREEN |
|-----|-----------------|-----------------------------------------------------|-----|-------|
| A01 | Interview       | One topic at a time                                 | ❌  | ✅    |
| A02 | Interview       | Summary before generation                           | ❌  | ✅    |
| A03 | Interview       | No model SQL produced                               | ❌  | ✅    |
| B01 | dbt_project.yml | Staging +meta: owner, domain, sla, contains_pii     | ❌  | ❌    |
| B02 | dbt_project.yml | Intermediate +meta: all 4 keys                      | ❌  | ❌    |
| B03 | dbt_project.yml | Mart +meta: all 4 keys                              | ❌  | ❌    |
| B04 | dbt_project.yml | No vars: meta-defaults block                        | ✅  | ✅    |
| B05 | dbt_project.yml | No extra path declarations                          | ✅  | ✅    |
| B06 | dbt_project.yml | Intermediate incremental + merge strategy           | ✅  | ✅    |
| B07 | dbt_project.yml | Staging view / Mart table                           | ✅  | ✅    |
| C01 | profiles.yml    | Adapter is fabric                                   | ✅  | ✅    |
| C02 | profiles.yml    | dev uses Entra ID interactive auth                  | ❌  | ✅    |
| C03 | profiles.yml    | prod uses service principal (env vars)              | ❌  | ✅    |
| C04 | profiles.yml    | Bronze endpoint URL present                         | ✅  | ✅    |
| C05 | profiles.yml    | Silver and Gold endpoint URLs present               | ✅  | ❌    |
| D01 | _source.yml     | File at correct path                                | ✅  | ✅    |
| D02 | _source.yml     | Declares correct bronze tables only                 | ✅  | ✅    |
| D03 | _source.yml     | database/schema matches bronze lakehouse            | ✅  | ✅    |
| E01 | .sqlfluff       | dialect = sparksql                                  | ❌  | ❌    |
| E02 | .sqlfluff       | capitalisation_policy = lower                       | ✅  | ✅    |
| E03 | .sqlfluff       | Trailing comma + explicit aliasing                  | ✅  | ✅    |
| F01 | macro           | generate_schema_name.sql exists                     | ✅  | ✅    |
| F02 | macro           | prod returns schema as-is                           | ✅  | ✅    |
| F03 | macro           | non-prod prefixes with target name                  | ✅  | ✅    |
| G01 | project_stds    | project_standards.md exists                         | ❌  | ✅    |
| G02 | project_stds    | Contains DAG rules                                  | ❌  | ✅    |
| G03 | project_stds    | Contains staging boundary rules                     | ❌  | ✅    |
| G04 | project_stds    | Contains bronze ownership statement                 | ❌  | ✅    |
| H01 | packages.yml    | dbt_utils only (no extra packages)                  | ✅  | ✅    |
| H02 | source.md       | Bronze table inventory produced                     | ❌  | ✅    |

**RED: 16/30 · GREEN: 25/30 · Skill delta: +9**

Checks fixed by skill: A01, A02, A03, C02, C03, G01, G02, G03, G04, H02
Checks still failing with skill: B01, B02, B03, C05, E01
Check regression (RED ✅ → GREEN ❌): C05

---

## Run 2 — 2026-03-02 · 30-check rubric (post-fix)

**Domain:** `garments` · **Source:** `garment_bronze` (`brz_sales_orders`, `brz_products`, `brz_customers`)
**Fixes applied before this run:** `dbt_project.template.yml` (meta keys), `sqlfluff.template.cfg` (dialect default), `profiles.template.yml` (new), `SKILL.md` (Fabric Connection section)

| ID  | Group           | Check                                               | RED | GREEN |
|-----|-----------------|-----------------------------------------------------|-----|-------|
| A01 | Interview       | One topic at a time                                 | ❌  | ✅    |
| A02 | Interview       | Summary before generation                           | ❌  | ✅    |
| A03 | Interview       | No model SQL produced                               | ❌  | ✅    |
| B01 | dbt_project.yml | Staging +meta: owner, domain, sla, contains_pii     | ✅  | ✅    |
| B02 | dbt_project.yml | Intermediate +meta: all 4 keys                      | ✅  | ✅    |
| B03 | dbt_project.yml | Mart +meta: all 4 keys                              | ✅  | ✅    |
| B04 | dbt_project.yml | No vars: meta-defaults block                        | ✅  | ✅    |
| B05 | dbt_project.yml | No extra path declarations                          | ✅  | ✅    |
| B06 | dbt_project.yml | Intermediate incremental + merge strategy           | ✅  | ✅    |
| B07 | dbt_project.yml | Staging view / Mart table                           | ✅  | ✅    |
| C01 | profiles.yml    | Adapter is fabric                                   | ✅  | ✅    |
| C02 | profiles.yml    | dev uses Entra ID interactive auth                  | ❌  | ✅    |
| C03 | profiles.yml    | prod uses service principal (env vars)              | ✅  | ✅    |
| C04 | profiles.yml    | Bronze endpoint URL present                         | ❌  | ✅    |
| C05 | profiles.yml    | Silver and Gold endpoint URLs present               | ✅  | ✅    |
| D01 | _source.yml     | File at correct path                                | ✅  | ✅    |
| D02 | _source.yml     | Declares correct bronze tables only                 | ✅  | ✅    |
| D03 | _source.yml     | database/schema matches bronze lakehouse            | ✅  | ✅    |
| E01 | .sqlfluff       | dialect = sparksql                                  | ❌  | ✅    |
| E02 | .sqlfluff       | capitalisation_policy = lower                       | ✅  | ✅    |
| E03 | .sqlfluff       | Trailing comma + explicit aliasing                  | ✅  | ✅    |
| F01 | macro           | generate_schema_name.sql exists                     | ✅  | ✅    |
| F02 | macro           | prod returns schema as-is                           | ✅  | ✅    |
| F03 | macro           | non-prod prefixes with target name                  | ✅  | ✅    |
| G01 | project_stds    | project_standards.md exists                         | ❌  | ✅    |
| G02 | project_stds    | Contains DAG rules                                  | ❌  | ✅    |
| G03 | project_stds    | Contains staging boundary rules                     | ❌  | ✅    |
| G04 | project_stds    | Contains bronze ownership statement                 | ❌  | ✅    |
| H01 | packages.yml    | dbt_utils only (no extra packages)                  | ✅  | ✅    |
| H02 | source.md       | Bronze table inventory produced                     | ❌  | ✅    |

**RED: 19/30 · GREEN: 30/30 · Skill delta: +11**

Checks fixed by skill: A01, A02, A03, C02, C04, E01, G01, G02, G03, G04, H02
Checks still failing with skill: none
Regressions: none

**RED failure notes (r2):**
- **A01–A03:** Produced full model SQL (`stg_*` × 3, `int_*` × 2, `fct_*`/`dim_*` × 3) with no interview protocol. Phase 1 boundary not respected.
- **C02:** Dev target used `authentication: ServicePrincipal` — not Entra ID interactive.
- **C04:** Bronze endpoint not present in `profiles.yml` at all (appeared in `_source.yml` only).
- **E01:** Used `dialect = tsql`, same reasoning as r1 — "Fabric Warehouse uses T-SQL". No skill to enforce `sparksql` default.
- **G01–G04:** No `project_standards.md` produced.
- **H02:** No `source.md` produced.

**Note on RED B01–B03 improvement:** RED now includes `sla` and `contains_pii` alongside `pii` and `tier` (all 6 keys present). This is likely because the test task prompt explicitly lists these key names — not because RED has internalised the v2 standard. The 4 required keys pass the rubric check, but the presence of stale `pii`/`tier` keys reveals RED is still not following the v2 convention.

---

## Failure Notes (Run 1)

### RED failures (14 checks)

- **A01–A03:** No interview protocol. Went straight to generating artefacts including full model SQL (`stg_*`, `int_*`, `fct_*`, `dim_*`). Phase 1 boundary not respected.
- **B01–B03:** `+meta` in `dbt_project.yml` used `pii: false` and `tier: 3` (v1 key names). Missing `sla` and `contains_pii` entirely.
- **C02:** Used `authentication: environment` for dev target — generic env var auth, not Entra ID interactive.
- **C03:** Used `authentication: environment` without explicitly declaring `client_id`, `client_secret`, `tenant_id` fields.
- **E01:** Used `dialect = tsql`, reasoning that Fabric Warehouse uses T-SQL. Ignored the skill template's default of `sparksql`.
- **G01–G04:** No `project_standards.md` produced at all.
- **H02:** No `source.md` produced.

### GREEN failures (5 checks)

- **B01–B03:** `+meta` in `dbt_project.yml` used `pii: false` and `tier: 3` (v1 key names from the template). Interview specified `sla: "07:00"` and `contains_pii: false`, but the agent followed the `dbt_project.template.yml` reference which still carries v1 key names. `contains_pii` appeared in the user-facing interview question but did not propagate into the template output.
- **C05:** Gold endpoint was documented as a comment/note in `profiles.yml` but not configured as a usable target. RED correctly produced separate `prod_silver` and `prod_gold` targets.
- **E01:** Same failure as RED — chose `tsql` dialect with identical reasoning ("Fabric Warehouse uses T-SQL, not Spark SQL"). The template defaults to `sparksql` but both agents overrode it.

---

## Skill Gaps Identified

| Gap | Failing checks | Fix |
|-----|---------------|-----|
| `dbt_project.template.yml` still uses v1 meta keys (`pii`, `tier`) instead of v2 keys (`sla`, `contains_pii`) | B01, B02, B03 | Update template to use `sla` and `contains_pii`; remove `tier` |
| No guidance on which sqlfluff dialect to default to for Fabric; agents consistently choose `tsql` | E01 | Tighten SKILL.md: state that `sparksql` is the default for Fabric Lakehouse SQL endpoints and is the template default; `tsql` is an explicit opt-in for Warehouse endpoints only |
| Gold endpoint not configured as a write target in profiles | C05 | Add explicit Gold target to `profiles.yml` template or add guidance that Silver and Gold must each appear as a named target |
