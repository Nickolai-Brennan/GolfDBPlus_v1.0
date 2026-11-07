# GolfDB+ database design

The [reference dictionary](../Reference_Dictionary.sql) is a design input containing prose, field lists, and sample SQL. Run the numbered migrations under [Design/Database/SQL](../../Design/Database/SQL).

## Apply in order

Use a PostgreSQL 15+ database with the foundation tables in `public`.

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f Design/Database/SQL/001_golfdb_foundation.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f Design/Database/SQL/002_core_reference.sql
```

For an existing foundation database, apply only 002. Migration 002 is transactional. It uses stable codes and keeps existing reference rows on replay. The role needs permission to create the `core` schema and alter the existing event and course tables.

| Dictionary area | Implemented storage | Use |
| --- | --- | --- |
| Geography and time zones | `core.continents`, `core.countries`, `core.states_provinces`, `core.time_zones` | Continents and PostgreSQL zone names are seeded. Load reviewed country and subdivision data separately. Sporting nationality may differ from ISO codes |
| Units | `core.measurement_units` | Stable codes and display symbols, including shot speed, spin, distance, and green area. Store currency separately from monetary amounts |
| Competition | `core.event_types`, `core.event_statuses`, `core.cut_rules` | Nullable FKs on `public.events`; existing tours and seasons remain canonical. Tour type vocabulary does not replace tour IDs |
| Course metadata | `core.course_themes`, `core.time_zones` | Nullable FKs on `public.courses`; surfaces and terrain are reference groups until setup data exists |
| Sources | `core.source_types`, `core.data_sources` | Starter registry. Existing source-system text remains compatible pending source crosswalks |
| Other reference vocabulary | `core.lookup_values` | Time windows, weather, player/shot labels, stat types and categories, ingestion quality, model outputs, projection markets, and content. Use both `lookup_group` and `code` as the identity |

```sql
SELECT code, name
FROM core.lookup_values
WHERE lookup_group = 'time_types' AND is_active
ORDER BY sort_order, code;
```

The optional `detail` field stores dictionary display metadata such as weather families and range labels. Those strings are for display and do not classify observations. Preserve raw labels during ingest and map them to reviewed codes. Retirement uses `is_active`; historical references remain intact. The migration adds no wagering, fantasy, billing, or access-control subsystem. Projection market codes classify model outputs.

## Implementation Notes

- **Assumptions** — Existing tables use the foundation column names. Existing events and courses may have no normalized reference values.
- **Risks** — Course/provider labels and sporting nationality can be ambiguous. Avoid guessing mappings or backfilling event status from dates alone.
- **Next Steps** — Import reviewed country and subdivision records, then map historical provider codes before adding further foreign keys.
- **Alternatives** — Promote a grouped lookup to a dedicated table when a domain foreign key or typed metadata is needed.
- **Performance Considerations** — Primary keys index reference codes. Add domain-column indexes when filter traffic and query plans justify them.
- **Maintenance Considerations** — Add a new numbered migration for changed labels, seed policies, or new domain relationships.
