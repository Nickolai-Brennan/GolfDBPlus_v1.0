# Database schemas

| Schema | Tables | Queries | Views |
|---|---|---|---|
| `public` | [Tables](public/tables.sql) | [Queries](public/queries.sql) | |
| `core` | [Tables](core/tables.sql) | [Queries](core/queries.sql) | |
| `intake` | [Tables](intake/tables.sql) | [Queries](intake/queries.sql) | [Views](intake/views.sql) |
| `analytics` | [Tables](analytics/tables.sql) | [Queries](analytics/queries.sql) | [Views](analytics/views.sql) |
| `performance` | [Tables](performance/tables.sql) | [Queries](performance/queries.sql) | [Views](performance/views.sql) |
| `statistic` | [Schema declaration](statistic/tables.sql) | [Queries](statistic/queries.sql) | [Views](statistic/views.sql) |

The folders group definitions by owning schema and prepared queries by their main relation. The `statistic` schema exposes views over canonical tables. Its table file contains the schema declaration.

Install database objects through [install.psql](../Schema/install.psql). The numbered migrations control cross-schema dependencies, data seeds, and transactions. The table and view files here are generated references. Load a schema's query file in the same PostgreSQL session that will execute its prepared statements. The original query entry points remain in [Queries](../Queries). Load either the original prepared statements or their schema-organized copies per session to avoid duplicate names.

```bash
psql "$DATABASE_URL" -X -f Database/Schema/install.psql
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f Database/Schemas/statistic/queries.sql \
  -c "EXECUTE statistic_player_registry('59095');"
```

Edit the canonical migration or query source identified in each file header. For the new performance and statistic reads, edit the schema's `read.sql`. Regenerate and verify the references from the repository root.

```bash
python -m pip install sqlparse==0.6.1
python Database/Schemas/generate.py
python Database/Schemas/generate.py --check
```
