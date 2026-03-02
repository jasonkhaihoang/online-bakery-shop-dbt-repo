# Phase 3 — Project Refactoring

> Source: https://www.notion.so/8c518ff8c53a49458088d2502926c0b4

_Consolidation. Run after multiple business intents to optimize project structure and extract common patterns._
_Input: patterns observed across multiple business intents + **`project_standards.md`**. Output: consolidated configs + updated artefacts._

---

## Project Refactoring (Optional)

_Use this section to consolidate and optimize project structure based on patterns observed across multiple business intents._

| Skill | Name | Description | Decided by the skill | Input | Generated artefacts |
|-------|------|-------------|----------------------|-------|---------------------|
| 3.1 | **refactoring-dbt-project** — _Consolidate and optimize project structure._ | Use when you've run multiple business intents and want to extract common patterns and consolidate configurations. Moves repeated settings from individual models into shared defaults. | Patterns identified across models (common materialization defaults, repeated test configs, shared column constraints), consolidation strategy, refactoring priority | Confirm or override proposed consolidations. Approve modifications to `project_standards.md` or default YAML files. | • **Updated:** `project_standards.md` (with consolidated configs)<br>• **Updated:** `dbt_project.yml` (with new defaults)<br>• **Updated:** `models/**/_defaults.yml` (new shared config files)<br>• **Docs:** `REFACTORING_HISTORY.md` (version log of all changes with rationale)<br>• **Updated:** individual model files (simplified, redundant configs removed) |

---

## Rollout Checklist

- [ ] **3.1** — Run project refactoring to consolidate patterns (optional)

> **Tip:** Requires `project_standards.md` as context (always loaded). Run after completing multiple business intents to consolidate common patterns.
