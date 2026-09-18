---
name: sql-performance
description: This skill should be used when writing, modifying, or reviewing SQL for query performance — .sql files, migrations, query-builder calls, or SQL embedded in C, Go, Rust, or Zig code — "この SQL を最適化して", "クエリのパフォーマンスをレビューして", "N+1 になっていないか見て", or auditing a codebase for slow-query patterns. It resolves the target engine and version (PostgreSQL, MySQL, SQLite) from project evidence, separates statically verifiable cost patterns from EXPLAIN-required ones, and applies a cost-ordered catalog with engine-specific sections and version-gated features, so that recommendations trace to official manuals and never exceed the project's engine version. Do NOT use for schema design — keys, constraints, normalization, data types (a separate sql-schema-design skill owns that) — or for the performance of the application code around a query (performance-patterns owns that).
---

# SQL Performance (engine- and version-aware)

Authority sources: the PostgreSQL manual (Performance Tips, Indexes, Queries chapters), the MySQL Reference Manual (Optimization chapter), and the SQLite documentation (Query Optimizer Overview, EXPLAIN QUERY PLAN, CREATE INDEX, ANALYZE). Do not invent recommendations: every catalog entry below traces to one of these sources.

## Step 0: Resolve the engine baseline (ALWAYS first)

Before writing or recommending any SQL:

1. Identify the engine — PostgreSQL, MySQL, or SQLite — from project evidence, in this order of authority: (a) the database driver or ORM dependency in the build manifest (`Cargo.toml`: `sqlx` features, `diesel` features, `rusqlite`, `tokio-postgres`; `go.mod`: `pgx`, `go-sql-driver/mysql`, `mattn/go-sqlite3`, `modernc.org/sqlite`; C: `libpq`, `libmysqlclient`, `sqlite3.h`); (b) migration tooling configuration (`sqlx` migrations directory, `diesel.toml`, `golang-migrate` file suffixes, Flyway / Liquibase config); (c) `docker-compose.yml` / CI service image tags and connection strings (`postgres://`, `mysql://`, `sqlite:`); (d) dialect markers inside the SQL itself (`$1` placeholders, `RETURNING`, `::type` casts → PostgreSQL; backtick identifiers, `?` placeholders with `ENGINE=InnoDB` → MySQL; `WITHOUT ROWID`, `PRAGMA` → SQLite).
2. Resolve the engine version from the same evidence: an image tag (`postgres:17`, `mysql:8.4`), a CI matrix, a `PRAGMA compile_options` expectation, or the driver's documented minimum. An engine named without a version (`postgres:latest`) pins nothing — record the engine only.
3. State the resolved engine and version in the deliverable — the review report's opening or the write-mode summary. If the engine cannot be identified, say so and restrict recommendations to the engine-common catalog; do not guess a dialect.

Hard rules derived from the baseline:

- **Never recommend a feature introduced strictly after the resolved engine version** as a direct fix. Present it as `[engine-gated]` with the introducing version, and give a within-baseline alternative (or "keep as-is") explicitly.
- **Never apply one engine's cost model to another.** Clustered-primary-key reasoning belongs to MySQL InnoDB; visibility-map reasoning belongs to PostgreSQL; automatic-index reasoning belongs to SQLite. A finding that only holds on one engine names that engine.
- When recommending a change in review, always cite the manual section it rests on so the user can verify it against their engine.

## Catalog coverage and verification

**Catalog coverage: PostgreSQL 18, MySQL 8.4 (LTS) / 9.7, SQLite 3.53.** The catalogs below are verified against the official manuals for these versions. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the resolved engine version is newer than the coverage version above. The catalog is out of date for this project: check the release notes for optimizer and feature changes between the coverage version and the actual version, follow those newer official recommendations now, and tell the user this skill's catalog needs updating (see Maintenance below).
- A feature or its introducing version is **not listed here** AND is **boundary-relevant** — plausibly introduced near the resolved engine version: never trust memory for introducing versions; verify before gating on it. Long-established SQL (`JOIN`, `GROUP BY`, `EXISTS`, `UNION ALL`) needs no verification.
- A catalog entry **conflicts with observed EXPLAIN output**: the planner wins; report the discrepancy.

Verification sources, in order of authority:

1. PostgreSQL: https://www.postgresql.org/docs/current/performance-tips.html (EXPLAIN, planner statistics), https://www.postgresql.org/docs/current/indexes.html (index types, multicolumn, partial, expression, index-only scans), https://www.postgresql.org/docs/current/queries-limit.html, https://www.postgresql.org/docs/release/
2. MySQL: https://dev.mysql.com/doc/refman/8.4/en/optimization.html (WHERE, range, index condition pushdown, ORDER BY, LIMIT, subqueries, InnoDB), https://dev.mysql.com/doc/refman/8.4/en/using-explain.html, https://dev.mysql.com/doc/relnotes/mysql/
3. SQLite: https://www.sqlite.org/optoverview.html, https://www.sqlite.org/eqp.html, https://www.sqlite.org/lang_createindex.html, https://www.sqlite.org/lang_analyze.html, https://www.sqlite.org/chronology.html

**Verification fallback**: if a source is unreachable (offline, sandboxed, restricted), try at most one alternate route, then stop and degrade: prefer a catalog-listed construct; if none fits, state the recommendation with an explicit "unverified" label and the assumed introducing version. Never let unreachable sources block the deliverable or trigger repeated fetch attempts.

## Scope boundary

This skill judges the cost and result-correctness of SQL statements and the index definitions that serve them. It does not own:

- **Schema design** — primary and foreign keys, unique constraints, NOT NULL, data types, normalization, naming. A separate `sql-schema-design` skill owns these; until it exists, report schema observations as out of scope, not as findings. Indexes stay here: whether an index is needed, and its column order, partiality, and covering payload, are decided by the queries it serves. Indexes created implicitly by a primary key or unique constraint are the constraint's consequence and stay with schema design.
- **Application-code cost around the query** — allocations, parsing, connection pooling, serialization. `performance-patterns` owns these. This skill owns the query count and shape the application produces (an N+1 loop is a SQL finding even though the loop is Rust).
- **Running SQL against a live database** — this skill only says which statements are safe to run for measurement (see Measuring). Executing them requires a target the user has confirmed is not production, whatever tool or client is used.

## Evidence tiers

- **[static]**: verifiable by reading the SQL and its call site. Reportable findings at full severity.
- **[measure]**: real, but dependent on data distribution, statistics, or planner choice — index selection, join order, whether a sort spills to disk, whether a partial index is chosen. Report as Notes with the exact `EXPLAIN` to run, unless plan output is available or the structure makes the cost unmistakable (a correlated subquery inside a per-request query is unmistakable; "this index might not be chosen" is not).

Correctness trumps cost: a rewrite that changes the result set is never a performance fix. Two catalog entries below are result-correctness problems disguised as performance patterns (`NOT IN` with NULL, `LIMIT` without a deterministic `ORDER BY`); they carry the `[wrong-result]` tag and outrank every cost finding.

## Locating SQL and judging hotness

SQL lives in `.sql` files, migration directories, and — most often — inside application code: string literals passed to `query`, `execute`, `prepare`, `sqlx::query!`, `db.Query`, `sqlite3_prepare_v2`, and query-builder chains. Grep for `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `WITH`, `CREATE INDEX` (case-insensitive) across the in-scope languages, then read each call site to learn how often the statement runs.

Hotness is judged by call context, exactly as in `performance-patterns`: a statement issued per request, per item, or inside a loop is hot; a one-off migration, a startup query, or an admin script is cold. Apply the catalog at full strength in hot statements; in cold ones, flag only egregious waste (a full-table correlated subquery in a migration that will run against production data).

## Engine-common catalog (cost-ordered)

Address a higher factor before a lower one: removing a query from a loop routinely beats any predicate tuning inside it.

### 1. Query multiplication [static]

- **N+1**: one query to fetch a list, then one query per element (in an application loop, or a lazy-loading ORM association). Replace with a single `JOIN`, a `WHERE key IN (...)` batch, or an `= ANY($1)` array parameter (PostgreSQL).
- **Correlated subquery evaluated per outer row** in `SELECT` list or `WHERE`, where a `JOIN` or a `LATERAL` / derived table computes it once.
- **Same statement issued repeatedly with different literals** where one prepared statement with parameters serves all (also avoids re-parsing; MySQL's insert cost breakdown attributes parsing and sending as separate per-statement costs).

### 2. Non-SARGable predicates [static]

A predicate is SARGable (Search ARGument-able) when the engine can use an index range on the column. These forms defeat the index on every engine unless an expression index exists:

- Function or arithmetic applied to the column: `WHERE lower(email) = $1`, `WHERE created_at + interval '1 day' > now()`, `WHERE YEAR(ts) = 2026`. Move the computation to the parameter side, or add an expression index that matches the query's expression exactly (PostgreSQL: Indexes on Expressions; SQLite: 3.9.0; MySQL: functional key parts in CREATE INDEX).
- Cast on the column, including implicit conversion: MySQL cannot use an index on a string column compared to a number (`WHERE str_col = 1`) because many strings convert to `1` (Type Conversion in Expression Evaluation). Match the literal or parameter type to the column type.
- `LIKE` / `GLOB` with a leading wildcard (`'%term'`). B-tree indexes serve only patterns anchored at the beginning (PostgreSQL Index Types; SQLite LIKE optimization, which additionally requires a literal or parameter right-hand side and compatible collation). PostgreSQL non-C collations need `text_pattern_ops` for `LIKE 'term%'` to use the index.
- Multicolumn index used without its leading column: equality constraints on leading columns, plus one inequality on the next column, bound the scan; a constraint on a later column alone does not (PostgreSQL Multicolumn Indexes; SQLite requires a contiguous prefix). PostgreSQL 18 can skip-scan a low-cardinality leading column, but do not rely on it for a hot query.
- `OR` across different columns: SQLite (OR optimization) and MySQL (Index Merge union) can union separate index lookups only when every `OR` branch is independently indexable; otherwise the statement scans. Rewrite as `UNION ALL` of indexable branches, or accept the scan and say so.

### 3. Over-fetching [static]

- `SELECT *` in a hot statement that uses a few columns: widens row transfer and blocks index-only scans / covering indexes on every engine. Cold code and `SELECT *` immediately mapped to a full struct are accepted.
- Fetching rows to count or test existence in application code. Use `COUNT(*)`, or `EXISTS (SELECT 1 ...)` / `LIMIT 1` for existence.
- `DISTINCT` added to hide a join that multiplies rows. Fix the join (or use `EXISTS`); `DISTINCT` sorts or hashes the whole result to undo the multiplication.
- `UNION` where `UNION ALL` suffices: `UNION` deduplicates via sort or hash; use `ALL` when the branches are disjoint or duplicates are acceptable.

### 4. Sort and pagination cost [static, measure]

- `ORDER BY` not served by an index on a hot statement shows as `Using filesort` (MySQL), `Sort` (PostgreSQL), or `USE TEMP B-TREE FOR ORDER BY` (SQLite). Whether that is worth an index is `[measure]`; that the sort exists is `[static]`. MySQL uses an index for `ORDER BY` only when the sort columns follow the index prefix in consistent direction (descending indexes since 8.0) and are not wrapped in expressions.
- Deep `OFFSET` pagination: "The rows skipped by an OFFSET clause still have to be computed inside the server; therefore a large OFFSET might be inefficient" (PostgreSQL Queries → LIMIT and OFFSET; the same holds on MySQL and SQLite). Recommend keyset pagination (`WHERE (sort_key, id) > ($last_key, $last_id) ORDER BY sort_key, id LIMIT n`) for hot list endpoints.
- `[wrong-result]` `LIMIT` / `OFFSET` without an `ORDER BY` that yields a unique order: "using different LIMIT/OFFSET values to select different subsets of a query result will give inconsistent results unless you enforce a predictable result ordering with ORDER BY" (PostgreSQL SELECT). MySQL documents the same for ties in the sort key: add a tie-breaker column. MySQL 8.4 no longer sorts implicitly on `GROUP BY`; an `ORDER BY` must be explicit.
- Keep `LIMIT n` in the statement next to its `ORDER BY`: MySQL stops sorting as soon as it has the first `n` rows (LIMIT Query Optimization); hoisting the limit into application code forces a full sort and transfer on every engine.

### 5. Set operations and NULL traps [static]

- `[wrong-result]` `NOT IN (subquery)` where the subquery column is nullable: "if there are no equal right-hand values and at least one right-hand row yields null, the result of the NOT IN construct will be null, not true" (PostgreSQL Subquery Expressions; standard SQL, so all engines). Rewrite as `NOT EXISTS`. MySQL additionally cannot convert nullable `NOT IN` to an antijoin (Optimizing IN and EXISTS Subquery Predicates), so the rewrite is also the performance fix.
- `IN (subquery)` and `EXISTS` are both fine — MySQL and PostgreSQL turn them into semijoins; do not rewrite one into the other without plan evidence.
- MySQL: single-table `UPDATE` / `DELETE` with a subquery gets no semijoin or materialization optimization; the manual recommends rewriting as a multi-table `UPDATE` / `DELETE` using a join.

### 6. Write batching [static]

- One `INSERT` per row in a loop: use multi-row `VALUES` (MySQL: "many times faster in some cases"; Optimizing INSERT Statements), `COPY` for bulk loads on PostgreSQL ("almost always faster than using INSERT, even if PREPARE is used"; Populating a Database), and one transaction around the batch on every engine (autocommit per row costs a commit per row).
- Per-row `UPDATE` where one `UPDATE ... WHERE key IN (...)` or an `UPDATE ... FROM` / multi-table update serves.
- After a bulk load, `ANALYZE` (PostgreSQL) / `ANALYZE TABLE` (MySQL) / `PRAGMA optimize` (SQLite) so statistics match the new distribution.

### 7. Index definitions [static reasoning, measure for benefit]

- **Missing index on a foreign-key or join column** used by a hot `JOIN`, `WHERE`, or a `DELETE` cascade: `[static]` when the statement is hot, `[measure]` otherwise.
- **Redundant index**: an index whose columns are a leading prefix of another index on the same table serves nothing the wider one does not (all engines).
- **Wide multicolumn indexes**: "Indexes with more than three columns are unlikely to be helpful unless the usage of the table is extremely stylized" (PostgreSQL Multicolumn Indexes). Column order follows the queries: equality columns first, then the range column, then sort columns.
- **Partial index** (`CREATE INDEX ... WHERE`): recommended when hot queries always carry the same selective predicate (e.g. `WHERE billed IS NOT TRUE`); the query's `WHERE` must imply the index predicate, which a parameterized predicate cannot (PostgreSQL Partial Indexes; SQLite supports partial indexes; MySQL does not — use a generated column plus index instead, `[engine-gated]` reasoning).
- **Covering / index-only scan**: add payload columns with `INCLUDE` (PostgreSQL 11+) or as trailing index columns (MySQL `Using index`, SQLite `USING COVERING INDEX`) only for frequent queries that read few extra narrow columns; "be conservative about adding non-key payload columns to an index, especially wide columns". PostgreSQL index-only scans also need the visibility map mostly set, so they pay off on slowly changing tables.
- **Expression index** to make a factor-2 predicate SARGable when the query cannot be rewritten; state the insert/update cost the index adds.
- Every index recommendation names the statement(s) it serves. An index without a served statement is not a finding.

## Engine-specific sections

### PostgreSQL (coverage 18)

- Index types: B-tree for `<, <=, =, >=, >, BETWEEN, IN, IS NULL`; Hash for `=` only; GIN for arrays / JSONB containment (`@>`, `<@`, `&&`); GiST / SP-GiST for geometric and nearest-neighbor; BRIN for large tables whose values correlate with physical order (Index Types). A `@>` or full-text predicate on a B-tree column is non-SARGable — recommend the matching type.
- `= ANY($1)` with an array parameter replaces dynamically built `IN (...)` lists and keeps one prepared statement.
- `[engine-gated]` `MERGE` (15+) for upsert-with-delete logic; `INSERT ... ON CONFLICT` covers plain upserts on all supported versions.
- Planner statistics are sampled; `EXPLAIN ANALYZE` row estimate vs actual divergence points at stale or missing statistics (Statistics Used by the Planner) — a `[measure]` Note, not a query rewrite.

### MySQL (coverage 8.4 LTS / 9.7, InnoDB)

- Secondary indexes store the primary key columns in every entry; "if the primary key is long, the secondary indexes use more space, so it is advantageous to have a short primary key" (Clustered and Secondary Indexes). Report a long or random primary key as an index-cost observation for the schema skill, not as a finding here.
- Index Condition Pushdown (`Using index condition` in `Extra`) lets the storage engine filter on indexed columns before fetching the row; it does not apply to conditions containing subqueries or stored functions — another reason to keep predicates simple.
- `EXPLAIN` `type` column: `ALL` = full table scan, `index` = full index scan, `range` / `ref` / `eq_ref` = bounded; `Extra`: `Using filesort`, `Using temporary`, `Using index` (covering).
- The manual explicitly discourages rewriting arithmetic for speed at the cost of readability because the optimizer folds constants itself (WHERE Clause Optimization) — do not flag readable arithmetic on the parameter side.

### SQLite (coverage 3.53)

- The planner builds an automatic (transient) index for a join when no suitable index exists and logs `SQLITE_WARNING_AUTOINDEX`; `AUTOMATIC INDEX` in `EXPLAIN QUERY PLAN` on a hot statement means a permanent index is missing.
- `WITHOUT ROWID` (3.8.2+) helps tables with a non-integer or composite primary key and small rows (average under ~1/20 of a page); it hurts tables with a single `INTEGER PRIMARY KEY` or large rows. The manual's own advice: decide near the end of development, by measurement — `[measure]`.
- `PRAGMA optimize` on connection close (short-lived) or periodically (long-lived), and after `CREATE INDEX`; since 3.46.0 it bounds its own work.
- `[engine-gated]` `RETURNING` (3.35.0+) removes the follow-up `SELECT` after an insert.

## Measuring

Plain `EXPLAIN` (PostgreSQL, MySQL) and `EXPLAIN QUERY PLAN` (SQLite) never execute the statement and are safe on any target. `EXPLAIN ANALYZE` executes it: on PostgreSQL wrap data-modifying statements in `BEGIN; ... ROLLBACK;` (Using EXPLAIN); on MySQL `EXPLAIN ANALYZE` runs multi-table `UPDATE` / `DELETE` for real, so never run it on a write. A `SELECT` whose `WITH` clause contains `INSERT` / `UPDATE` / `DELETE` / `MERGE` also writes: PostgreSQL executes data-modifying statements in `WITH` "exactly once, and always to completion" whether or not the outer query reads their output (Queries → WITH Queries), so `EXPLAIN ANALYZE` on such a statement writes too. Run plain `EXPLAIN` only, and only against a target the user has confirmed is not production. SQLite's `EXPLAIN QUERY PLAN` output format is not stable across versions; read it interactively, never parse it in code.

What to read: PostgreSQL `Seq Scan` vs `Index Scan` / `Bitmap` nodes, `rows` estimated vs actual, `Rows Removed by Filter`, `Buffers`; MySQL `type` and `Extra`; SQLite `SCAN` vs `SEARCH`, `USING COVERING INDEX`, `USE TEMP B-TREE`.

## Accepted patterns (do not flag)

- Primary-key or unique-key lookups, however written — they are bounded on every engine.
- `SELECT *` in cold code, in a CTE consumed internally, or mapped to a full-row struct.
- `OFFSET` on a bounded, small result (an admin page over hundreds of rows).
- `DISTINCT` when the result semantics require it, not to hide a join.
- Leading-wildcard `LIKE` when full-text or trigram search is the stated intent or the table is a small lookup table.
- N+1 or per-row writes in a one-off migration or admin script, unless it will run against production-sized data.
- Query shapes the ORM generates for its documented eager-loading paths.

## Review output contract

When the task is a review or audit, structure the report as follows. (Writing new SQL needs no report; the hard rules in Step 0 still apply.)

1. Open with the resolved engine and version (or "engine unresolved" and what was tried).
2. Tag every finding with exactly one of:
   - `[wrong-result]` — the statement returns wrong, incomplete, or non-deterministic rows (NULL-trap `NOT IN`, unordered `LIMIT`). Outranks every cost finding.
   - `[cost]` — a `[static]`-tier avoidable cost on a hot statement, with the catalog factor number.
   - `[measure]` — a plausible cost that needs plan evidence; carries the exact `EXPLAIN` statement to run and what to look for.
   - `[engine-gated]` — a better construct that needs a newer engine version; carries the introducing version and a within-baseline alternative.
3. Every finding cites the manual section it rests on and names the engine when the reasoning is engine-specific.
4. Report prose follows the conversation language; SQL, identifiers, plan-node names, and tags stay in English.
5. When one fix supersedes another (removing an N+1 also removes the non-SARGable predicate inside it), report both and say which fix subsumes which.

## Maintenance (updating this skill for a new engine release)

When asked to update this skill after a new engine release:

1. Read the release notes between the coverage version and the new version for that engine (PostgreSQL release notes; MySQL release notes; SQLite chronology and release history).
2. Add new optimizer behaviors and SQL features with their introducing version; record changed defaults (like MySQL 8.4's `GROUP BY` no longer sorting) separately from new features.
3. Remove nothing that older engine versions may still need — entries are version-tagged so old and new baselines coexist.
4. Bump the coverage line at the top of "Catalog coverage and verification" for that engine only.
5. If the file approaches ~300 lines, move engine-specific detail that hot reviews rarely need to `references/<engine>.md`, keeping the engine-common catalog in this file.
