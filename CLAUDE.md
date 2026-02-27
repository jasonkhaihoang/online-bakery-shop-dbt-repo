# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All dbt commands use the local `.venv`:

```bash
# Debug connection
.venv/bin/dbt debug

# First-ever run (seeds must precede staging — see note below)
.venv/bin/dbt seed && .venv/bin/dbt build

# Subsequent full builds
.venv/bin/dbt build

# Single model + its tests
.venv/bin/dbt build --select stg_bakery__customers

# Tests only
.venv/bin/dbt test

# Install packages
.venv/bin/dbt deps
```

**Seed-first on first run:** Staging models use `source()` so dbt has no DAG dependency on seeds. Postgres rejects `CREATE VIEW` when referenced tables don't yet exist, causing staging to fail if seeds lose the race. On subsequent runs (seeds already loaded), `dbt build` alone is safe.

## Project Config

- **dbt project**: `bakery_sales` | **profile**: `bakery_shop`
- **Adapter**: Postgres (`172.26.48.1:5432`, db `bakery`)
- **Default target**: `dev`
- **Packages**: `dbt-labs/dbt_utils >=1.0.0,<2.0.0`

## File Operations

This repo runs on **Windows with WSL bash**. Follow these rules for all file operations:

- **Always use absolute Windows paths** with the `Write` and `Edit` tools — e.g. `c:\Users\ADMIN\github\online-bakery-shop-dbt-repo\path\to\file.md`. Relative paths are resolved by WSL as `/mnt/c/...` and cause ENOENT errors.
- **Never use `touch`, `cp`, or shell redirects** to create or modify files — use `Write` and `Edit` tools only.
- **To create a new directory**, use `mkdir` via Bash first (`mkdir -p /mnt/c/Users/ADMIN/github/online-bakery-shop-dbt-repo/path/to/dir`), then write files into it with `Write` using the absolute Windows path. The `Write` tool cannot create directories.

## Skills

This repo has a custom skill `scaffolding-dbt-project` (`.claude/skills/scaffolding-dbt-project/`) covering conventions for scaffolding, model placement, naming, DAG compliance, and config templates.

Invoke it via the `Skill` tool when scaffolding new domains, placing new models, or checking naming/DAG compliance.

## Skill Evaluation

Skill evaluations live in `.claude/skills-evaluation/{skill-name}/`. Each folder contains:
- `evaluation-steps.md` — how to run the RED vs GREEN comparison (rubric + test task)
- `evaluation-results.md` — historical run results

To evaluate whether a skill is working, invoke `superpowers:dispatching-parallel-agents` and follow the instructions in the relevant `evaluation-steps.md`.
