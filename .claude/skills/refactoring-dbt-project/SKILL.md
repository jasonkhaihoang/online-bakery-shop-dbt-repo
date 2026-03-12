# Refactoring dbt Project

**Skill Code:** 3.1
**Phase:** Phase 3 — Project Refactoring (optional post-multiple-intents)
**Depends on:** Multiple business intents completed (1.1-2.3)
**Used by:** Standalone, invoked after 3+ business intents

## Purpose

Consolidate and optimize project structure by extracting common patterns observed across multiple business intents and moving repeated settings into shared defaults.

## When to Use

Use this skill when:
- You've completed 3+ business intents and notice repeated patterns in model configs
- Common materialization defaults (table vs view) are replicated across models
- Test configurations and column constraints are repeated across similar models
- You want to reduce config duplication and improve project maintainability
- Preparing for scale: consolidating patterns before adding many more models

**This is optional and runs separately** after multiple business intents complete.

## Input Requirements

Observations from running multiple business intents:
- Patterns identified across models (common materialization defaults, repeated test configs)
- Shared column constraints across domain models
- Naming conventions and structure that can be standardized
- Configuration redundancy to eliminate

Decisions to make:
1. **Patterns to extract** — which configs are repeated and safe to consolidate?
2. **Consolidation strategy** — move to `project_standards.md`, create `_defaults.yml` files, or update `dbt_project.yml`?
3. **Refactoring priority** — which consolidations have the highest impact first?
4. **Testing coverage** — do all models still pass tests after refactoring?
5. **Backwards compatibility** — are we changing anything users depend on?

## Output Artefacts

- **Updated:** `project_standards.md` (with consolidated configs and new defaults documented)
- **Updated:** `dbt_project.yml` (new defaults section, vars, thresholds, model defaults)
- **Created:** `models/**/_defaults.yml` (new shared config files for layer-specific defaults)
- **Docs:** `REFACTORING_HISTORY.md` (version log of all changes with rationale and impact)
- **Updated:** individual model files (simplified by removing redundant configs that now inherit from defaults)

## User Confirmation

After analyzing patterns and before making changes, prompt user to confirm or override:
- Proposed consolidations and which configs to extract
- Consolidation targets (where to store shared configs)
- Impact assessment (which models will be simplified)
- Backwards compatibility concerns

## Implementation Notes

- Always run full `dbt build` after refactoring to ensure all models still work
- Create `_defaults.yml` files at layer level (staging, intermediate, marts) for layer-specific defaults
- Document the rationale for each consolidation in `REFACTORING_HISTORY.md`
- Use version numbering in `REFACTORING_HISTORY.md` to track changes over time
- Keep `project_standards.md` as the source of truth for project conventions
- Test that all models still render correctly with inherited defaults
- Commit refactoring separately from feature work
- Only consolidate truly safe defaults that work across all models (err on the side of caution)
