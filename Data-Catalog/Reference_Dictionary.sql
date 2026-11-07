Golf_DB / Caddy Stats Core Reference Dictionary

Purpose

The "core" schema stores shared reference data used across the entire Golf_DB / Caddy Stats platform.

Use "core" for values that are:

- Reused across players, courses, events, stats, models, dashboards, and imports
- Mostly stable over time
- Good candidates for dropdowns, filters, validations, or foreign keys
- Needed to standardize messy source data
- Useful for analytics, modeling, and API consistency

---

1. Recommended "core" File Tree

database/
├── schema/
│   └── core/
│       ├── 000_core_schema.sql
│       ├── 010_geography.sql
│       ├── 020_time.sql
│       ├── 030_weather_environment.sql
│       ├── 040_measurements_units.sql
│       ├── 050_sports_golf_reference.sql
│       ├── 060_people_identity.sql
│       ├── 070_competition_reference.sql
│       ├── 080_stats_reference.sql
│       ├── 090_data_sources.sql
│       ├── 100_ingestion_quality.sql
│       ├── 110_models_reference.sql
│       ├── 120_betting_fantasy_reference.sql
│       ├── 130_media_content_reference.sql
│       ├── 140_access_products.sql
│       └── 150_audit_system.sql
│
├── seeds/
│   └── core/
│       ├── seed_geography.sql
│       ├── seed_time.sql
│       ├── seed_weather_environment.sql
│       ├── seed_measurements_units.sql
│       ├── seed_golf_reference.sql
│       ├── seed_competition_reference.sql
│       ├── seed_stats_reference.sql
│       ├── seed_data_sources.sql
│       ├── seed_models_reference.sql
│       └── seed_content_reference.sql
│
docs/
└── data-dictionary/
    └── core/
        ├── CORE_OVERVIEW.md
        ├── GEOGRAPHY_REFERENCE.md
        ├── TIME_REFERENCE.md
        ├── WEATHER_ENVIRONMENT_REFERENCE.md
        ├── MEASUREMENT_REFERENCE.md
        ├── GOLF_REFERENCE.md
        ├── COMPETITION_REFERENCE.md
        ├── STATS_REFERENCE.md
        ├── DATA_SOURCE_REFERENCE.md
        ├── INGESTION_QUALITY_REFERENCE.md
        ├── MODEL_REFERENCE.md
        ├── BETTING_FANTASY_REFERENCE.md
        ├── CONTENT_REFERENCE.md
        └── AUDIT_SYSTEM_REFERENCE.md

---

2. Core Reference Groups

Group| Purpose
"geography"| Countries, states, cities, regions, continents, location metadata
"time"| Time zones, periods, seasons, date grains, tee-time windows
"weather_environment"| Weather, wind, temperature, climate, turf environment
"measurements_units"| Units, directions, value types, scales
"sports_golf_reference"| Golf scoring, surfaces, course types, play formats
"people_identity"| Statuses, handedness, roles, eligibility
"competition_reference"| Tours, event types, round types, statuses, cut rules
"stats_reference"| Stat types, categories, units, directions, calculation rules
"data_sources"| Source systems, licenses, endpoints, scrape/import metadata
"ingestion_quality"| Import status, data quality, confidence, verification
"models_reference"| Model types, versions, output types, run statuses
"betting_fantasy_reference"| Markets, bet types, odds formats, fantasy scoring
"media_content_reference"| Content types, article categories, publishing statuses
"access_products"| Subscription tiers, product types, feature flags
"audit_system"| Change logs, object types, error types, job statuses

---

3. Geography Reference

3.1 "core.continents"

Column| Type| Description
"continent_id"| "BIGSERIAL PRIMARY KEY"| Unique continent ID
"continent_code"| "TEXT UNIQUE NOT NULL"| Continent code
"continent_name"| "TEXT NOT NULL"| Continent name
"sort_order"| "INTEGER"| Display order
"is_active"| "BOOLEAN"| Active flag

Seed Values

Code| Name
"AF"| Africa
"AS"| Asia
"EU"| Europe
"NA"| North America
"OC"| Oceania
"SA"| South America
"AN"| Antarctica

---

3.2 "core.countries"

Column| Type| Description
"country_id"| "BIGSERIAL PRIMARY KEY"| Unique country ID
"country_code_2"| "CHAR(2) UNIQUE NOT NULL"| ISO alpha-2 code
"country_code_3"| "CHAR(3) UNIQUE"| ISO alpha-3 code
"country_name"| "TEXT NOT NULL"| Country name
"continent_id"| "BIGINT"| Links to continent
"region_name"| "TEXT"| Region
"subregion_name"| "TEXT"| Subregion
"default_currency_code"| "TEXT"| Currency
"default_timezone"| "TEXT"| IANA timezone
"phone_country_code"| "TEXT"| Calling code
"is_active"| "BOOLEAN"| Active flag

---

3.3 "core.states_provinces"

Column| Type| Description
"state_province_id"| "BIGSERIAL PRIMARY KEY"| Unique state/province ID
"country_id"| "BIGINT NOT NULL"| Country reference
"state_province_code"| "TEXT NOT NULL"| State/province code
"state_province_name"| "TEXT NOT NULL"| State/province name
"region_name"| "TEXT"| Geographic region
"timezone_primary"| "TEXT"| Primary timezone
"is_active"| "BOOLEAN"| Active flag

---

3.4 "core.cities"

Column| Type| Description
"city_id"| "BIGSERIAL PRIMARY KEY"| Unique city ID
"city_name"| "TEXT NOT NULL"| City name
"state_province_id"| "BIGINT"| State/province reference
"country_id"| "BIGINT NOT NULL"| Country reference
"latitude"| "NUMERIC(10,7)"| Latitude
"longitude"| "NUMERIC(10,7)"| Longitude
"timezone_name"| "TEXT"| IANA timezone
"elevation_ft"| "NUMERIC(10,2)"| Elevation
"is_active"| "BOOLEAN"| Active flag

---

3.5 "core.location_types"

Code| Name| Description
"country"| Country| Country-level location
"state_province"| State / Province| Regional subdivision
"city"| City| City/locality
"course"| Course| Golf course location
"venue"| Venue| Event venue
"resort"| Resort| Resort property
"club"| Club| Golf club/facility
"airport"| Airport| Travel/logistics location
"region"| Region| Custom region
"market"| Market| Media/betting/business market

---

4. Time Reference

4.1 "core.time_zones"

Column| Type| Description
"time_zone_id"| "BIGSERIAL PRIMARY KEY"| Unique timezone ID
"timezone_name"| "TEXT UNIQUE NOT NULL"| IANA timezone
"timezone_abbreviation_standard"| "TEXT"| Standard abbreviation
"timezone_abbreviation_daylight"| "TEXT"| Daylight abbreviation
"utc_offset_standard"| "TEXT"| Standard UTC offset
"utc_offset_daylight"| "TEXT"| Daylight UTC offset
"observes_dst"| "BOOLEAN"| Daylight saving flag
"is_active"| "BOOLEAN"| Active flag

---

4.2 "core.date_grains"

Code| Name| Description
"shot"| Shot| Single shot
"hole"| Hole| Single hole
"round"| Round| Single round
"day"| Day| Calendar day
"week"| Week| Calendar/tournament week
"month"| Month| Calendar month
"quarter"| Quarter| Calendar quarter
"season"| Season| Golf season
"year"| Year| Calendar year
"career"| Career| Full career
"custom"| Custom| User-defined range

---

4.3 "core.time_types"

Code| Name| Group
"shot"| Shot| "micro"
"hole"| Hole| "micro"
"front_9"| Front 9| "micro"
"back_9"| Back 9| "micro"
"round"| Round| "micro"
"event_round"| Event Round| "event"
"event"| Event| "event"
"event_to_date"| Event To Date| "event"
"last_7_days"| Last 7 Days| "rolling"
"last_14_days"| Last 14 Days| "rolling"
"last_30_days"| Last 30 Days| "rolling"
"last_60_days"| Last 60 Days| "rolling"
"last_90_days"| Last 90 Days| "rolling"
"season_to_date"| Season To Date| "season"
"season"| Season| "season"
"previous_season"| Previous Season| "season"
"two_seasons"| Two Seasons| "season"
"three_seasons"| Three Seasons| "season"
"five_seasons"| Five Seasons| "season"
"career"| Career| "career"
"course_history"| Course History| "history"
"event_history"| Event History| "history"
"rank_snapshot"| Rank Snapshot| "snapshot"
"model_run"| Model Run| "model"
"projection_window"| Projection Window| "model"
"simulation_run"| Simulation Run| "model"
"custom_window"| Custom Window| "custom"

---

4.4 "core.tee_time_types"

Code| Name
"early_morning"| Early Morning
"morning"| Morning
"late_morning"| Late Morning
"midday"| Midday
"afternoon"| Afternoon
"late_afternoon"| Late Afternoon
"evening"| Evening
"am_wave"| AM Wave
"pm_wave"| PM Wave
"am_pm_wave"| AM / PM Wave
"pm_am_wave"| PM / AM Wave

---

4.5 "core.round_types"

Code| Name| Description
"practice"| Practice| Practice round
"pro_am"| Pro-Am| Pro-am round
"round_1"| Round 1| First tournament round
"round_2"| Round 2| Second tournament round
"round_3"| Round 3| Third tournament round
"round_4"| Round 4| Fourth tournament round
"playoff"| Playoff| Playoff holes
"makeup_round"| Makeup Round| Completed after delay
"suspended_round"| Suspended Round| Interrupted round

---

5. Weather + Environment Reference

5.1 "core.weather_types"

Code| Name
"sunny"| Sunny
"cloudy_overcast"| Cloudy / Overcast
"precipitation"| Precipitation
"windy"| Windy
"storms_severe"| Storms / Severe
"obscurations"| Obscurations
"extreme_heat"| Extreme Heat
"cold"| Cold
"mixed"| Mixed

---

5.2 "core.weather_conditions"

Code| Weather Type
"clear"| "sunny"
"mostly_sunny"| "sunny"
"partly_cloudy"| "cloudy_overcast"
"mostly_cloudy"| "cloudy_overcast"
"overcast"| "cloudy_overcast"
"light_rain"| "precipitation"
"moderate_rain"| "precipitation"
"heavy_rain"| "precipitation"
"showers"| "precipitation"
"thunderstorm"| "storms_severe"
"lightning_delay"| "storms_severe"
"high_wind"| "windy"
"gusty"| "windy"
"fog"| "obscurations"
"haze"| "obscurations"
"smoke"| "obscurations"
"hot"| "extreme_heat"
"cold"| "cold"
"freezing"| "cold"

---

5.3 "core.wind_types"

Code| Name| MPH Range
"calm"| Calm| "0-3"
"light_breeze"| Light Breeze| "4-7"
"breeze"| Breeze| "8-12"
"moderate_wind"| Moderate Wind| "13-18"
"strong_wind"| Strong Wind| "19-25"
"very_strong_wind"| Very Strong Wind| "26-35"
"dangerous_wind"| Dangerous Wind| "36+"

---

5.4 "core.wind_directions"

Code| Name| Degrees
"n"| North| "0"
"nne"| North-Northeast| "22.5"
"ne"| Northeast| "45"
"ene"| East-Northeast| "67.5"
"e"| East| "90"
"ese"| East-Southeast| "112.5"
"se"| Southeast| "135"
"sse"| South-Southeast| "157.5"
"s"| South| "180"
"ssw"| South-Southwest| "202.5"
"sw"| Southwest| "225"
"wsw"| West-Southwest| "247.5"
"w"| West| "270"
"wnw"| West-Northwest| "292.5"
"nw"| Northwest| "315"
"nnw"| North-Northwest| "337.5"
"variable"| Variable| "NULL"

---

5.5 "core.temperature_bands"

Code| Name| Fahrenheit Range
"freezing"| Freezing| "<32"
"very_cold"| Very Cold| "32-44"
"cold"| Cold| "45-54"
"cool"| Cool| "55-64"
"mild"| Mild| "65-74"
"warm"| Warm| "75-84"
"hot"| Hot| "85-94"
"very_hot"| Very Hot| "95-104"
"extreme_heat"| Extreme Heat| "105+"

---

5.6 "core.precipitation_types"

Code| Name
"none"| None
"mist"| Mist
"drizzle"| Drizzle
"light_rain"| Light Rain
"moderate_rain"| Moderate Rain
"heavy_rain"| Heavy Rain
"showers"| Showers
"thunderstorm_rain"| Thunderstorm Rain
"snow"| Snow
"sleet"| Sleet
"hail"| Hail
"mixed_precipitation"| Mixed Precipitation

---

5.7 "core.climate_zones"

Code| Name
"tropical_wet"| Tropical Wet
"tropical_wet_dry"| Tropical Wet and Dry
"desert"| Desert
"semiarid"| Semiarid
"mediterranean"| Mediterranean
"marine_west_coast"| Marine West Coast
"humid_subtropical"| Humid Subtropical
"humid_continental"| Humid Continental
"subarctic"| Subarctic
"highland"| Highland
"coastal"| Coastal
"inland"| Inland

---

5.8 "core.course_environment_types"

Code| Name
"coastal"| Coastal
"inland"| Inland
"mountain"| Mountain
"desert"| Desert
"woodland"| Woodland
"prairie"| Prairie
"tropical"| Tropical
"urban"| Urban
"resort"| Resort
"linksland"| Linksland

---

6. Measurement + Value Reference

6.1 "core.measurement_units"

Code| Name| Symbol
"count"| Count| "#"
"percent"| Percent| "%"
"strokes"| Strokes| "strokes"
"yards"| Yards| "yds"
"feet"| Feet| "ft"
"inches"| Inches| "in"
"mph"| Miles Per Hour| "mph"
"degrees_f"| Degrees Fahrenheit| "°F"
"degrees_c"| Degrees Celsius| "°C"
"degrees_direction"| Direction Degrees| "°"
"stimp"| Stimpmeter| "stimp"
"score"| Score| "score"
"rating"| Rating| "rating"
"rank"| Rank| "rank"
"points"| Points| "pts"
"money"| Money| "$"
"probability"| Probability| "%"
"decimal"| Decimal| "decimal"
"boolean"| Boolean| "true/false"
"text"| Text| "text"
"date"| Date| "date"
"datetime"| DateTime| "timestamp"

---

6.2 "core.value_types"

Code| Name| Description
"integer"| Integer| Whole number
"decimal"| Decimal| Numeric decimal
"percent"| Percent| Percentage
"money"| Money| Currency value
"text"| Text| String/text
"boolean"| Boolean| True/false
"date"| Date| Date only
"datetime"| DateTime| Date and time
"json"| JSON| Structured JSON
"array"| Array| List/array
"rank"| Rank| Ordered rank
"score"| Score| Model or rating score

---

6.3 "core.stat_directions"

Code| Name
"higher_better"| Higher Better
"lower_better"| Lower Better
"neutral"| Neutral
"context_dependent"| Context Dependent
"boolean_true_good"| Boolean True Good
"boolean_false_good"| Boolean False Good

---

6.4 "core.scale_types"

Code| Name| Description
"zero_to_one"| 0 to 1| Probability-style scale
"zero_to_100"| 0 to 100| Rating/percentile scale
"one_to_10"| 1 to 10| Simple rating scale
"z_score"| Z-Score| Standardized score
"percentile"| Percentile| Population percentile
"rank_order"| Rank Order| Ranking scale
"raw_value"| Raw Value| Unscaled value
"custom"| Custom| Custom scale

---

7. Golf Reference

7.1 "core.player_statuses"

Code| Name
"amateur"| Amateur
"professional"| Professional
"rookie"| Rookie
"active"| Active
"injured"| Injured
"suspended"| Suspended
"retired"| Retired
"deceased"| Deceased

---

7.2 "core.handedness_types"

Code| Name
"right"| Right-Handed
"left"| Left-Handed
"ambidextrous"| Ambidextrous
"unknown"| Unknown

---

7.3 "core.golf_scores"

Code| Name| Relative To Par
"hole_in_one"| Hole In One| "special"
"condor"| Condor| "-4"
"albatross"| Albatross / Double Eagle| "-3"
"eagle"| Eagle| "-2"
"birdie"| Birdie| "-1"
"par"| Par| "0"
"bogey"| Bogey| "+1"
"double_bogey"| Double Bogey| "+2"
"triple_bogey"| Triple Bogey| "+3"
"quad_or_worse"| +4 Or Worse| "+4+"

---

7.4 "core.par_types"

Code| Name
"par_3"| Par 3
"par_4"| Par 4
"par_5"| Par 5
"par_6"| Par 6
"unknown"| Unknown

---

7.5 "core.course_themes"

Code| Name
"links"| Links
"parkland"| Parkland
"desert"| Desert
"heathland"| Heathland
"sandbelt"| Sandbelt
"mountain"| Mountain
"resort"| Resort
"stadium"| Stadium
"executive"| Executive
"championship"| Championship

---

7.6 "core.course_surfaces"

Code| Name| Group
"bentgrass"| Bentgrass| "grass"
"bermuda"| Bermuda| "grass"
"poa_annua"| Poa Annua| "grass"
"zoysia"| Zoysia| "grass"
"ryegrass"| Ryegrass| "grass"
"fescue"| Fescue| "grass"
"paspalum"| Paspalum| "grass"
"sand"| Sand| "hazard_surface"
"water"| Water| "hazard_surface"
"hardpan"| Hardpan| "natural_surface"
"pine_straw"| Pine Straw| "natural_surface"
"native_grass"| Native Grass| "natural_surface"

---

7.7 "core.course_terrain_types"

Code| Name| Group
"tee_box"| Tee Box| "starting_area"
"fairway"| Fairway| "primary_playing_surface"
"first_cut"| First Cut| "secondary_playing_surface"
"rough"| Rough| "penalty_surface"
"deep_rough"| Deep Rough| "penalty_surface"
"native_area"| Native Area| "natural_area"
"heather"| Heather| "natural_area"
"fescue"| Fescue| "natural_area"
"pine_straw"| Pine Straw| "natural_area"
"trees"| Trees| "obstruction"
"woods"| Woods| "obstruction"
"desert"| Desert| "natural_area"
"waste_area"| Waste Area| "natural_area"
"bunker"| Bunker| "hazard"
"fairway_bunker"| Fairway Bunker| "hazard"
"greenside_bunker"| Greenside Bunker| "hazard"
"water"| Water| "hazard"
"creek"| Creek| "hazard"
"pond"| Pond| "hazard"
"out_of_bounds"| Out Of Bounds| "penalty_area"
"penalty_area"| Penalty Area| "penalty_area"
"cart_path"| Cart Path| "man_made"
"road"| Road| "man_made"
"grandstand"| Grandstand| "man_made"
"fringe"| Fringe| "green_complex"
"collar"| Collar| "green_complex"
"green"| Green| "green_complex"
"false_front"| False Front| "green_complex"
"runoff_area"| Runoff Area| "green_complex"
"collection_area"| Collection Area| "green_complex"
"slope"| Slope| "topography"
"elevation_change"| Elevation Change| "topography"
"blind_shot_area"| Blind Shot Area| "topography"

---

7.8 "core.club_types"

Code| Name| Group
"driver"| Driver| "wood"
"3_wood"| 3 Wood| "wood"
"5_wood"| 5 Wood| "wood"
"hybrid"| Hybrid| "hybrid"
"long_iron"| Long Iron| "iron"
"mid_iron"| Mid Iron| "iron"
"short_iron"| Short Iron| "iron"
"pitching_wedge"| Pitching Wedge| "wedge"
"gap_wedge"| Gap Wedge| "wedge"
"sand_wedge"| Sand Wedge| "wedge"
"lob_wedge"| Lob Wedge| "wedge"
"putter"| Putter| "putter"
"unknown"| Unknown| "unknown"

---

7.9 "core.shot_types"

Code| Name
"tee_shot"| Tee Shot
"approach"| Approach
"layup"| Layup
"recovery"| Recovery
"chip"| Chip
"pitch"| Pitch
"bunker_shot"| Bunker Shot
"flop"| Flop Shot
"putt"| Putt
"penalty_drop"| Penalty Drop
"provisional"| Provisional
"tap_in"| Tap-In

---

7.10 "core.shot_shapes"

Code| Name
"straight"| Straight
"draw"| Draw
"fade"| Fade
"hook"| Hook
"slice"| Slice
"pull"| Pull
"push"| Push
"high"| High
"low"| Low
"knockdown"| Knockdown
"stinger"| Stinger
"unknown"| Unknown

---

8. Competition Reference

8.1 "core.tour_types"

Code| Name
"pga_tour"| PGA TOUR
"dp_world_tour"| DP World Tour
"liv_golf"| LIV Golf
"korn_ferry_tour"| Korn Ferry Tour
"pga_tour_champions"| PGA TOUR Champions
"lpga"| LPGA
"college"| College
"amateur"| Amateur
"international"| International
"custom"| Custom

---

8.2 "core.event_types"

Code| Name
"regular"| Regular Event
"signature"| Signature Event
"major"| Major Championship
"playoff"| Playoff Event
"opposite_field"| Opposite Field
"team"| Team Event
"match_play"| Match Play
"alternate_field"| Alternate Field
"exhibition"| Exhibition
"international"| International Event
"custom_simulation"| Custom Simulation

---

8.3 "core.event_statuses"

Code| Name
"scheduled"| Scheduled
"field_released"| Field Released
"tee_times_released"| Tee Times Released
"in_progress"| In Progress
"suspended"| Suspended
"delayed"| Delayed
"cut_made"| Cut Made
"complete"| Complete
"cancelled"| Cancelled
"postponed"| Postponed

---

8.4 "core.cut_rules"

Code| Name
"no_cut"| No Cut
"top_65_and_ties"| Top 65 And Ties
"top_70_and_ties"| Top 70 And Ties
"top_50_and_ties"| Top 50 And Ties
"top_60_and_ties"| Top 60 And Ties
"custom_cut"| Custom Cut
"match_play_no_cut"| Match Play No Cut
"team_event_no_cut"| Team Event No Cut

---

8.5 "core.field_strength_tiers"

Code| Name
"elite"| Elite
"strong"| Strong
"average"| Average
"weak"| Weak
"opposite_field"| Opposite Field
"major_field"| Major Field
"signature_field"| Signature Field
"limited_field"| Limited Field

---

8.6 "core.result_statuses"

Code| Name
"complete"| Complete
"active"| Active
"missed_cut"| Missed Cut
"made_cut"| Made Cut
"withdrawn"| Withdrawn
"disqualified"| Disqualified
"did_not_start"| Did Not Start
"did_not_finish"| Did Not Finish
"no_card"| No Card
"suspended"| Suspended

---

9. Stats Reference

9.1 "core.stat_types"

Code| Name
"standard"| Standard
"advanced"| Advanced
"strokes_gained"| Strokes Gained
"model_metric"| Model Metric
"percentile"| Percentile
"rating"| Rating
"ranking"| Ranking
"trend"| Trend
"projection"| Projection
"simulation"| Simulation
"snapshot"| Snapshot
"split"| Split
"aggregate"| Aggregate

---

9.2 "core.stat_categories"

Code| Name
"overview"| Overview
"strokes_gained"| Strokes Gained
"off_the_tee"| Off The Tee
"approach"| Approach
"around_green"| Around Green
"putting"| Putting
"scoring"| Scoring
"streaks"| Streaks
"money_finishes"| Money / Finishes
"points_rankings"| Points / Rankings
"course_fit"| Course Fit
"weather"| Weather
"surface"| Surface
"betting"| Betting
"fantasy"| Fantasy
"simulation"| Simulation
"projection"| Projection
"modeling"| Modeling

---

9.3 "core.stat_coverage_types"

Code| Name
"full"| Full
"partial"| Partial
"estimated"| Estimated
"manual"| Manual
"official"| Official
"unverified"| Unverified
"missing"| Missing
"not_applicable"| Not Applicable

---

9.4 "core.calculation_methods"

Code| Name
"raw_source"| Raw Source
"sum"| Sum
"average"| Average
"median"| Median
"min"| Minimum
"max"| Maximum
"rate"| Rate
"percentage"| Percentage
"weighted_average"| Weighted Average
"rolling_average"| Rolling Average
"z_score"| Z-Score
"percentile_rank"| Percentile Rank
"model_formula"| Model Formula
"simulation"| Simulation
"manual_override"| Manual Override

---

10. Data Source Reference

10.1 "core.data_sources"

Column| Type| Description
"data_source_id"| "BIGSERIAL PRIMARY KEY"| Unique source ID
"source_code"| "TEXT UNIQUE NOT NULL"| Source code
"source_name"| "TEXT NOT NULL"| Source name
"source_type_id"| "BIGINT"| Source type
"base_url"| "TEXT"| Base URL
"requires_auth"| "BOOLEAN"| Auth required
"is_official"| "BOOLEAN"| Official source flag
"is_active"| "BOOLEAN"| Active flag

---

10.2 "core.source_types"

Code| Name
"official"| Official
"third_party"| Third Party
"media"| Media
"manual"| Manual
"model"| Model
"api"| API
"scrape"| Scrape
"file_upload"| File Upload
"internal"| Internal
"user_generated"| User Generated

---

10.3 "core.source_file_types"

Code| Name
"csv"| CSV
"xlsx"| Excel
"json"| JSON
"xml"| XML
"parquet"| Parquet
"pdf"| PDF
"html"| HTML
"api_response"| API Response
"manual_entry"| Manual Entry
"image"| Image
"markdown"| Markdown

---

10.4 "core.import_frequencies"

Code| Name
"real_time"| Real Time
"hourly"| Hourly
"daily"| Daily
"weekly"| Weekly
"event_based"| Event Based
"seasonal"| Seasonal
"manual"| Manual
"ad_hoc"| Ad Hoc

---

11. Ingestion + Quality Reference

11.1 "core.import_statuses"

Code| Name
"pending"| Pending
"running"| Running
"complete"| Complete
"complete_with_warnings"| Complete With Warnings
"failed"| Failed
"cancelled"| Cancelled
"retrying"| Retrying
"skipped"| Skipped

---

11.2 "core.data_quality_statuses"

Code| Name
"valid"| Valid
"warning"| Warning
"error"| Error
"missing_required"| Missing Required
"duplicate"| Duplicate
"outlier"| Outlier
"stale"| Stale
"unverified"| Unverified
"manually_verified"| Manually Verified
"source_conflict"| Source Conflict

---

11.3 "core.confidence_levels"

Code| Name| Score Range
"very_low"| Very Low| "0-20"
"low"| Low| "21-40"
"medium"| Medium| "41-60"
"high"| High| "61-80"
"very_high"| Very High| "81-100"

---

11.4 "core.verification_statuses"

Code| Name
"unverified"| Unverified
"source_verified"| Source Verified
"manual_verified"| Manual Verified
"cross_verified"| Cross Verified
"model_estimated"| Model Estimated
"deprecated"| Deprecated
"rejected"| Rejected

---

11.5 "core.error_types"

Code| Name
"missing_value"| Missing Value
"invalid_type"| Invalid Type
"invalid_range"| Invalid Range
"foreign_key_missing"| Foreign Key Missing
"duplicate_record"| Duplicate Record
"source_unavailable"| Source Unavailable
"schema_mismatch"| Schema Mismatch
"parse_error"| Parse Error
"timeout"| Timeout
"auth_error"| Authentication Error
"rate_limited"| Rate Limited
"unknown"| Unknown

---

12. Model Reference

12.1 "core.model_types"

Code| Name
"rating"| Rating Model
"ranking"| Ranking Model
"projection"| Projection Model
"classification"| Classification Model
"simulation"| Simulation Model
"probability"| Probability Model
"course_fit"| Course Fit Model
"weather_fit"| Weather Fit Model
"betting_value"| Betting Value Model
"fantasy_value"| Fantasy Value Model
"trend_model"| Trend Model
"risk_model"| Risk Model

---

12.2 "core.model_run_statuses"

Code| Name
"queued"| Queued
"running"| Running
"complete"| Complete
"failed"| Failed
"cancelled"| Cancelled
"stale"| Stale
"archived"| Archived

---

12.3 "core.model_output_types"

Code| Name
"score"| Score
"rating"| Rating
"rank"| Rank
"percentile"| Percentile
"probability"| Probability
"projection"| Projection
"classification"| Classification
"recommendation"| Recommendation
"flag"| Flag
"explanation"| Explanation

---

12.4 "core.risk_levels"

Code| Name
"very_low"| Very Low
"low"| Low
"medium"| Medium
"high"| High
"very_high"| Very High
"extreme"| Extreme

---

13. Betting + Fantasy Reference

13.1 "core.odds_formats"

Code| Name
"american"| American
"decimal"| Decimal
"fractional"| Fractional
"implied_probability"| Implied Probability

---

13.2 "core.bet_market_types"

Code| Name
"outright_winner"| Outright Winner
"top_5"| Top 5
"top_10"| Top 10
"top_20"| Top 20
"make_cut"| Make Cut
"miss_cut"| Miss Cut
"matchup"| Matchup
"three_ball"| Three Ball
"first_round_leader"| First Round Leader
"round_score"| Round Score
"nationality_top"| Top Nationality
"group_winner"| Group Winner
"dfs_salary"| DFS Salary
"fantasy_points"| Fantasy Points

---

13.3 "core.sportsbook_types"

Code| Name
"draftkings"| DraftKings
"fanduel"| FanDuel
"betmgm"| BetMGM
"caesars"| Caesars
"espnbet"| ESPN BET
"bet365"| bet365
"circa"| Circa
"pinnacle"| Pinnacle
"consensus"| Consensus
"manual"| Manual

---

13.4 "core.fantasy_platforms"

Code| Name
"draftkings"| DraftKings
"fanduel"| FanDuel
"yahoo"| Yahoo
"espn"| ESPN
"custom"| Custom
"caddystats"| CaddyStats

---

13.5 "core.value_grades"

Code| Name
"a_plus"| A+
"a"| A
"b"| B
"c"| C
"d"| D
"f"| F
"avoid"| Avoid
"watchlist"| Watchlist

---

14. Media + Content Reference

14.1 "core.content_types"

Code| Name
"article"| Article
"blog_post"| Blog Post
"tournament_preview"| Tournament Preview
"course_preview"| Course Preview
"betting_picks"| Betting Picks
"fantasy_picks"| Fantasy Picks
"player_breakdown"| Player Breakdown
"model_report"| Model Report
"weekly_recap"| Weekly Recap
"newsletter"| Newsletter
"social_post"| Social Post
"video_script"| Video Script
"dashboard_embed"| Dashboard Embed

---

14.2 "core.publish_statuses"

Code| Name
"draft"| Draft
"review"| Review
"scheduled"| Scheduled
"published"| Published
"updated"| Updated
"archived"| Archived
"deleted"| Deleted

---

14.3 "core.content_channels"

Code| Name
"website"| Website
"newsletter"| Newsletter
"x_twitter"| X / Twitter
"reddit"| Reddit
"discord"| Discord
"linkedin"| LinkedIn
"bluesky"| Bluesky
"mastodon"| Mastodon
"youtube"| YouTube
"podcast"| Podcast

---

14.4 "core.seo_intent_types"

Code| Name
"informational"| Informational
"commercial"| Commercial
"transactional"| Transactional
"navigational"| Navigational
"comparison"| Comparison
"news"| News
"evergreen"| Evergreen

---

15. Access + Product Reference

15.1 "core.product_types"

Code| Name
"free"| Free
"premium"| Premium
"vip"| VIP
"ebook"| eBook
"dashboard"| Dashboard
"model_access"| Model Access
"newsletter"| Newsletter
"league_entry"| League Entry
"api_access"| API Access
"custom_report"| Custom Report

---

15.2 "core.subscription_tiers"

Code| Name
"free"| Free
"founding_member"| Founding Member
"premium"| Premium
"vip"| VIP
"admin"| Admin
"internal"| Internal

---

15.3 "core.feature_flags"

Code| Name
"course_dashboard"| Course Dashboard
"player_dashboard"| Player Dashboard
"betting_dashboard"| Betting Dashboard
"simulation_engine"| Simulation Engine
"premium_charts"| Premium Charts
"raw_data_downloads"| Raw Data Downloads
"model_explanations"| Model Explanations
"api_access"| API Access
"admin_tools"| Admin Tools

---

16. Audit + System Reference

16.1 "core.object_types"

Code| Name
"player"| Player
"course"| Course
"hole"| Hole
"event"| Event
"round"| Round
"shot"| Shot
"stat"| Stat
"model"| Model
"ranking"| Ranking
"projection"| Projection
"article"| Article
"user"| User
"import_job"| Import Job
"source_file"| Source File

---

16.2 "core.change_types"

Code| Name
"created"| Created
"updated"| Updated
"deleted"| Deleted
"archived"| Archived
"restored"| Restored
"verified"| Verified
"deprecated"| Deprecated
"merged"| Merged
"split"| Split
"manual_override"| Manual Override
"system_update"| System Update
"model_update"| Model Update

---

16.3 "core.job_statuses"

Code| Name
"queued"| Queued
"running"| Running
"success"| Success
"success_with_warnings"| Success With Warnings
"failed"| Failed
"cancelled"| Cancelled
"retrying"| Retrying
"paused"| Paused
"skipped"| Skipped

---

16.4 "core.priority_levels"

Code| Name
"low"| Low
"normal"| Normal
"medium"| Medium
"high"| High
"urgent"| Urgent
"critical"| Critical

---

17. Recommended Universal Lookup Table Pattern

Most simple "core" lookup tables can follow this format:

-- file: database/schema/core/000_lookup_pattern.sql

CREATE TABLE IF NOT EXISTS core.example_lookup (
    example_lookup_id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    group_code TEXT,
    sort_order INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

Use this pattern for:

weather_types
weather_conditions
wind_types
temperature_bands
course_themes
course_surfaces
event_types
event_statuses
stat_types
stat_categories
model_types
content_types
publish_statuses

---

18. Recommended Core Schema SQL

-- file: database/schema/core/000_core_schema.sql

CREATE SCHEMA IF NOT EXISTS core;

-- Shared update timestamp function.
CREATE OR REPLACE FUNCTION core.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---

19. Recommended Core Lookup Template SQL

-- file: database/schema/core/001_core_lookup_template.sql

CREATE TABLE IF NOT EXISTS core.lookup_template (
    lookup_id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    group_code TEXT,
    sort_order INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lookup_template_code
    ON core.lookup_template (code);

CREATE INDEX IF NOT EXISTS idx_lookup_template_group_code
    ON core.lookup_template (group_code);

CREATE INDEX IF NOT EXISTS idx_lookup_template_active
    ON core.lookup_template (is_active);

---

20. Recommended Core Build Priority

MVP Core

Build these first:

countries
states_provinces
time_zones
measurement_units
value_types
stat_directions
time_types
weather_types
weather_conditions
wind_types
temperature_bands
course_themes
course_surfaces
course_terrain_types
player_statuses
tour_types
event_types
event_statuses
stat_types
stat_categories
data_sources
source_types
import_statuses
data_quality_statuses
model_types

Advanced Core

Build these after MVP:

cities
location_types
date_grains
tee_time_types
daylight_types
precipitation_types
wind_directions
humidity_bands
climate_zones
elevation_bands
course_environment_types
club_types
shot_types
shot_shapes
cut_rules
field_strength_tiers
calculation_methods
confidence_levels
verification_statuses
error_types
model_output_types
risk_levels
bet_market_types
sportsbook_types
fantasy_platforms
content_types
publish_statuses
feature_flags
object_types
change_types
job_statuses

---

Implementation Notes

Assumptions

- "core" is the shared reference layer for Golf_DB / Caddy Stats.
- PostgreSQL is the target database.
- Most "core" tables are lookup tables.
- Entity-specific values stay outside "core".
- Example: "course_id" belongs in "courses", not "core".
- Example: "player_id" belongs in "players", not "core".

Risks

- Overbuilding "core" can slow early development.
- Too many lookup tables can make inserts more complex.
- Some values may later need to move from "core" into domain schemas.
- Weather and betting source mappings may need raw source value tables because each provider names things differently.

Next Steps

1. Build MVP "core" lookup tables.
2. Seed the required reference values.
3. Create foreign keys from "players", "courses", "events", "player_stats", "models", and "content".
4. Add raw source mapping tables for messy imported labels.
5. Add validation rules using "core" codes.
6. Generate API dropdown/filter options from "core".

Alternatives

For MVP, you can use a single generic lookup table:

core.lookup_values

With columns:

lookup_group
code
name
description
sort_order
is_active

That is faster early, but weaker long term. I recommend separate lookup tables for important domains like weather, time, geography, stats, events, and models.

Performance Considerations

- Index every "code" column.
- Index every "group_code" column.
- Index every foreign key.
- Keep lookup tables small.
- Cache lookup tables in the API layer.
- Use codes in import pipelines, IDs in normalized database tables, and names in UI.

Maintenance Considerations

- Add "is_active" to every lookup table.
- Add "sort_order" for UI display.
- Add "created_at" and "updated_at".
- Add "deprecated_at" only when values may be retired.
- Add source mapping tables for external systems.
- Do not delete lookup values that historical records depend on.
