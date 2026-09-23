---
name: sql-schema-design
description: "Guides PostgreSQL, MySQL, and SQLite schema design in DDL and migrations: primary and foreign keys, constraints, NOT NULL, data types, normalization, naming, and safe schema changes. Query cost and index selection use sql-performance."
---

# SQL Schema Design (engine- and version-aware)

Authority sources: the PostgreSQL manual (Data Definition, Data Types, ALTER TABLE), the MySQL Reference Manual (Data Types, CREATE TABLE, InnoDB Online DDL, Optimizing Data Size), and the SQLite documentation (Datatypes, CREATE TABLE, Foreign Key Support, ALTER TABLE, STRICT Tables). Do not invent recommendations: every catalog entry below traces to one of these sources. Normalization itself comes from relational theory (Codd's normal forms) rather than a vendor manual; the MySQL manual's Optimizing Data Size section is the one vendor statement that endorses third normal form as the default.

## Step 0: Resolve the engine baseline (ALWAYS first)

Before writing or recommending any DDL:

1. Identify the engine — PostgreSQL, MySQL, or SQLite — from project evidence, in this order of authority: (a) the database driver or ORM dependency in the build manifest (`Cargo.toml`: `sqlx` features, `diesel` features, `rusqlite`, `tokio-postgres`; `go.mod`: `pgx`, `go-sql-driver/mysql`, `mattn/go-sqlite3`, `modernc.org/sqlite`; C: `libpq`, `libmysqlclient`, `sqlite3.h`); (b) migration tooling configuration (`sqlx` migrations directory, `diesel.toml`, `golang-migrate` file suffixes, Flyway / Liquibase config); (c) `docker-compose.yml` / CI service image tags and connection strings (`postgres://`, `mysql://`, `sqlite:`); (d) dialect markers inside the DDL itself (`GENERATED ALWAYS AS IDENTITY`, `timestamptz`, `jsonb` → PostgreSQL; backtick identifiers, `ENGINE=InnoDB`, `AUTO_INCREMENT` → MySQL; `WITHOUT ROWID`, `STRICT`, `INTEGER PRIMARY KEY` → SQLite).
2. Resolve the engine version from the same evidence: an image tag (`postgres:17`, `mysql:8.4`), a CI matrix, a `PRAGMA compile_options` expectation, or the driver's documented minimum. An engine named without a version (`postgres:latest`) pins nothing — record the engine only.
3. State the resolved engine and version in the deliverable — the review report's opening or the DDL's accompanying summary. If the engine cannot be identified, say so and restrict recommendations to the engine-common catalog; do not guess a dialect.

Hard rules derived from the baseline:

- **Never recommend a feature introduced strictly after the resolved engine version** as a direct fix. Present it as `[engine-gated]` with the introducing version, and give a within-baseline alternative (or "keep as-is") explicitly.
- **Never apply one engine's storage model to another.** Clustered-primary-key reasoning belongs to MySQL InnoDB; type affinity belongs to SQLite; identity columns and `timestamptz` belong to PostgreSQL. A finding that only holds on one engine names that engine.
- **The project's declared conventions win.** An existing naming scheme, key strategy, or migration tool's DDL style is followed, not replaced; recommend a change to a convention only with a manual citation and only as a separate, clearly labeled proposal.
- When recommending a change in review, always cite the manual section it rests on so the user can verify it against their engine.

## Catalog coverage and verification

**Catalog coverage: PostgreSQL 18, MySQL 8.4 (LTS) / 9.7, SQLite 3.53.** The catalog below is verified against the official manuals for these versions. It is the default checklist; do not re-derive it from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the resolved engine version is newer than the coverage version above. Check the release notes for DDL, data-type, and constraint changes between the coverage version and the actual version, follow those newer official recommendations now, and tell the user this skill's catalog needs updating (see Maintenance below).
- A feature or its introducing version is **not listed here** AND is **boundary-relevant** — plausibly introduced near the resolved engine version: never trust memory for introducing versions; verify before gating on it. Long-established DDL (`PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `DEFAULT`, `DECIMAL`) needs no verification.
- A catalog entry **conflicts with observed engine behavior** (an error message, `SHOW CREATE TABLE`, `\d`, or `.schema` output): the engine wins; report the discrepancy.

Verification sources, in order of authority:

1. PostgreSQL: https://www.postgresql.org/docs/current/ddl.html (constraints, identity and generated columns, ALTER TABLE), https://www.postgresql.org/docs/current/datatype.html (numeric, character, date/time, JSON, enum, UUID), https://www.postgresql.org/docs/current/sql-altertable.html, https://www.postgresql.org/docs/release/
2. MySQL: https://dev.mysql.com/doc/refman/8.4/en/data-types.html, https://dev.mysql.com/doc/refman/8.4/en/create-table.html (constraints, foreign keys, generated columns), https://dev.mysql.com/doc/refman/8.4/en/innodb-online-ddl-operations.html, https://dev.mysql.com/doc/refman/8.4/en/data-size.html, https://dev.mysql.com/doc/relnotes/mysql/
3. SQLite: https://www.sqlite.org/datatype3.html, https://www.sqlite.org/lang_createtable.html, https://www.sqlite.org/foreignkeys.html, https://www.sqlite.org/lang_altertable.html, https://www.sqlite.org/stricttables.html, https://www.sqlite.org/chronology.html

**Verification fallback**: if a source is unreachable (offline, sandboxed, restricted), try at most one alternate route, then stop and degrade: prefer a catalog-listed construct; if none fits, state the recommendation with an explicit "unverified" label and the assumed introducing version. Never let unreachable sources block the deliverable or trigger repeated fetch attempts.

## Scope boundary

This skill judges what a table definition allows the database to store: keys, foreign keys, constraints, nullability, data types, normalization, naming, and how a schema change is applied. It does not own:

- **Query cost and index selection** — which indexes exist beyond those a primary key or unique constraint creates implicitly, their column order, partiality, and covering payload. `sql-performance` owns these, because they are decided by the queries an index serves. The one exception stays here: a foreign key's referencing columns need an index for integrity checks (catalog factor 2), and this skill says so with the manual's own wording.
- **Statement shape** — N+1 loops, non-SARGable predicates, pagination, batching. `sql-performance`.
- **Application code around the schema** — ORM model layout, repository boundaries, serialization. `architecture-patterns` and `performance-patterns` own those.
- **Running DDL against a live database** — this skill produces and reviews DDL text. Executing it needs a target the user has confirmed is not production, and any tool that runs it (such as the `rdb-mcp` skill) applies its own confirmation discipline for write and DDL statements.

## Evidence tiers

- **[static]**: verifiable by reading the DDL and the manual. Reportable findings at full severity — a nullable foreign key column with no stated reason, a floating-point money column, a `CHECK` constraint on a MySQL version that ignores it.
- **[requirement]**: correct only under a business rule the code or documentation must establish — whether an email must be unique, whether a column may legitimately be empty, whether history rows must survive a parent's deletion. Report as a question with the constraint that would encode each answer; do not pick the answer for the user unless the code already does (a `NOT NULL` assumption in every reader is evidence).

Integrity trumps convenience: a definition that lets the database accept data the application treats as impossible is the highest-severity finding in this skill, and carries the `[integrity]` tag (catalog factors 1–4). Type and naming findings never outrank it.

## Locating schema definitions

Schema lives in migration directories (`migrations/`, `db/migrate/`, `sql/`, `schema.sql`, `*.up.sql`), ORM model definitions that generate DDL (`diesel` `schema.rs` and migrations, `sqlx` migration files, Go `ent` / `gorm` structs with tags), and embedded `CREATE TABLE` strings in application code (common in SQLite projects). Read the whole migration history for a table before judging its current shape: a later migration may already have added the constraint a first migration lacks. Report against the effective schema, and name the migration that should carry the fix.

## Engine-common catalog (severity-ordered)

Address a higher factor before a lower one: a missing foreign key matters more than a column name, and a wrong numeric type matters more than a missing `CHECK`.

### 1. Primary keys [static, integrity]

- **Every table declares a primary key.** MySQL InnoDB clusters rows on the primary key; without one it uses the first `UNIQUE NOT NULL` index, and failing that a hidden 6-byte `GEN_CLUST_INDEX` that no query can use (Clustered and Secondary Indexes). PostgreSQL and SQLite accept keyless tables, but replication tools, ORMs, and `UPDATE` / `DELETE` of a single row all need a row identity.
- **Surrogate key type follows the engine.** PostgreSQL: `bigint GENERATED ALWAYS AS IDENTITY` (identity columns are SQL standard, introduced in PostgreSQL 10; `serial` is "merely a notational convenience" for the older sequence-plus-default pattern). MySQL: `BIGINT UNSIGNED AUTO_INCREMENT` or `INT` when the row count is bounded; keep it short, because "primary key columns are duplicated in each secondary index entry" (Optimizing Data Size). SQLite: `INTEGER PRIMARY KEY` is an alias for the rowid and needs no `AUTOINCREMENT` — that keyword "imposes extra CPU, memory, disk space, and disk I/O overhead and should be avoided if not strictly needed" (Autoincrement); use it only when rowids must never be reused. `INTEGER PRIMARY KEY DESC` is not a rowid alias (a retained historical quirk).
- **`integer` versus `bigint`**: a 4-byte integer key overflows at 2,147,483,647. Flag a 4-byte key on a table whose growth the code implies is unbounded (events, logs, messages); accept it on lookup and configuration tables.
- **Random UUID keys** spread inserts across the whole key space, which costs most on MySQL's clustered index and on any secondary index that embeds the primary key. When distributed generation is the requirement, prefer a time-ordered UUID: PostgreSQL 18 adds `uuidv7()` (`[engine-gated]`, 18+); MySQL's `UUID_TO_BIN(uuid, 1)` swaps the time-low field forward for `BINARY(16)` storage. Otherwise keep the integer key and give the UUID a `UNIQUE` column of its own.
- **Composite primary keys** suit pure junction tables (`(post_id, tag_id)`) and nothing else that other tables reference: every referencing table would have to repeat all columns. SQLite: a composite or non-integer primary key is the case the manual names for `WITHOUT ROWID` (3.8.2+), provided rows stay small (about 1/20 of a page); measure before adopting it.
- SQLite quirk `[static, integrity]`: in an ordinary rowid table, "SQLite allows NULL values in a PRIMARY KEY column" unless the column is `INTEGER PRIMARY KEY`, declared `NOT NULL`, or the table is `WITHOUT ROWID` or `STRICT` (CREATE TABLE). Add `NOT NULL` to every non-integer primary key column.

### 2. Foreign keys [static, integrity]

- **Declare every relationship the application relies on.** A join column without a `FOREIGN KEY` lets orphan rows in; "an application without a database-level constraint" is a `[requirement]` question only when the referenced table lives in another database or service.
- **Index the referencing columns.** PostgreSQL: "the declaration of a foreign key constraint does not automatically create an index on the referencing columns", yet a parent `DELETE` or key `UPDATE` "will require a scan of the referencing table" (Foreign Keys) — so the index is an integrity-check cost, not only a query cost. SQLite: the same, and the manual recommends the index explicitly (Foreign Key Support). MySQL creates the index automatically when none exists (FOREIGN KEY Constraints). Which index shape serves the application's queries is `sql-performance`'s call; that one exists is this skill's.
- **Match the types exactly.** MySQL: "the size and sign of fixed precision types such as INTEGER and DECIMAL must be the same", and character columns need the same character set and collation. PostgreSQL 18 additionally requires deterministic (or identical nondeterministic) collations on both sides. A `INT` child referencing a `BIGINT UNSIGNED` parent is a `[static]` finding.
- **Choose the referential action deliberately.** `NO ACTION` is the default everywhere; `CASCADE` deletes children silently and belongs only where the child has no meaning without its parent (line items of an order); `SET NULL` needs a nullable column and a reader that handles it; `RESTRICT` makes the dependency explicit. MySQL InnoDB rejects `SET DEFAULT` and treats `NO ACTION` as `RESTRICT`. Flag `CASCADE` on a relationship the code treats as historical (audit rows, ledgers) as `[integrity]`.
- **SQLite enforcement is off by default**: "foreign key constraints are disabled by default" and must be enabled with `PRAGMA foreign_keys = ON` on every connection (Foreign Key Support). A schema with foreign keys but no evidence of that pragma at connection setup is a `[static, integrity]` finding against the application's connection code. The parent key must be a `PRIMARY KEY` or `UNIQUE` constraint or index.
- MySQL: foreign keys exist only on InnoDB (and NDB); parent and child must use the same storage engine, and neither may be temporary.

### 3. NOT NULL and CHECK [static, integrity]

- **Default to `NOT NULL`; allow `NULL` only where absence has a meaning the code handles.** MySQL: "Declare columns to be NOT NULL if possible" (Optimizing Data Size). PostgreSQL: an explicit not-null constraint "is more efficient" than `CHECK (col IS NOT NULL)` (Constraints). A nullable column read everywhere with `.unwrap()` / a nil check that panics is `[static]`; a nullable column with no reader evidence is `[requirement]`.
- **`CHECK` encodes single-row domain rules**: positive quantities, a status drawn from a fixed set, `end_at > start_at`. PostgreSQL "does not support CHECK constraints that reference table data other than the new or updated row"; cross-row and cross-table rules need `UNIQUE`, `EXCLUDE`, or `FOREIGN KEY` (Constraints). MySQL forbids subqueries, other tables, `AUTO_INCREMENT` columns, stored functions, and nondeterministic functions in `CHECK` (CHECK Constraints).
- **`CHECK` passes on NULL** on every engine (PostgreSQL: "satisfied if the check expression evaluates to true or the null value"; SQLite: a violation occurs only when the expression is zero). A `CHECK` on a nullable column does not force a value — pair it with `NOT NULL` when the rule must always hold.
- **MySQL version gate**: before 8.0.16, `CHECK (expr)` was "parsed and ignored". On an older baseline a `CHECK` is documentation, not enforcement — flag it `[static, integrity]` and offer a trigger or application check as the within-baseline alternative.
- **`NOT ENFORCED` is documentation.** MySQL accepts `CHECK ... NOT ENFORCED`; PostgreSQL 18 accepts `NOT ENFORCED` on `CHECK` and foreign keys and `NOT VALID` on `NOT NULL`. Either is acceptable as a migration step (add now, validate later) and a finding when left permanent.
- PostgreSQL 18 `[engine-gated]`: `NOT NULL` constraints are stored in `pg_constraint` and can be named; on older versions a `NOT NULL` has no name and cannot be dropped by name.

### 4. UNIQUE constraints [static / requirement, integrity]

- **Encode every business identity**: a login email, an external ID, a slug, the `(parent_id, position)` pair of an ordered child. A uniqueness check done only in application code races under concurrent inserts; the constraint is the only safe form. Whether a given column is an identity is `[requirement]` unless the code already assumes it (a lookup that expects at most one row is evidence).
- **NULLs are distinct by default**: two rows with `NULL` in a unique column both pass, on every engine. PostgreSQL 15+ offers `UNIQUE NULLS NOT DISTINCT` (`[engine-gated]`); elsewhere, make the column `NOT NULL` or express the rule with a generated column or a partial index (PostgreSQL, SQLite) that `sql-performance` shapes.
- **A unique constraint creates its index implicitly** ("Adding a unique constraint will automatically create a unique B-tree index" — PostgreSQL; SQLite's `sqlite_autoindex_*`; MySQL's unique key). Do not recommend a second index on the same columns; do report a unique constraint on a wide column set as a storage observation for `sql-performance`.
- PostgreSQL only: **exclusion constraints** (`EXCLUDE USING gist (room WITH =, during WITH &&)`) enforce "no two rows overlap"; PostgreSQL 18 adds temporal `PRIMARY KEY` / `UNIQUE ... WITHOUT OVERLAPS` and `FOREIGN KEY ... PERIOD` (`[engine-gated]`, 18+). Recommend them wherever the code checks for overlapping ranges before inserting.

### 5. Data types [static]

Choose the narrowest type that holds every valid value exactly; "use the most efficient (smallest) data types possible" (MySQL Optimizing Data Size) applies to all three engines' storage and index size.

- **Money and exact quantities**: `numeric` / `DECIMAL(p, s)` — "especially recommended for storing monetary amounts and other quantities where exactness is required" (PostgreSQL Numeric Types); MySQL `DECIMAL` holds up to 65 digits. `real`, `double precision`, `FLOAT`, `DOUBLE` are approximations and a `[static]` finding on any money, price, tax, or balance column. PostgreSQL's `money` type is locale-sensitive (`lc_monetary`) and may not restore into a database with another setting; prefer `numeric`.
- **Integers**: pick the width from the value range (`smallint` for enumerations and small counters, `integer` by default, `bigint` for identifiers and counters that can exceed 2^31). MySQL: `UNSIGNED` doubles the positive range but must match on both sides of a foreign key. SQLite stores all integers in one 8-byte class and ignores the declared width.
- **Strings**: PostgreSQL — "In most situations `text` or `character varying` should be used"; `character(n)` is blank-padded and "usually the slowest of the three" (Character Types). A `varchar(n)` length is a domain rule, not an optimization; use it when a maximum is a real constraint (an ISO country code), not as a habit. MySQL — `VARCHAR(n)` with `n` sized to the domain, character set `utf8mb4` (the 8.0+ server default with collation `utf8mb4_0900_ai_ci`); `utf8mb3` / `utf8` are deprecated. SQLite — declared lengths are ignored ("SQLite does not impose any length restrictions"); a `CHECK (length(col) <= n)` or a `STRICT` table is the only enforcement.
- **Date and time**: PostgreSQL — use `timestamp with time zone` (`timestamptz`) for instants; bare `timestamp` is `without time zone` per the SQL standard, and `time with time zone` is "not recommended" (Date/Time Types). MySQL — `TIMESTAMP` ends at `2038-01-19 03:14:07` UTC and is converted through the session time zone, `DATETIME` runs to 9999 and is stored as-is (Date and Time Types); `TIMESTAMP` on any date that can exceed 2038 (expiry, contract end) is `[static]`. SQLite — there is no date storage class; store ISO-8601 `TEXT` or Unix-time `INTEGER` and use one representation per project.
- **Booleans**: PostgreSQL `boolean`; MySQL `BOOL` is `TINYINT(1)` with no enforcement beyond a `CHECK (flag IN (0, 1))`; SQLite stores 0 and 1 as integers. Flag `'Y'` / `'N'` and `'true'` / `'false'` string columns.
- **Enumerations**: PostgreSQL `ENUM` values can be added (`ALTER TYPE ... ADD VALUE`) but "existing values cannot be removed" and their order is fixed at creation; MySQL `ENUM` must not use numbers as values ("we strongly recommend that you do not") and changing the set is an `ALTER TABLE`. A lookup table with a foreign key, or a `text` column plus `CHECK (status IN (...))`, keeps the set editable in a migration; prefer it when the set changes with the product.
- **JSON**: PostgreSQL — "most applications should prefer to store JSON data as `jsonb`"; keep documents small because "any update acquires a row-level lock on the whole row" (JSON Types). MySQL — the `JSON` type validates input; index a path through a generated column. SQLite — JSON is ordinary `TEXT` (functions built in since 3.38.0); the 3.45.0 `JSONB` BLOB format is SQLite-specific and not PostgreSQL's. A JSON column holding fields the application filters, joins, or updates individually is a normalization finding (factor 6), not a type choice.
- **Generated columns** express a derived value once: PostgreSQL 12+ (`STORED`; 18 adds `VIRTUAL` and makes it the default — `[engine-gated]`), MySQL (`VIRTUAL` default, `STORED` for a fully indexable column; InnoDB indexes virtual columns only as secondary indexes), SQLite 3.31.0+ (`ADD COLUMN` accepts `VIRTUAL` only). Expressions must be deterministic and may not use subqueries on any engine.
- **Defaults**: use constant defaults or the engine's clock (`now()`, `CURRENT_TIMESTAMP`); a default that the application also always supplies is harmless, a default that hides a missing value (`DEFAULT ''`, `DEFAULT 0` on a foreign key) is `[integrity]`. MySQL 8.0+ persists the `AUTO_INCREMENT` counter across restarts; gaps after rollbacks are normal on every engine and never a finding.
- **SQLite typing**: a declared type only sets an affinity (`INT` → INTEGER, `CHAR` / `CLOB` / `TEXT` → TEXT, `BLOB` or none → BLOB, `REAL` / `FLOA` / `DOUB` → REAL, otherwise NUMERIC — so `BOOLEAN`, `DATE`, and `DECIMAL` are NUMERIC); the column still accepts any storage class. `STRICT` tables (3.37.0+) reject mismatched values and allow only `INT`, `INTEGER`, `REAL`, `TEXT`, `BLOB`, `ANY`. Recommend `STRICT` for new tables within baseline; on older baselines, a `CHECK (typeof(col) = 'integer')` is the alternative.

### 6. Normalization [static / requirement]

- **Third normal form is the default**: "keep data nonredundant" and "use unique IDs instead of repeating lengthy values" (MySQL Optimizing Data Size). Each non-key column depends on the key, the whole key, and nothing but the key.
- **Repeating groups and lists in one column** — `tags TEXT` holding `'a,b,c'`, `phone1` / `phone2` / `phone3`, a JSON array the application searches — become a child table (or, on PostgreSQL, an array column only when the elements are never joined or constrained individually).
- **Copied attributes** (`orders.customer_name` next to `orders.customer_id`) are a finding unless the copy is intentional history (a price at time of purchase) — then name the column for what it is (`unit_price_at_purchase`) and treat it as immutable.
- **Polymorphic references** (`owner_type` + `owner_id`) cannot be enforced by a foreign key on any engine. Report them as `[requirement]`: either one nullable foreign key column per target with a `CHECK` that exactly one is set, or an explicit statement that integrity is application-owned.
- **Denormalization is a stated trade**: accepted when a read path justifies it and the schema shows how the copy stays current (a generated column, a trigger, or a documented application owner). The MySQL manual's own exception is business-intelligence workloads that "prioritize speed over disk space".
- **Wide tables with optional column groups** that are always null together (`shipping_*` filled only for physical goods) are a candidate for a one-to-one child table; flag as `[requirement]` with the group named.

### 7. Naming [static]

- **Follow the project's existing convention first**; a review reports inconsistency within the project, not disagreement with a preferred style. Absent a convention: lowercase `snake_case` for every identifier, singular or plural table names used consistently, `<table>_id` for foreign key columns, and explicit constraint names (`<table>_<column>_fkey`, `<table>_<columns>_key`, `<table>_<rule>_check`) so migrations can drop them by name.
- **Case folding differs by engine**: PostgreSQL folds unquoted identifiers to lower case and quoted ones are case-sensitive, so a quoted mixed-case name forces quoting forever; MySQL table and database names follow the file system and `lower_case_table_names`, and the manual recommends "always creating and referring to databases and tables using lowercase names"; column names are case-insensitive on every engine.
- **Length limits**: PostgreSQL truncates identifiers to 63 bytes (`NAMEDATALEN` − 1); MySQL allows 64 characters, and auto-generated constraint names (`<table>_ibfk_N`, `<table>_chk_N`) derived from a long table name can exceed it. Flag generated names on long tables.
- **Reserved words** (`user`, `order`, `group`, `key`) as unquoted table or column names force quoting in every statement; recommend `users`, `orders`, `user_group` before the first migration ships, and accept them afterwards with a note.

### 8. Schema-change safety [static, migration]

A correct target schema reached by a migration that locks or rewrites a large table is still a finding. Judge each `ALTER` by what the engine does with it:

- **PostgreSQL**: "Adding a column with a constant default value does not require each row of the table to be updated" (ALTER TABLE; fast since PostgreSQL 11), but a volatile default such as `clock_timestamp()` rewrites every row — add the column without the default, backfill, then set the default. Changing a column's type "requires a full table rewrite". Add `CHECK` and foreign key constraints as `NOT VALID` and run `VALIDATE CONSTRAINT` separately so existing rows are checked without a long exclusive lock; PostgreSQL 18 allows `NOT NULL ... NOT VALID` the same way (`[engine-gated]`).
- **MySQL InnoDB**: `ADD COLUMN` and `DROP COLUMN` are `ALGORITHM=INSTANT` by default (adding since 8.0.12, at any position and dropping since 8.0.29), as are renaming a column without changing its type or nullability and setting a literal default. Each instant add or drop consumes a row version, capped at 64 (255 as of 9.1.0); at the cap the table must be rebuilt. Changing a data type is `ALGORITHM=COPY` only; adding a primary key, converting the character set, reordering columns, and switching a column between `NULL` and `NOT NULL` rebuild the table (Online DDL Operations). State the algorithm in the migration when it matters.
- **SQLite**: `ALTER TABLE` supports only rename table, rename column (3.25.0+), `ADD COLUMN`, and `DROP COLUMN` (3.35.0+). `ADD COLUMN` cannot add `PRIMARY KEY` or `UNIQUE`, cannot use `CURRENT_TIMESTAMP` or an expression as the default, and needs a non-NULL default for a `NOT NULL` column; `DROP COLUMN` refuses indexed, constrained, or referenced columns. Everything else is the manual's twelve-step rebuild (disable foreign keys, create the new table, copy, drop, rename, recreate indexes / triggers / views, `PRAGMA foreign_key_check`, commit, re-enable) — a migration that skips the foreign-key steps or runs outside a transaction is `[static]`.
- **Every engine**: a `NOT NULL` added to an existing column needs a backfill first; a shrinking type change (`bigint` → `integer`, `VARCHAR(255)` → `VARCHAR(50)`) needs a `[requirement]` confirmation that no stored value exceeds the new range; dropping a column that older application versions still write is a deploy-order question, reported as `[migration]`.

## Engine-specific reminders

### PostgreSQL (coverage 18)

- Prefer `bigint GENERATED ALWAYS AS IDENTITY`, `text`, `timestamptz`, `numeric`, `jsonb`, `boolean`; `serial`, `char(n)`, `timestamp`, `money`, `json` each have a catalog entry above explaining why not.
- `GENERATED ALWAYS` rejects explicit values unless `OVERRIDING SYSTEM VALUE` is given; `GENERATED BY DEFAULT` lets an explicit value win. Neither guarantees uniqueness — the primary key does.
- Exclusion and temporal constraints, `NULLS NOT DISTINCT` (15+), virtual generated columns (18), named `NOT NULL` and `NOT ENFORCED` (18), `uuidv7()` (18) are version-gated as marked above.

### MySQL (coverage 8.4 LTS / 9.7, InnoDB)

- Every table gets an explicit short primary key; secondary indexes embed it. `AUTO_INCREMENT` gaps are normal; the counter persists across restarts since 8.0.
- `utf8mb4` everywhere; `TIMESTAMP` only for values guaranteed before 2038; `DECIMAL` for money; `CHECK` enforced from 8.0.16; `SET DEFAULT` referential action rejected; foreign keys need InnoDB.
- Instant DDL for column add/drop/rename/default; type changes and primary-key changes rebuild.

### SQLite (coverage 3.53)

- `INTEGER PRIMARY KEY` without `AUTOINCREMENT`; `NOT NULL` on every other primary key column; `STRICT` (3.37.0+) for new tables; one date representation per project.
- `PRAGMA foreign_keys = ON` on every connection, or the foreign keys are decoration.
- `WITHOUT ROWID` only for composite or non-integer keys with small rows; schema changes beyond rename/add/drop go through the twelve-step rebuild.

## Accepted patterns (do not flag)

- Nullable columns whose absence is a documented state the readers handle (`deleted_at`, `parent_id` on a root).
- Intentional historical copies named as such (`unit_price_at_purchase`), and read models or summary tables with a documented refresh mechanism.
- JSON columns for genuinely schemaless payloads the application never filters or updates field by field (webhook bodies, user preferences blobs).
- UUID keys where distributed or client-side generation is a stated requirement, with the index-size cost acknowledged.
- Missing foreign keys to tables owned by another database or service, when the boundary is stated.
- Natural primary keys on small, stable lookup tables (ISO codes, currency codes).
- `TIMESTAMP` in MySQL for creation and update audit columns, which stay within range for the life of the product.
- SQLite schemas that predate `STRICT` on a baseline below 3.37.0, or that document their reliance on affinity.
- A project-wide naming convention that differs from the default above, applied consistently.

## Review output contract

When the task is a review or audit, structure the report as follows. (Writing new DDL needs no report; the hard rules in Step 0 still apply, and the DDL names every constraint explicitly.)

1. Open with the resolved engine and version (or "engine unresolved" and what was tried), and the migration files or model definitions read.
2. Tag every finding with exactly one of:
   - `[integrity]` — the definition admits data the application treats as impossible (missing key, missing or unenforced constraint, wrong nullability, cascade that destroys history). Outranks every other tag.
   - `[type]` — a data type that loses precision, range, or meaning (float money, `TIMESTAMP` past 2038, `char(n)`, string booleans).
   - `[normalization]` — redundancy or a multi-valued column without a stated read-path reason.
   - `[naming]` — inconsistency with the project's convention, quoting hazards, or length-limit risks.
   - `[migration]` — an `ALTER` that rewrites, locks, or cannot be applied on the resolved engine, or a change whose deploy order matters.
   - `[requirement]` — a design choice that depends on a business rule not evidenced in the code; carries the question and the constraint that would encode each answer.
   - `[engine-gated]` — a better construct that needs a newer engine version; carries the introducing version and a within-baseline alternative.
3. Every finding cites the manual section it rests on and names the engine when the reasoning is engine-specific.
4. Report prose follows the conversation language; SQL, identifiers, type names, and tags stay in English.
5. When one fix supersedes another (moving a list column into a child table also removes the `CHECK` that parsed it), report both and say which fix subsumes which.

## Maintenance (updating this skill for a new engine release)

When asked to update this skill after a new engine release:

1. Read the release notes between the coverage version and the new version for that engine (PostgreSQL release notes; MySQL release notes; SQLite chronology and release history).
2. Add new DDL features, data types, and constraint options with their introducing version; record changed defaults (like PostgreSQL 18 making generated columns virtual by default) separately from new features.
3. Remove nothing that older engine versions may still need — entries are version-tagged so old and new baselines coexist.
4. Bump the coverage line at the top of "Catalog coverage and verification" for that engine only, and keep it in step with `sql-performance` when both skills are updated together.
5. If the file approaches ~300 lines, move engine-specific detail that reviews rarely need to `references/<engine>.md`, keeping the engine-common catalog in this file.
