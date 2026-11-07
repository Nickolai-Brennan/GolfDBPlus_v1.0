# Shot Tracker model additions

Design specification for the Shot Tracker analytics layer. The single-shot data feeds the models where coverage permits. Every output has an as-of timestamp, model version, source coverage, and observation count. Course outputs identify the layout or setup, since a venue can change across events and years.

| Model | Output and grain | App placement |
| --- | --- | --- |
| `course-traits-scale` | One 0–100 profile per course setup, with typical and event-week conditions | Courses → Course Profile → Traits |
| `course-similarity-markets` | Ranked course pairs with 0–100 similarity, matched traits, and optional comparable-event market context | Courses → Course Profile → Similar Courses |
| `player-prediction-sportsbook-categories` | Probability per player or nationality, event, market, and as-of time | Events → Event Details → Projections |
| `event-prestige-ranker` | Edition score, event-series history, and pillar breakdown | Events → Event Details → Prestige |
| `player-nationality-skill` | Country-level skill and depth by season and tour | Players → World Map |
| `player-shot-quality-shape` | Player and shot-type distributions by season, plus field-relative rankings | Players → Profile → Shot Maps |
| `par-scoring-chances` | Player scoring distribution per par type and optional event hole or shot state | Players → Scoring and Courses → Hole Profile |

## 1. Course traits scale

Use course-relative percentile scores against a named, versioned tour cohort. High values mean stronger demands or larger measurements as labeled.

| Trait | Starter measurement |
| --- | --- |
| Driving distance | Estimated scoring advantage per additional 10 yards of usable carry, adjusted for accuracy and hole setup |
| Driving accuracy | Expected scoring cost of missing the intended driving corridor versus finding it at comparable distance |
| Iron accuracy | Expected scoring cost of approach misses by distance band, adjusted for lie and target difficulty |
| Green size | Median playable green area in square feet and its course percentile |
| Putt reads and speed | Two scores. Read difficulty uses verified slope or observed break at comparable distance. Speed uses recorded green speed where available |
| Miss punishment and forgiveness | Show the expected extra strokes after comparable misses and the share of misses with a playable recovery. Break out rough, sand, water, trees, and out of bounds where identifiable |
| Climate and weather | Separate typical seasonal wind, heat, humidity, rain, and altitude from event-week wind, precipitation, and other observed or forecast conditions |

Publish the underlying measurements beside each score. Leave unsupported traits unavailable. Treat estimated scoring effects as observational.

## 2. Course similarity map and market context

Compare physical layout, turf, and design separately from how the course plays. Feature groups include fairway widths and routing, elevation and green complexes, grass by surface, deep greenside bunkers, fairway bunkers, water exposure, dense woods, out-of-bounds exposure, and the course trait scores. Capture hazard exposure as the share of holes or target areas affected, with severity where sourced.

Use a weighted mixed-data distance over shared features. Starter weights are 40% layout and hazards, 35% playing demands, 15% turf, and 10% typical climate. Normalize numeric gaps, use explicit matches for categorical values, and weight each group once. Similarity equals 100 × (1 − weighted mean gap). Require at least 70% weighted feature coverage and coverage in both primary groups before ranking a pair. Show coverage, top matches, and biggest differences on a geographic map with a ranked table. Add event-week comparison as a separate overlay.

Treat “markets” as optional comparison context for prior events at similar courses. Show historical outcomes and time-stamped market prices only where recorded, with field strength and event format alongside them. Keep market prices out of the physical similarity score.

## 3. Player sportsbook-category projections

Run a shared tournament simulation using player baseline skill and recent form, course fit, field strength, tee-time weather, correlated round scores, and published tournament rules. Count the fraction of simulations meeting each market's defined outcome.

| Market | Outcome |
| --- | --- |
| Win | Official winner after applicable playoff rules |
| Top 5, top 10, top 20 | Finish within the specified threshold, with a separate dead-heat-adjusted view when matching book settlement |
| Make cut and miss cut | Cut outcome under the edition's rules. Suppress for no-cut events. Track withdrawal and disqualification separately |
| Nationality winner | Best eligible finisher within the selected nationality. Also support outright winner by nationality as a separately labeled market |
| Round 1 leader | First-round leader, with a stated tie policy and round completion rule |

Show model probability, fair odds, snapshot time, and uncertainty. A sportsbook comparison requires an aligned quote, market definition, and timestamp. Backtest chronologically with log loss, Brier score, and calibration by category. Check that win ≤ top 5 ≤ top 10 ≤ top 20 under compatible finish definitions.

## 4. Event prestige ranker

Calculate separate series and edition histories. Start with a 0–100 edition score using competition level (30%), verified media attention (20%), financial incentives (15%), qualification and stakes (15%), event longevity and timeline (10%), and documented signature moments (10%). Normalize monetary comparisons by currency and inflation where supported. Use pre-event field strength for upcoming editions and label edition scores provisional until required evidence is available. Keep signature moments in a cited editorial timeline with a rubric for consequence, rarity, and lasting relevance.

## 5. World map and country skill ranking

Color countries by an adjusted skill rating based on the season's eligible player cohort and display player count independently. Start with field-adjusted strokes gained per round, shrink thin country samples toward the tour baseline, and display the number of eligible players and rounds. For the country table, show overall rating, top-five player average, depth, and driving, approach, and putting splits. Support country-to-player drilldown. Use an effective-dated sporting nationality, expose unknowns, and avoid assigning nationality from event location.

## 6. Shot quality and shape

Show driver, long iron, and short iron in separate panels, with an additional mid-iron filter when verified club labels allow it. Provide a plan-view dispersion map, elevation view with apex marked, and three season overlays with a year-to-date label where needed. Normalize the display to the shot's target line and use comparable samples for seasonal rankings.

Track carry and total distance separately, launch and landing angles, apex, lateral curvature, target-relative miss distance, and dispersion. Use handedness to distinguish draw and fade from the signed curve direction. Separate shot shape from accuracy and rank shot quality by expected strokes gained from start and finish states where a validated baseline is available. Keep inferred or reconstructed paths labeled. Endpoints alone support endpoint dispersion and distance where coordinate scale is known. They do not establish apex, curvature, or launch angle. Distance bands without verified club labels are approach bands.

## 7. Par-3, par-4, and par-5 scoring chances

Estimate probabilities for eagle or better, birdie, par, bogey, and double bogey or worse. Display birdie-or-better and bogey-or-worse as summaries. Fit and evaluate at player–hole–round grain, pooling sparse samples toward the tour baseline by par and yardage band. Start with historical distributions and add setup, weather, player skill, and shot-state updates when available. Show sample size and expected score relative to par. All five outcome probabilities should sum to 100% before display rounding.

## Source readiness

| Project source reviewed | Evidence and constraint |
| --- | --- |
| `LeaderboardHoleByHole.graphql`, `CourseStats.graphql` | Query definitions expose player hole score, hole par, yardage, course IDs, and course round-hole aggregates. Historical response coverage still needs testing |
| `shotDetailsV4Compressed.graphql`, `ScorecardCompressedV3.graphql` | Requests expose compressed payloads. Validate decoded keys, units, coordinates, club labels, and optional radar before claiming trajectory coverage |
| `pga_results_2001-2025.tsv`, `raw_pga_536_2021 (1).tsv`, ASA tournament CSV | Historical results, sample round stats, and tournament-level finishes, SG, purse and cut indicators. These grains cannot supply player-by-hole outcomes |
| `TournamentPastResults.graphql`, `TournamentOverview.graphql`, `NewsArticles.graphql` | Player country labels, event overview and champion information, and dated news fields. Consistent nationality coverage and audience reach need separate verification |
| `oddsToWinCompressed.graphql` | Defines a win-odds request. Payload contents, historical snapshots, and other market categories need separate verification |

## Implementation Notes

**Assumptions.** Start with PGA Tour stroke play. Weights, coverage thresholds, and reference cohorts are proposed starting values. The three-year shot view uses the selected season and its two predecessors.

**Risks.** Sparse radar, absent course geometry, inconsistent nationality labels, and look-ahead leakage can change rankings materially. Resolve source IDs through crosswalks and show coverage alongside every published metric.

**Next Steps.** Validate decoded shot payloads and ingest a small player-hole test set. Implement par scoring and country rankings first, then shot trends, traits and similarity, prestige, and calibrated event predictions. Audit each model against known examples before publishing.

**Alternatives.** Start the similarity model with a curated course comparison when geometry is missing. Use empirical par distributions as the benchmark for contextual probabilities.

**Performance Considerations.** Keep canonical facts once. Cache course pairs per setup version and precompute player-season and player-par rollups. Preserve publication snapshots for reproducibility.

**Maintenance Considerations.** Version feature definitions, weights, eligibility, event rules, and source mappings. Revalidate on new seasons, course changes, or provider payload changes.
