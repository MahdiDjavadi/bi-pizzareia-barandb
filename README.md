# BaranDb: OLTP Source Profiling

Source profiling of a restaurant OLTP database (SQL Server backup): schema discovery, relationship discovery, grain, and data-quality findings.

**Status:** in progress. No data is published; every number in this repo is an aggregate.

## How to read this repo
- `sql/discovery/`: one read-only SQL file per test (T01, T02, ...)
- `docs/tests/`: one write-up per test (Goal, Result, Interpretation, Decision)
- `docs/query-index.md`, `docs/findings-log.md`, `docs/decisions.md`

Labels: P = project phase, S = source-assessment stage, T = discovery test.