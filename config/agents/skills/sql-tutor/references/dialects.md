# Dialect Differences: MySQL, PostgreSQL, SQLite

Read this file only when the question touches a construct that is not
portable across the three engines, or when you need the exact wording
of an engine's error message. Portable standard SQL needs none of it.

## Syntax and semantics

| Topic | MySQL | PostgreSQL | SQLite |
|---|---|---|---|
| Row limit | `LIMIT n` | `LIMIT n`; standard `FETCH FIRST n ROWS ONLY` | `LIMIT n` |
| Auto-increment key | `AUTO_INCREMENT` | `GENERATED ALWAYS AS IDENTITY` (`SERIAL` is legacy) | `INTEGER PRIMARY KEY` |
| String concatenation | `CONCAT(a, b)`; `\|\|` is logical OR by default | `a \|\| b` | `a \|\| b` |
| Identifier quoting | backticks; `"` only with `ANSI_QUOTES` | `"name"` | `"name"` |
| Double-quoted string | accepted as a string by default | identifier, never a string | identifier, string as a fallback |
| Boolean | `BOOLEAN` is `TINYINT(1)` | true `boolean` type | integers `0` / `1` |
| Type strictness | many implicit conversions | strict | type affinity: column type is a hint |
| Integer division | `7 / 2 = 3.5` | `7 / 2 = 3` | `7 / 2 = 3` |
| Non-aggregated column with `GROUP BY` | error under `ONLY_FULL_GROUP_BY` (default) | error | accepted, arbitrary row |
| Rows from a write | not supported | `RETURNING` | `RETURNING` (3.35+) |
| Upsert | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT (...) DO UPDATE` | `ON CONFLICT (...) DO UPDATE` |
| Case in `=` comparison | insensitive by default collation | sensitive | sensitive; `COLLATE NOCASE` for ASCII |
| Show the plan | `EXPLAIN` | `EXPLAIN` | `EXPLAIN QUERY PLAN` |
| DDL inside a transaction | implicit commit | transactional | transactional |
| Interactive client | `mysql -u root -p` | `psql -U postgres` | `sqlite3 :memory:` |

## Error message shapes

Use these to infer the engine from a pasted error, and to show the
user what each engine says for the same mistake.

Syntax error:

```text
MySQL:      ERROR 1064 (42000): You have an error in your SQL syntax; ...
PostgreSQL: ERROR:  syntax error at or near "..."
SQLite:     Parse error: near "...": syntax error
```

Ambiguous column in a join:

```text
MySQL:      ERROR 1052 (23000): Column 'id' in field list is ambiguous
PostgreSQL: ERROR:  column reference "id" is ambiguous
SQLite:     Parse error: ambiguous column name: id
```

Non-aggregated column with `GROUP BY`:

```text
MySQL:      ERROR 1055 (42000): ... is not in GROUP BY clause and contains
            nonaggregated column ... incompatible with sql_mode=only_full_group_by
            (no error when ONLY_FULL_GROUP_BY is disabled)
PostgreSQL: ERROR:  column "users.name" must appear in the GROUP BY clause
            or be used in an aggregate function
SQLite:     accepted; the value comes from an arbitrary row of the group
```

Treat the strictest engine as the teacher: a query that PostgreSQL
rejects is usually a query whose meaning is not fully specified.

## Labeling engine-specific examples

Put the engine name in a comment line at the top of the code block,
and leave portable examples unlabeled:

```sql
-- PostgreSQL
INSERT INTO users (name) VALUES ('Dave') RETURNING id;
```

When the user has not named an engine, prefer the portable form and
mention the engine-specific alternative only if it matters.
