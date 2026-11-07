# GolfDB+ page inventory

This audit covers the repository's `main` branch and the [static dashboard demo](https://github.com/Nickolai-Brennan/GolfDBPlus_v1.0/blob/0f49c59/demo/index.html) on `demo/golfdb-dashboard`. The demo has one HTML entry point with in-page navigation. Main contains schema, scripts, assets, and documentation. There is no application router or database-connected frontend on main.

## Existing demo views

| View | Behavior in the demo | Data and gaps |
| --- | --- | --- |
| Data Entry → Players | Sample master table, text search, tour filter, CSV download | In-memory records and synthetic IDs. No profile navigation, source matching, or edits |
| Data Entry → Events | Sample event table, text search, tour filter, CSV download | No edition detail, tee times, or leaderboard drilldown |
| Data Entry → Courses | Sample course table, text search, CSV download | Tour filter is offered even though course rows have no tour property. Selecting a specific tour hides all rows |
| Stats & Metrics | Player selector, skill bars, scoring chart, fairway scatter | Skills change with player selection. Trend and scatter reuse fixed sample data. No real shots, scorecards, or stats query |
| Models | Roadmap, governance notes, development sequence | No trained models, model runs, or projections |

The registry table's body also starts empty after tab or section navigation until a search/filter action refreshes the rows. Initial load explicitly populates it. These findings are from the demo source. Its UI behavior is tracked separately from the database migration.

## Planned screens and data boundaries

| Screen or group | Planned views | Existing database support and remaining data |
| --- | --- | --- |
| Home | Cross-entity overview and shortcuts | Registry only. Recent results and shot summaries need facts |
| Players | Player DB, Rookies, Profile, Rankings, World Map | Player identity and source IDs exist. Effective-dated sporting nationality, profile details, and ranking history need ingestion. Profile ranker remains in the left column |
| Player detail | Stats & History, Shot Map, Round Scorecard, Media & Social, Fame, Models | Player identity exists. Round and shot facts, social snapshots, ratings, and sourced model outputs are pending |
| Courses | Directory, Profile, Difficulty, Traits, Similar Courses | Course identity exists. Migration adds theme and time zone references. Versioned layout, turf by surface, hazards, scoring, and similarity outputs are pending |
| Hole and green | Hole Detail, Green Detail, 3D Putt Lab, Caddie Zone | Course ID and reference categories exist. Hole/setup IDs, coordinates, green meshes, timestamps, and shot dispersion are pending |
| Events | Directory, Detail, Past Results, Field, Tee Times, Round Center, Outcomes | Event/season IDs and a course link exist. Migration adds event type, status, and cut rule. Multi-course rotation, field entries, tee times, scoreboards, earnings, and points are pending. Event Info Rows remain immediately above Event Results |
| Event analysis | Weather, Projections, Prestige | Reference vocabularies exist. Forecasts, observed weather, market quotes, evidence, and model outputs are pending |
| Shot Lab | Event → round → player → hole → shot | Shot and unit vocabulary exists. Compressed response decoding, coordinates, radar, and video availability need verification and ingestion |
| Stats & Values | Metric definitions, comparisons, Snapshot Explorer | Units, time windows, stat categories, and directions exist. Canonical facts and point-in-time queries are pending. Store each fact once and derive windowed results |
| Data Entry and Tools | Registry, Query Studio, imports, Bulk Downloads, Data Operations, asset browser | SQL foundation and offline scripts exist. App workflows, exports, job persistence, and source mappings are pending |
| Media Search | Entity-linked articles, transcripts, video, RSS, PDFs | Content tables, full-text index, and offline scripts exist. UI and provider ingestion are pending |
| Models | Model Registry, Prediction Engine, Fame Tracker | Reference types, scales, model states, and projection market labels exist. Training, calibration, versioned outputs, and serving are pending |

Use the [component catalog](COMPONENT_CATALOG.md) for sizes and placement, the [model specification](MODEL_SPECIFICATION.md) for model grain, and the [core reference guide](../Database/Design/readme.md) for database boundaries.
