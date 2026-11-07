# GolfDB+ Component Catalog

Product planning inventory for Shot Tracker V1, Stats & Metrics V2, and Models V3. This catalog assigns proposed screen placements and preserves the two requested anchors. Availability varies by source, season, and event.

| Size | Desktop footprint |
| --- | --- |
| Small | One card, one column, or a short metadata strip |
| Medium | One content section, usually half to two-thirds width |
| Large | Full content width or a dedicated page |

Sizes describe the default visible footprint. For models, size describes the **output display**. On mobile, columns stack and wide tables scroll within their own containers. “Tables” below refers to on-screen components, including compact metadata rows.

## Models List

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Player Skill Ratings | Composite ratings, 0–100 | Medium | Players → Player Profile → right column, upper card |
| Player Behavior Ratings | Context ratings, −50 to +50 | Medium | Players → Player Profile → right column, directly below Skill Ratings |
| Playing Style & Aggression | Style classification and risk profile | Medium | Players → Player Profile → Models tab, upper section |
| Player Floor & Ceiling | Outcome distribution | Medium | Players → Player Profile → Models tab, below Style |
| Player–Course Fit | Match score and contributing factors | Medium | Courses → Course Profile → Fit tab, above fit rankings |
| Expected Shot Outcome | Shot-level prediction | Small | Shot Lab → selected shot, below measured shot specs |
| Caddie Zone | Spatial model for top-decile outcomes | Large | Courses → Hole Detail → field spray map overlay |
| Green Slope & Break | Terrain and trajectory estimation | Large | 3D Putt Lab → main green canvas |
| Putt Speed & Aim | Video-timed speed and cup-relative aim estimates | Small | 3D Putt Lab → selected putt inspector |
| Current Form & Trend | Time-window performance estimate | Medium | Players → Stats & History → above snapshot results |
| Player Event Projection | Score and finish distribution | Large | Events → Event Detail → Projections tab, main results section |
| Projected Winning Score | Field scoring forecast | Small | Events → Event Detail → Projections tab, above player projections |
| Player Fame Status | Composite fame score | Medium | Players → Player Profile → Fame tab, above platform breakdown |
| Course Traits Scale | 0–100 setup trait ratings | Medium | Courses → Course Profile → Traits |
| Course Similarity | Matched course-pair score and optional market context | Large | Courses → Course Profile → Similar Courses |
| Sportsbook Category Projections | Event outcome probabilities | Large | Events → Event Detail → Projections, below headline forecasts |
| Event Prestige Ranker | Edition and series ratings | Medium | Events → Event Detail → Prestige, above timeline |
| Nationality Skill | Country skill and depth rating | Large | Players → World Map, above country rankings |
| Shot Quality & Shape | Club and season distributions | Large | Players → Player Profile → Shot Map, under shot-type selectors |
| Par Scoring Chances | Outcome probability by par type | Medium | Players → Stats & History → Scoring, and Courses → Hole Detail |

Skill inputs cover power, accuracy, long/mid/short approach, around the green, putting distance, green reading, 10–20 ft putts, 3–10 ft putts, and scrambling. Behavior covers composure, bounce back, under pressure, and get creative. Fame combines social percentiles, event fan following, endorsement value, and earnings where available. The separate Prediction Engine consumes eligible model outputs plus course style, geography, form, history, weather, and sourced research.

## Dashboards List

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Dashboard Home | Cross-entity overview | Large | Home → below global navigation |
| Player DB | Searchable directory | Large | Players → Player DB, default landing |
| Player Profile | Entity overview | Large | Players → select player → Overview |
| Player Shot Map | Three-panel dispersion view | Large | Players → Shot Map → top row with Driver, Approach, and Around the Green |
| Player Rankings | Ranking and eligibility workspace | Large | Players → Rankings |
| Player / Round Scorecard | Scoring and comparisons | Large | Players → Player Profile → Scorecards, also linked from Round Center |
| Player Stats & History | Performance and historical reporting | Large | Players → Player Profile → Stats & History |
| Courses Directory | Searchable venue directory | Large | Courses → directory landing |
| Course Profile | Course overview and scoring | Large | Courses → select course → Overview |
| Hole & Green Explorer | Map and hole drilldown | Large | Courses → Course Profile → select hole → Hole Detail and Green Detail |
| Course & Hole Difficulty | Comparative rankings | Large | Courses → Difficulty |
| Events Directory | Past, current, and upcoming schedule | Large | Events → directory landing |
| Event Detail | Tournament overview and outcomes | Large | Events → select event → Overview |
| Round Center | Round and group reporting | Large | Events → Event Detail → select round |
| Shot Lab | Shot visualization and inspection | Large | Shot Lab → main view with event, round, player, hole, and shot selectors |
| Stats & Values | Metric catalog and comparison | Large | Stats & Metrics → Stats & Values |
| Snapshot Explorer | Historical comparison workspace | Large | Stats & Metrics → Snapshots |
| Bulk Downloads | Export builder and job monitor | Large | Tools → Bulk Downloads |
| 3D Putt Lab | 3D green analysis workspace | Large | Tools → 3D Putt Lab, also linked from Green Detail |
| Weather Tracker | Forecast and shot conditions | Medium | Events → Event Detail → Weather tab |
| Media Search | Search across news and media | Large | Media → Search, with contextual links from profiles and events |
| Player Fame Tracker | Fame score and evidence review | Large | Models → Fame Tracker, linked from Player Profile |
| Prediction Engine | Forecast and evidence workspace | Large | Models → Projections, linked from Event Detail |
| Model Registry | Model definitions and validation | Large | Models → Registry |
| Ingestion & Source Health | Backfill and quality monitoring | Large | Tools → Data Operations |
| World Map | Country skill map and player drilldown | Large | Players → World Map |
| Course Traits & Similar Courses | Setup ratings and comparable venue map | Large | Courses → Course Profile → Traits and Similar Courses |
| Event Prestige | Edition ratings and cited timeline | Large | Events → Event Detail → Prestige |

## Tables List

### Players

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Player Directory | Searchable index | Large | Players → Player DB → below search and active-field filters |
| PGA Tour Rookies | Roster table | Large | Players → PGA Tour Rookies → main area |
| Player Bio Rows | Key-value rows | Small | Players → Player Profile → beside oval headshot and flag |
| Overall Player Ranker Table | Compact ranking summary | Small | Players → Player Profile → **left column**, beneath the profile header |
| OWGR History | Seasonal and quarterly ranking table | Medium | Players → Player Profile → left column, below Overall Player Ranker |
| Priority & Signature Standings | Tabbed standings | Large | Players → Rankings → Priority and Signature tabs |
| Player Event History | Results ledger | Large | Players → Player Profile → Stats & History, below form summary |
| Scores, Streaks & Cuts | Split summary table | Medium | Players → Stats & History → Scoring tab, above event history |
| Earnings & FedExCup Points | Outcomes ledger | Medium | Players → Stats & History → Earnings & Points tab |
| Player Round Scorecard | Hole-by-hole score matrix | Large | Players → Scorecards → below round selector and summary |
| Round Stat Rows | OTT, fairways hit, GIR, and putts | Small | Players → Scorecards → above hole-by-hole scorecard |
| Field & Player Comparison | Comparative metric grid | Medium | Players → Scorecards → below hole-by-hole scorecard |
| Player Shot Log | Filtered shot table | Large | Players → Shot Map → below the three dispersion panels |
| Club Shot Specs | Per-club measurement rows | Small | Players → Shot Map → within each swing-plane and shot-arc card, below the apex marker visualization |
| Social Accounts & Followers | Platform links and dated counts | Medium | Players → Player Profile → Fame tab, beneath Fame Status |
| Fame Score Breakdown | Component weights and coverage | Medium | Models → Fame Tracker → below selected player score |
| Country Skill Rankings | Country rating, depth, and sample sizes | Large | Players → World Map → below map |
| Shot Quality & Shape Splits | Club, season, and field comparison | Medium | Players → Shot Map → below trajectory panels |
| Par Scoring Chances | Five-outcome probability table | Medium | Players → Stats & History → Scoring, below scoring splits |

### Courses

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Course Directory | Searchable venue index | Large | Courses → directory → below geography and course-style filters |
| Course Info Rows | Location, style, grass, setup and elevation metadata | Small | Courses → Course Profile → below header, above scorecard |
| Course Scorecard & Hole Attributes | Hole layout table | Large | Courses → Course Profile → below Course Info Rows |
| Course Toughness Rankings | Ranked course table | Large | Courses → Difficulty → Course Rankings tab, below filters |
| Hole Toughness Rankings | Ranked hole table with scoring distribution | Large | Courses → Difficulty → Hole Rankings tab, below filters |
| Green Difficulty Rankings | Ranked green comparison | Medium | Courses → Difficulty → Greens tab |
| Course & Hole Scoring Splits | Score distribution and field medians | Large | Courses → Course Profile → Scoring tab, with round and par-type filters |
| Hole Info Rows | Par, yardage, elevation and setup metadata | Small | Courses → Hole Detail → above full-hole map |
| Field Spray & Landing Zones | Dispersion and outcome summary | Medium | Courses → Hole Detail → below field spray map |
| Green Surface & Pin Rows | Green size, speed, grass, pin and slope metadata | Small | Courses → Green Detail → beside 2D green map |
| Green Coordinates & Putt Paths | Coordinate and trajectory grid | Large | 3D Putt Lab → below 3D canvas |
| Course Event History | Hosted event editions | Medium | Courses → Course Profile → Event History tab |
| Player–Course Fit Rankings | Model output table | Large | Courses → Course Profile → Fit tab, below fit summary |
| Course Social Accounts | Platform links and dated counts | Small | Courses → Course Profile → Media & Social tab |
| Course Traits Breakdown | Underlying measurements and trait percentiles | Medium | Courses → Course Profile → Traits, below scale cards |
| Similar Course Rankings | Pair score, coverage, and differences | Large | Courses → Course Profile → Similar Courses, below map |

### Events

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Event Schedule | Searchable event index | Large | Events → directory → below season and tournament filters |
| Event Info Rows | Compact metadata rows | Small | Events → Event Detail → **directly above Event Results Table** |
| Event Results Table | Current or final event leaderboard | Large | Events → Event Detail → Overview, below Event Info Rows |
| Past Event Results | Historical leaderboard | Large | Events → Event Detail → Past Results tab, below edition selector |
| Past Champions | Compact winners table | Medium | Events → Event Detail → Past Results tab, below historical leaderboard |
| Tee Times & Groups | Pairings and schedule | Large | Events → Event Detail → Tee Times, below round selector |
| Event Field & Player Status | Field roster | Large | Events → Event Detail → Field tab |
| Round Leaderboard | Round-level ranking grid | Large | Events → Round Center → above hole leaderboard |
| Hole-by-Hole Leaderboard | Hole scoring matrix | Large | Events → Round Center → below round leaderboard |
| Group Stats & Cut Status | Performance splits and cut tracking | Medium | Events → Round Center → below scoring tables |
| Event Earnings & Points | Results and awards ledger | Large | Events → Event Detail → Outcomes tab |
| Source Win Odds | Timestamped provider data | Medium | Events → Event Detail → Projections tab, separate from model probabilities |
| Group Start Weather | Forecast by tee time and starting hole | Medium | Events → Weather tab → above shot conditions |
| Shot Conditions | Timestamped weather matches | Large | Events → Weather tab → below Group Start Weather |
| Category Forecasts | Win, finish, cut, nationality, and round-one probabilities | Large | Events → Event Detail → Projections, below forecast summary |
| Event Prestige Breakdown | Pillar scores and source coverage | Medium | Events → Event Detail → Prestige, above signature moments |

### Shared Tools and Models

| Title | Type | Size | Designated Area |
| --- | --- | --- | --- |
| Shot Specs Rows | Radar and trajectory values | Small | Shot Lab → right inspector, below shot identity |
| Hole Shot Sequence | Ordered shot list | Medium | Shot Lab → below visualization, linked to selected shot |
| Shot Video Availability | Video references and availability | Small | Shot Lab → right inspector, below shot specs |
| Metric Definitions | Dictionary with unit, denominator and coverage | Large | Stats & Values → Definitions tab |
| Metric Rankings & Percentiles | Comparison table | Large | Stats & Values → Rankings tab, below metric and cohort filters |
| Player Snapshots | Historical metrics, ranks, earnings and streaks | Large | Snapshot Explorer → below filter toolbar |
| Split Performance | Event, round, hole, par-type and contention splits | Large | Snapshot Explorer → Drilldown tab |
| Field Benchmarks | Medians and sample sizes | Medium | Stats & Values → comparison sidebar, also used in course scoring |
| Export Job Queue | Operational status and retry grid | Large | Bulk Downloads → below dataset and export controls |
| Export Manifest | Source, row counts, coverage and as-of rows | Medium | Bulk Downloads → selected job details |
| Source Health & Backfill | Coverage, failures and reconciliation | Large | Tools → Data Operations → below source filters |
| Media Results | Articles, RSS items, videos, PDFs and transcripts | Large | Media Search → below query and entity filters |
| Forecast Results | Player scores, finish probabilities and intervals | Large | Prediction Engine → below forecast summary, embedded on Event Projections |
| Projection Evidence | Source, date and supporting finding | Medium | Prediction Engine → selected forecast, below results |
| Model Versions & Validation | Registry with inputs, weights and evaluation | Large | Model Registry → main area |
| Putt Timing & Aim | Estimated speed, aim offset, break and confidence | Medium | 3D Putt Lab → selected putt, below replay |

## Placement Details

- **Player Profile** places the Overall Player Ranker and OWGR history on the left. Skill Ratings and Behavior Ratings occupy the right column, in that order.
- **Event Results** starts with compact Event Info Rows for edition, dates, venue or course rotation, location, purse, and champion or defending champion where applicable. The results table follows immediately.
- **Difficulty** gives course and hole rankings separate tabs. The hole table includes rank, course, hole, par, yardage, average score, average vs par, and counts by score category where supplied.
- **Snapshot Explorer** supports round, tournament, past month, year to date, season, and first or second half of season. Filters include seasons 2001–2026, tournament name, combined majors, location, top-decile events, qualifiers, and purse. Drill down from player to event, round, and course hole.

See the [page inventory](PAGE_INVENTORY.md) for current demo coverage and [model specification](MODEL_SPECIFICATION.md) for the newer model designs.

## Project References

- [GolfDB+ Application Map](https://chatgpt.com/library?file_id=libfile_95b82428cbf48191971e24e0d0bb0c1b&account_id=personal)
- Project attachments include TournamentOverview, TournamentPastResults, CourseStats, CourseStatsOverview, scorecard and shot-detail GraphQL operations, the 2001–2025 results TSV, the 2021 round-level TSV, and the ASA tournament-level CSV archive.

## Implementation Notes

- **Assumptions** — Size describes display footprint. Placement beyond the two user-specified anchors is proposed. This is a planning inventory.
- **Risks** — Query definitions establish requested fields. Live coverage, video availability, green elevation, radar, 2026 backfill completeness, and external model inputs require verification. Show missing values and sample sizes explicitly.
- **Next Steps** — Build V1 shot capture and visualization first, then V2 aggregate views and exports, then V3 models and projections.
- **Alternatives** — Rankings and Projections can share a single underlying view with dedicated navigation and contextual embeds.
- **Performance Considerations** — Paginate leaderboards and shot logs. Precompute historical snapshots and field benchmarks by cohort.
- **Maintenance Considerations** — Give components stable IDs and track source coverage, metric definitions, model versions, and as-of timestamps.
