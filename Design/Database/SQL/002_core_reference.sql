-- Apply after 001_golfdb_foundation.sql. Replays preserve local reference edits.
BEGIN;

CREATE SCHEMA IF NOT EXISTS core;

-- Keep shared metadata for categories whose values do not yet have a domain FK.
CREATE TABLE IF NOT EXISTS core.lookup_values (
    lookup_group TEXT NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    detail TEXT,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (lookup_group, code)
);

CREATE TABLE IF NOT EXISTS core.continents (
    continent_code CHAR(2) PRIMARY KEY,
    continent_name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.time_zones (
    timezone_name TEXT PRIMARY KEY,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.countries (
    country_code_2 CHAR(2) PRIMARY KEY CHECK (country_code_2 ~ '^[A-Z]{2}$'),
    country_code_3 CHAR(3) NOT NULL UNIQUE CHECK (country_code_3 ~ '^[A-Z]{3}$'),
    country_name TEXT NOT NULL,
    continent_code CHAR(2) REFERENCES core.continents(continent_code),
    default_timezone TEXT REFERENCES core.time_zones(timezone_name),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.states_provinces (
    country_code_2 CHAR(2) REFERENCES core.countries(country_code_2),
    state_province_code TEXT,
    state_province_name TEXT NOT NULL,
    timezone_primary TEXT REFERENCES core.time_zones(timezone_name),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (country_code_2, state_province_code)
);

CREATE TABLE IF NOT EXISTS core.measurement_units (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    symbol TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.course_themes (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.event_types (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.event_statuses (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.cut_rules (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.source_types (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.data_sources (
    source_code TEXT PRIMARY KEY,
    source_name TEXT NOT NULL,
    source_type_code TEXT NOT NULL REFERENCES core.source_types(code),
    base_url TEXT,
    requires_auth BOOLEAN,
    is_official BOOLEAN,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO core.continents (continent_code, continent_name, sort_order) VALUES
    ('AF', 'Africa', 1),
    ('AS', 'Asia', 2),
    ('EU', 'Europe', 3),
    ('NA', 'North America', 4),
    ('OC', 'Oceania', 5),
    ('SA', 'South America', 6),
    ('AN', 'Antarctica', 7)
ON CONFLICT (continent_code) DO NOTHING;

-- PostgreSQL supplies IANA names and aliases. Offsets depend on the timestamp.
INSERT INTO core.time_zones (timezone_name)
SELECT name FROM pg_timezone_names
ON CONFLICT (timezone_name) DO NOTHING;

INSERT INTO core.measurement_units (code, name, symbol, sort_order) VALUES
    ('count', 'Count', '#', 1),
    ('percent', 'Percent', '%', 2),
    ('strokes', 'Strokes', 'strokes', 3),
    ('yards', 'Yards', 'yds', 4),
    ('feet', 'Feet', 'ft', 5),
    ('inches', 'Inches', 'in', 6),
    ('mph', 'Miles Per Hour', 'mph', 7),
    ('degrees_f', 'Degrees Fahrenheit', '°F', 8),
    ('degrees_c', 'Degrees Celsius', '°C', 9),
    ('degrees_direction', 'Direction Degrees', '°', 10),
    ('stimp', 'Stimpmeter', 'stimp', 11),
    ('score', 'Score', 'score', 12),
    ('rating', 'Rating', 'rating', 13),
    ('rank', 'Rank', 'rank', 14),
    ('points', 'Points', 'pts', 15),
    ('money', 'Money', '$', 16),
    ('probability', 'Probability', '%', 17),
    ('decimal', 'Decimal', 'decimal', 18),
    ('boolean', 'Boolean', 'true/false', 19),
    ('text', 'Text', 'text', 20),
    ('date', 'Date', 'date', 21),
    ('datetime', 'DateTime', 'timestamp', 22),
    ('rpm', 'Revolutions Per Minute', 'rpm', 23),
    ('square_feet', 'Square Feet', 'ft²', 24),
    ('seconds', 'Seconds', 's', 25),
    ('meters', 'Meters', 'm', 26)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.course_themes (code, name, sort_order) VALUES
    ('links', 'Links', 1),
    ('parkland', 'Parkland', 2),
    ('desert', 'Desert', 3),
    ('heathland', 'Heathland', 4),
    ('sandbelt', 'Sandbelt', 5),
    ('mountain', 'Mountain', 6),
    ('resort', 'Resort', 7),
    ('stadium', 'Stadium', 8),
    ('executive', 'Executive', 9),
    ('championship', 'Championship', 10)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.event_types (code, name, sort_order) VALUES
    ('regular', 'Regular Event', 1),
    ('signature', 'Signature Event', 2),
    ('major', 'Major Championship', 3),
    ('playoff', 'Playoff Event', 4),
    ('opposite_field', 'Opposite Field', 5),
    ('team', 'Team Event', 6),
    ('match_play', 'Match Play', 7),
    ('alternate_field', 'Alternate Field', 8),
    ('exhibition', 'Exhibition', 9),
    ('international', 'International Event', 10),
    ('custom_simulation', 'Custom Simulation', 11)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.event_statuses (code, name, sort_order) VALUES
    ('scheduled', 'Scheduled', 1),
    ('field_released', 'Field Released', 2),
    ('tee_times_released', 'Tee Times Released', 3),
    ('in_progress', 'In Progress', 4),
    ('suspended', 'Suspended', 5),
    ('delayed', 'Delayed', 6),
    ('cut_made', 'Cut Made', 7),
    ('complete', 'Complete', 8),
    ('cancelled', 'Cancelled', 9),
    ('postponed', 'Postponed', 10)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.cut_rules (code, name, sort_order) VALUES
    ('no_cut', 'No Cut', 1),
    ('top_65_and_ties', 'Top 65 And Ties', 2),
    ('top_70_and_ties', 'Top 70 And Ties', 3),
    ('top_50_and_ties', 'Top 50 And Ties', 4),
    ('top_60_and_ties', 'Top 60 And Ties', 5),
    ('custom_cut', 'Custom Cut', 6),
    ('match_play_no_cut', 'Match Play No Cut', 7),
    ('team_event_no_cut', 'Team Event No Cut', 8)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.source_types (code, name, sort_order) VALUES
    ('official', 'Official', 1),
    ('third_party', 'Third Party', 2),
    ('media', 'Media', 3),
    ('manual', 'Manual', 4),
    ('model', 'Model', 5),
    ('api', 'API', 6),
    ('scrape', 'Scrape', 7),
    ('file_upload', 'File Upload', 8),
    ('internal', 'Internal', 9),
    ('user_generated', 'User Generated', 10)
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.data_sources (source_code, source_name, source_type_code) VALUES
    ('pgatourmedia', 'PGA TOUR Media', 'media'),
    ('pgatour', 'PGA TOUR', 'official'),
    ('datagolf', 'DataGolf', 'third_party'),
    ('historical_upload', 'Historical File Upload', 'file_upload')
ON CONFLICT (source_code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('date_grains', 'shot', 'Shot', 1, 'Single shot'),
    ('date_grains', 'hole', 'Hole', 2, 'Single hole'),
    ('date_grains', 'round', 'Round', 3, 'Single round'),
    ('date_grains', 'day', 'Day', 4, 'Calendar day'),
    ('date_grains', 'week', 'Week', 5, 'Calendar/tournament week'),
    ('date_grains', 'month', 'Month', 6, 'Calendar month'),
    ('date_grains', 'quarter', 'Quarter', 7, 'Calendar quarter'),
    ('date_grains', 'season', 'Season', 8, 'Golf season'),
    ('date_grains', 'year', 'Year', 9, 'Calendar year'),
    ('date_grains', 'career', 'Career', 10, 'Full career'),
    ('date_grains', 'custom', 'Custom', 11, 'User-defined range')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('time_types', 'shot', 'Shot', 1, 'micro'),
    ('time_types', 'hole', 'Hole', 2, 'micro'),
    ('time_types', 'front_9', 'Front 9', 3, 'micro'),
    ('time_types', 'back_9', 'Back 9', 4, 'micro'),
    ('time_types', 'round', 'Round', 5, 'micro'),
    ('time_types', 'event_round', 'Event Round', 6, 'event'),
    ('time_types', 'event', 'Event', 7, 'event'),
    ('time_types', 'event_to_date', 'Event To Date', 8, 'event'),
    ('time_types', 'last_7_days', 'Last 7 Days', 9, 'rolling'),
    ('time_types', 'last_14_days', 'Last 14 Days', 10, 'rolling'),
    ('time_types', 'last_30_days', 'Last 30 Days', 11, 'rolling'),
    ('time_types', 'last_60_days', 'Last 60 Days', 12, 'rolling'),
    ('time_types', 'last_90_days', 'Last 90 Days', 13, 'rolling'),
    ('time_types', 'season_to_date', 'Season To Date', 14, 'season'),
    ('time_types', 'season', 'Season', 15, 'season'),
    ('time_types', 'previous_season', 'Previous Season', 16, 'season'),
    ('time_types', 'two_seasons', 'Two Seasons', 17, 'season'),
    ('time_types', 'three_seasons', 'Three Seasons', 18, 'season'),
    ('time_types', 'five_seasons', 'Five Seasons', 19, 'season'),
    ('time_types', 'career', 'Career', 20, 'career'),
    ('time_types', 'course_history', 'Course History', 21, 'history'),
    ('time_types', 'event_history', 'Event History', 22, 'history'),
    ('time_types', 'rank_snapshot', 'Rank Snapshot', 23, 'snapshot'),
    ('time_types', 'model_run', 'Model Run', 24, 'model'),
    ('time_types', 'projection_window', 'Projection Window', 25, 'model'),
    ('time_types', 'simulation_run', 'Simulation Run', 26, 'model'),
    ('time_types', 'custom_window', 'Custom Window', 27, 'custom'),
    ('time_types', 'year_to_date', 'Year To Date', 28, 'calendar'),
    ('time_types', 'season_first_half', 'First Half of Season', 29, 'season'),
    ('time_types', 'season_second_half', 'Second Half of Season', 30, 'season')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('tee_time_types', 'early_morning', 'Early Morning', 1, NULL),
    ('tee_time_types', 'morning', 'Morning', 2, NULL),
    ('tee_time_types', 'late_morning', 'Late Morning', 3, NULL),
    ('tee_time_types', 'midday', 'Midday', 4, NULL),
    ('tee_time_types', 'afternoon', 'Afternoon', 5, NULL),
    ('tee_time_types', 'late_afternoon', 'Late Afternoon', 6, NULL),
    ('tee_time_types', 'evening', 'Evening', 7, NULL),
    ('tee_time_types', 'am_wave', 'AM Wave', 8, NULL),
    ('tee_time_types', 'pm_wave', 'PM Wave', 9, NULL),
    ('tee_time_types', 'am_pm_wave', 'AM / PM Wave', 10, NULL),
    ('tee_time_types', 'pm_am_wave', 'PM / AM Wave', 11, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('round_types', 'practice', 'Practice', 1, 'Practice round'),
    ('round_types', 'pro_am', 'Pro-Am', 2, 'Pro-am round'),
    ('round_types', 'round_1', 'Round 1', 3, 'First tournament round'),
    ('round_types', 'round_2', 'Round 2', 4, 'Second tournament round'),
    ('round_types', 'round_3', 'Round 3', 5, 'Third tournament round'),
    ('round_types', 'round_4', 'Round 4', 6, 'Fourth tournament round'),
    ('round_types', 'playoff', 'Playoff', 7, 'Playoff holes'),
    ('round_types', 'makeup_round', 'Makeup Round', 8, 'Completed after delay'),
    ('round_types', 'suspended_round', 'Suspended Round', 9, 'Interrupted round')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('weather_types', 'sunny', 'Sunny', 1, NULL),
    ('weather_types', 'cloudy_overcast', 'Cloudy / Overcast', 2, NULL),
    ('weather_types', 'precipitation', 'Precipitation', 3, NULL),
    ('weather_types', 'windy', 'Windy', 4, NULL),
    ('weather_types', 'storms_severe', 'Storms / Severe', 5, NULL),
    ('weather_types', 'obscurations', 'Obscurations', 6, NULL),
    ('weather_types', 'extreme_heat', 'Extreme Heat', 7, NULL),
    ('weather_types', 'cold', 'Cold', 8, NULL),
    ('weather_types', 'mixed', 'Mixed', 9, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('weather_conditions', 'clear', 'Clear', 1, 'sunny'),
    ('weather_conditions', 'mostly_sunny', 'Mostly Sunny', 2, 'sunny'),
    ('weather_conditions', 'partly_cloudy', 'Partly Cloudy', 3, 'cloudy_overcast'),
    ('weather_conditions', 'mostly_cloudy', 'Mostly Cloudy', 4, 'cloudy_overcast'),
    ('weather_conditions', 'overcast', 'Overcast', 5, 'cloudy_overcast'),
    ('weather_conditions', 'light_rain', 'Light Rain', 6, 'precipitation'),
    ('weather_conditions', 'moderate_rain', 'Moderate Rain', 7, 'precipitation'),
    ('weather_conditions', 'heavy_rain', 'Heavy Rain', 8, 'precipitation'),
    ('weather_conditions', 'showers', 'Showers', 9, 'precipitation'),
    ('weather_conditions', 'thunderstorm', 'Thunderstorm', 10, 'storms_severe'),
    ('weather_conditions', 'lightning_delay', 'Lightning Delay', 11, 'storms_severe'),
    ('weather_conditions', 'high_wind', 'High Wind', 12, 'windy'),
    ('weather_conditions', 'gusty', 'Gusty', 13, 'windy'),
    ('weather_conditions', 'fog', 'Fog', 14, 'obscurations'),
    ('weather_conditions', 'haze', 'Haze', 15, 'obscurations'),
    ('weather_conditions', 'smoke', 'Smoke', 16, 'obscurations'),
    ('weather_conditions', 'hot', 'Hot', 17, 'extreme_heat'),
    ('weather_conditions', 'cold', 'Cold', 18, 'cold'),
    ('weather_conditions', 'freezing', 'Freezing', 19, 'cold')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('wind_types', 'calm', 'Calm', 1, '0-3'),
    ('wind_types', 'light_breeze', 'Light Breeze', 2, '4-7'),
    ('wind_types', 'breeze', 'Breeze', 3, '8-12'),
    ('wind_types', 'moderate_wind', 'Moderate Wind', 4, '13-18'),
    ('wind_types', 'strong_wind', 'Strong Wind', 5, '19-25'),
    ('wind_types', 'very_strong_wind', 'Very Strong Wind', 6, '26-35'),
    ('wind_types', 'dangerous_wind', 'Dangerous Wind', 7, '36+')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('wind_directions', 'n', 'North', 1, '0'),
    ('wind_directions', 'nne', 'North-Northeast', 2, '22.5'),
    ('wind_directions', 'ne', 'Northeast', 3, '45'),
    ('wind_directions', 'ene', 'East-Northeast', 4, '67.5'),
    ('wind_directions', 'e', 'East', 5, '90'),
    ('wind_directions', 'ese', 'East-Southeast', 6, '112.5'),
    ('wind_directions', 'se', 'Southeast', 7, '135'),
    ('wind_directions', 'sse', 'South-Southeast', 8, '157.5'),
    ('wind_directions', 's', 'South', 9, '180'),
    ('wind_directions', 'ssw', 'South-Southwest', 10, '202.5'),
    ('wind_directions', 'sw', 'Southwest', 11, '225'),
    ('wind_directions', 'wsw', 'West-Southwest', 12, '247.5'),
    ('wind_directions', 'w', 'West', 13, '270'),
    ('wind_directions', 'wnw', 'West-Northwest', 14, '292.5'),
    ('wind_directions', 'nw', 'Northwest', 15, '315'),
    ('wind_directions', 'nnw', 'North-Northwest', 16, '337.5'),
    ('wind_directions', 'variable', 'Variable', 17, 'NULL')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('temperature_bands', 'freezing', 'Freezing', 1, '<32'),
    ('temperature_bands', 'very_cold', 'Very Cold', 2, '32-44'),
    ('temperature_bands', 'cold', 'Cold', 3, '45-54'),
    ('temperature_bands', 'cool', 'Cool', 4, '55-64'),
    ('temperature_bands', 'mild', 'Mild', 5, '65-74'),
    ('temperature_bands', 'warm', 'Warm', 6, '75-84'),
    ('temperature_bands', 'hot', 'Hot', 7, '85-94'),
    ('temperature_bands', 'very_hot', 'Very Hot', 8, '95-104'),
    ('temperature_bands', 'extreme_heat', 'Extreme Heat', 9, '105+')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('precipitation_types', 'none', 'None', 1, NULL),
    ('precipitation_types', 'mist', 'Mist', 2, NULL),
    ('precipitation_types', 'drizzle', 'Drizzle', 3, NULL),
    ('precipitation_types', 'light_rain', 'Light Rain', 4, NULL),
    ('precipitation_types', 'moderate_rain', 'Moderate Rain', 5, NULL),
    ('precipitation_types', 'heavy_rain', 'Heavy Rain', 6, NULL),
    ('precipitation_types', 'showers', 'Showers', 7, NULL),
    ('precipitation_types', 'thunderstorm_rain', 'Thunderstorm Rain', 8, NULL),
    ('precipitation_types', 'snow', 'Snow', 9, NULL),
    ('precipitation_types', 'sleet', 'Sleet', 10, NULL),
    ('precipitation_types', 'hail', 'Hail', 11, NULL),
    ('precipitation_types', 'mixed_precipitation', 'Mixed Precipitation', 12, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('climate_zones', 'tropical_wet', 'Tropical Wet', 1, NULL),
    ('climate_zones', 'tropical_wet_dry', 'Tropical Wet and Dry', 2, NULL),
    ('climate_zones', 'desert', 'Desert', 3, NULL),
    ('climate_zones', 'semiarid', 'Semiarid', 4, NULL),
    ('climate_zones', 'mediterranean', 'Mediterranean', 5, NULL),
    ('climate_zones', 'marine_west_coast', 'Marine West Coast', 6, NULL),
    ('climate_zones', 'humid_subtropical', 'Humid Subtropical', 7, NULL),
    ('climate_zones', 'humid_continental', 'Humid Continental', 8, NULL),
    ('climate_zones', 'subarctic', 'Subarctic', 9, NULL),
    ('climate_zones', 'highland', 'Highland', 10, NULL),
    ('climate_zones', 'coastal', 'Coastal', 11, NULL),
    ('climate_zones', 'inland', 'Inland', 12, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('course_environment_types', 'coastal', 'Coastal', 1, NULL),
    ('course_environment_types', 'inland', 'Inland', 2, NULL),
    ('course_environment_types', 'mountain', 'Mountain', 3, NULL),
    ('course_environment_types', 'desert', 'Desert', 4, NULL),
    ('course_environment_types', 'woodland', 'Woodland', 5, NULL),
    ('course_environment_types', 'prairie', 'Prairie', 6, NULL),
    ('course_environment_types', 'tropical', 'Tropical', 7, NULL),
    ('course_environment_types', 'urban', 'Urban', 8, NULL),
    ('course_environment_types', 'resort', 'Resort', 9, NULL),
    ('course_environment_types', 'linksland', 'Linksland', 10, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('value_types', 'integer', 'Integer', 1, 'Whole number'),
    ('value_types', 'decimal', 'Decimal', 2, 'Numeric decimal'),
    ('value_types', 'percent', 'Percent', 3, 'Percentage'),
    ('value_types', 'money', 'Money', 4, 'Currency value'),
    ('value_types', 'text', 'Text', 5, 'String/text'),
    ('value_types', 'boolean', 'Boolean', 6, 'True/false'),
    ('value_types', 'date', 'Date', 7, 'Date only'),
    ('value_types', 'datetime', 'DateTime', 8, 'Date and time'),
    ('value_types', 'json', 'JSON', 9, 'Structured JSON'),
    ('value_types', 'array', 'Array', 10, 'List/array'),
    ('value_types', 'rank', 'Rank', 11, 'Ordered rank'),
    ('value_types', 'score', 'Score', 12, 'Model or rating score')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('stat_directions', 'higher_better', 'Higher Better', 1, NULL),
    ('stat_directions', 'lower_better', 'Lower Better', 2, NULL),
    ('stat_directions', 'neutral', 'Neutral', 3, NULL),
    ('stat_directions', 'context_dependent', 'Context Dependent', 4, NULL),
    ('stat_directions', 'boolean_true_good', 'Boolean True Good', 5, NULL),
    ('stat_directions', 'boolean_false_good', 'Boolean False Good', 6, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('scale_types', 'zero_to_one', '0 to 1', 1, 'Probability-style scale'),
    ('scale_types', 'zero_to_100', '0 to 100', 2, 'Rating/percentile scale'),
    ('scale_types', 'one_to_10', '1 to 10', 3, 'Simple rating scale'),
    ('scale_types', 'z_score', 'Z-Score', 4, 'Standardized score'),
    ('scale_types', 'percentile', 'Percentile', 5, 'Population percentile'),
    ('scale_types', 'rank_order', 'Rank Order', 6, 'Ranking scale'),
    ('scale_types', 'raw_value', 'Raw Value', 7, 'Unscaled value'),
    ('scale_types', 'custom', 'Custom', 8, 'Custom scale'),
    ('scale_types', 'minus_50_to_50', '−50 to +50', 9, 'Player behavior rating scale')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('player_statuses', 'amateur', 'Amateur', 1, NULL),
    ('player_statuses', 'professional', 'Professional', 2, NULL),
    ('player_statuses', 'rookie', 'Rookie', 3, NULL),
    ('player_statuses', 'active', 'Active', 4, NULL),
    ('player_statuses', 'injured', 'Injured', 5, NULL),
    ('player_statuses', 'suspended', 'Suspended', 6, NULL),
    ('player_statuses', 'retired', 'Retired', 7, NULL),
    ('player_statuses', 'deceased', 'Deceased', 8, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('handedness_types', 'right', 'Right-Handed', 1, NULL),
    ('handedness_types', 'left', 'Left-Handed', 2, NULL),
    ('handedness_types', 'ambidextrous', 'Ambidextrous', 3, NULL),
    ('handedness_types', 'unknown', 'Unknown', 4, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('golf_scores', 'hole_in_one', 'Hole In One', 1, 'special'),
    ('golf_scores', 'condor', 'Condor', 2, '-4'),
    ('golf_scores', 'albatross', 'Albatross / Double Eagle', 3, '-3'),
    ('golf_scores', 'eagle', 'Eagle', 4, '-2'),
    ('golf_scores', 'birdie', 'Birdie', 5, '-1'),
    ('golf_scores', 'par', 'Par', 6, '0'),
    ('golf_scores', 'bogey', 'Bogey', 7, '+1'),
    ('golf_scores', 'double_bogey', 'Double Bogey', 8, '+2'),
    ('golf_scores', 'triple_bogey', 'Triple Bogey', 9, '+3'),
    ('golf_scores', 'quad_or_worse', '+4 Or Worse', 10, '+4+')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('par_types', 'par_3', 'Par 3', 1, NULL),
    ('par_types', 'par_4', 'Par 4', 2, NULL),
    ('par_types', 'par_5', 'Par 5', 3, NULL),
    ('par_types', 'par_6', 'Par 6', 4, NULL),
    ('par_types', 'unknown', 'Unknown', 5, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('course_surfaces', 'bentgrass', 'Bentgrass', 1, 'grass'),
    ('course_surfaces', 'bermuda', 'Bermuda', 2, 'grass'),
    ('course_surfaces', 'poa_annua', 'Poa Annua', 3, 'grass'),
    ('course_surfaces', 'zoysia', 'Zoysia', 4, 'grass'),
    ('course_surfaces', 'ryegrass', 'Ryegrass', 5, 'grass'),
    ('course_surfaces', 'fescue', 'Fescue', 6, 'grass'),
    ('course_surfaces', 'paspalum', 'Paspalum', 7, 'grass'),
    ('course_surfaces', 'sand', 'Sand', 8, 'hazard_surface'),
    ('course_surfaces', 'water', 'Water', 9, 'hazard_surface'),
    ('course_surfaces', 'hardpan', 'Hardpan', 10, 'natural_surface'),
    ('course_surfaces', 'pine_straw', 'Pine Straw', 11, 'natural_surface'),
    ('course_surfaces', 'native_grass', 'Native Grass', 12, 'natural_surface')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('course_terrain_types', 'tee_box', 'Tee Box', 1, 'starting_area'),
    ('course_terrain_types', 'fairway', 'Fairway', 2, 'primary_playing_surface'),
    ('course_terrain_types', 'first_cut', 'First Cut', 3, 'secondary_playing_surface'),
    ('course_terrain_types', 'rough', 'Rough', 4, 'penalty_surface'),
    ('course_terrain_types', 'deep_rough', 'Deep Rough', 5, 'penalty_surface'),
    ('course_terrain_types', 'native_area', 'Native Area', 6, 'natural_area'),
    ('course_terrain_types', 'heather', 'Heather', 7, 'natural_area'),
    ('course_terrain_types', 'fescue', 'Fescue', 8, 'natural_area'),
    ('course_terrain_types', 'pine_straw', 'Pine Straw', 9, 'natural_area'),
    ('course_terrain_types', 'trees', 'Trees', 10, 'obstruction'),
    ('course_terrain_types', 'woods', 'Woods', 11, 'obstruction'),
    ('course_terrain_types', 'desert', 'Desert', 12, 'natural_area'),
    ('course_terrain_types', 'waste_area', 'Waste Area', 13, 'natural_area'),
    ('course_terrain_types', 'bunker', 'Bunker', 14, 'hazard'),
    ('course_terrain_types', 'fairway_bunker', 'Fairway Bunker', 15, 'hazard'),
    ('course_terrain_types', 'greenside_bunker', 'Greenside Bunker', 16, 'hazard'),
    ('course_terrain_types', 'water', 'Water', 17, 'hazard'),
    ('course_terrain_types', 'creek', 'Creek', 18, 'hazard'),
    ('course_terrain_types', 'pond', 'Pond', 19, 'hazard'),
    ('course_terrain_types', 'out_of_bounds', 'Out Of Bounds', 20, 'penalty_area'),
    ('course_terrain_types', 'penalty_area', 'Penalty Area', 21, 'penalty_area'),
    ('course_terrain_types', 'cart_path', 'Cart Path', 22, 'man_made'),
    ('course_terrain_types', 'road', 'Road', 23, 'man_made'),
    ('course_terrain_types', 'grandstand', 'Grandstand', 24, 'man_made'),
    ('course_terrain_types', 'fringe', 'Fringe', 25, 'green_complex'),
    ('course_terrain_types', 'collar', 'Collar', 26, 'green_complex'),
    ('course_terrain_types', 'green', 'Green', 27, 'green_complex'),
    ('course_terrain_types', 'false_front', 'False Front', 28, 'green_complex'),
    ('course_terrain_types', 'runoff_area', 'Runoff Area', 29, 'green_complex'),
    ('course_terrain_types', 'collection_area', 'Collection Area', 30, 'green_complex'),
    ('course_terrain_types', 'slope', 'Slope', 31, 'topography'),
    ('course_terrain_types', 'elevation_change', 'Elevation Change', 32, 'topography'),
    ('course_terrain_types', 'blind_shot_area', 'Blind Shot Area', 33, 'topography')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('club_types', 'driver', 'Driver', 1, 'wood'),
    ('club_types', '3_wood', '3 Wood', 2, 'wood'),
    ('club_types', '5_wood', '5 Wood', 3, 'wood'),
    ('club_types', 'hybrid', 'Hybrid', 4, 'hybrid'),
    ('club_types', 'long_iron', 'Long Iron', 5, 'iron'),
    ('club_types', 'mid_iron', 'Mid Iron', 6, 'iron'),
    ('club_types', 'short_iron', 'Short Iron', 7, 'iron'),
    ('club_types', 'pitching_wedge', 'Pitching Wedge', 8, 'wedge'),
    ('club_types', 'gap_wedge', 'Gap Wedge', 9, 'wedge'),
    ('club_types', 'sand_wedge', 'Sand Wedge', 10, 'wedge'),
    ('club_types', 'lob_wedge', 'Lob Wedge', 11, 'wedge'),
    ('club_types', 'putter', 'Putter', 12, 'putter'),
    ('club_types', 'unknown', 'Unknown', 13, 'unknown')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('shot_types', 'tee_shot', 'Tee Shot', 1, NULL),
    ('shot_types', 'approach', 'Approach', 2, NULL),
    ('shot_types', 'layup', 'Layup', 3, NULL),
    ('shot_types', 'recovery', 'Recovery', 4, NULL),
    ('shot_types', 'chip', 'Chip', 5, NULL),
    ('shot_types', 'pitch', 'Pitch', 6, NULL),
    ('shot_types', 'bunker_shot', 'Bunker Shot', 7, NULL),
    ('shot_types', 'flop', 'Flop Shot', 8, NULL),
    ('shot_types', 'putt', 'Putt', 9, NULL),
    ('shot_types', 'penalty_drop', 'Penalty Drop', 10, NULL),
    ('shot_types', 'provisional', 'Provisional', 11, NULL),
    ('shot_types', 'tap_in', 'Tap-In', 12, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('shot_shapes', 'straight', 'Straight', 1, NULL),
    ('shot_shapes', 'draw', 'Draw', 2, NULL),
    ('shot_shapes', 'fade', 'Fade', 3, NULL),
    ('shot_shapes', 'hook', 'Hook', 4, NULL),
    ('shot_shapes', 'slice', 'Slice', 5, NULL),
    ('shot_shapes', 'pull', 'Pull', 6, NULL),
    ('shot_shapes', 'push', 'Push', 7, NULL),
    ('shot_shapes', 'high', 'High', 8, NULL),
    ('shot_shapes', 'low', 'Low', 9, NULL),
    ('shot_shapes', 'knockdown', 'Knockdown', 10, NULL),
    ('shot_shapes', 'stinger', 'Stinger', 11, NULL),
    ('shot_shapes', 'unknown', 'Unknown', 12, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('tour_types', 'pga_tour', 'PGA TOUR', 1, NULL),
    ('tour_types', 'dp_world_tour', 'DP World Tour', 2, NULL),
    ('tour_types', 'liv_golf', 'LIV Golf', 3, NULL),
    ('tour_types', 'korn_ferry_tour', 'Korn Ferry Tour', 4, NULL),
    ('tour_types', 'pga_tour_champions', 'PGA TOUR Champions', 5, NULL),
    ('tour_types', 'lpga', 'LPGA', 6, NULL),
    ('tour_types', 'college', 'College', 7, NULL),
    ('tour_types', 'amateur', 'Amateur', 8, NULL),
    ('tour_types', 'international', 'International', 9, NULL),
    ('tour_types', 'custom', 'Custom', 10, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('field_strength_tiers', 'elite', 'Elite', 1, NULL),
    ('field_strength_tiers', 'strong', 'Strong', 2, NULL),
    ('field_strength_tiers', 'average', 'Average', 3, NULL),
    ('field_strength_tiers', 'weak', 'Weak', 4, NULL),
    ('field_strength_tiers', 'opposite_field', 'Opposite Field', 5, NULL),
    ('field_strength_tiers', 'major_field', 'Major Field', 6, NULL),
    ('field_strength_tiers', 'signature_field', 'Signature Field', 7, NULL),
    ('field_strength_tiers', 'limited_field', 'Limited Field', 8, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('result_statuses', 'complete', 'Complete', 1, NULL),
    ('result_statuses', 'active', 'Active', 2, NULL),
    ('result_statuses', 'missed_cut', 'Missed Cut', 3, NULL),
    ('result_statuses', 'made_cut', 'Made Cut', 4, NULL),
    ('result_statuses', 'withdrawn', 'Withdrawn', 5, NULL),
    ('result_statuses', 'disqualified', 'Disqualified', 6, NULL),
    ('result_statuses', 'did_not_start', 'Did Not Start', 7, NULL),
    ('result_statuses', 'did_not_finish', 'Did Not Finish', 8, NULL),
    ('result_statuses', 'no_card', 'No Card', 9, NULL),
    ('result_statuses', 'suspended', 'Suspended', 10, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('stat_types', 'standard', 'Standard', 1, NULL),
    ('stat_types', 'advanced', 'Advanced', 2, NULL),
    ('stat_types', 'strokes_gained', 'Strokes Gained', 3, NULL),
    ('stat_types', 'model_metric', 'Model Metric', 4, NULL),
    ('stat_types', 'percentile', 'Percentile', 5, NULL),
    ('stat_types', 'rating', 'Rating', 6, NULL),
    ('stat_types', 'ranking', 'Ranking', 7, NULL),
    ('stat_types', 'trend', 'Trend', 8, NULL),
    ('stat_types', 'projection', 'Projection', 9, NULL),
    ('stat_types', 'simulation', 'Simulation', 10, NULL),
    ('stat_types', 'snapshot', 'Snapshot', 11, NULL),
    ('stat_types', 'split', 'Split', 12, NULL),
    ('stat_types', 'aggregate', 'Aggregate', 13, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('stat_categories', 'overview', 'Overview', 1, NULL),
    ('stat_categories', 'strokes_gained', 'Strokes Gained', 2, NULL),
    ('stat_categories', 'off_the_tee', 'Off The Tee', 3, NULL),
    ('stat_categories', 'approach', 'Approach', 4, NULL),
    ('stat_categories', 'around_green', 'Around Green', 5, NULL),
    ('stat_categories', 'putting', 'Putting', 6, NULL),
    ('stat_categories', 'scoring', 'Scoring', 7, NULL),
    ('stat_categories', 'streaks', 'Streaks', 8, NULL),
    ('stat_categories', 'money_finishes', 'Money / Finishes', 9, NULL),
    ('stat_categories', 'points_rankings', 'Points / Rankings', 10, NULL),
    ('stat_categories', 'course_fit', 'Course Fit', 11, NULL),
    ('stat_categories', 'weather', 'Weather', 12, NULL),
    ('stat_categories', 'surface', 'Surface', 13, NULL),
    ('stat_categories', 'simulation', 'Simulation', 16, NULL),
    ('stat_categories', 'projection', 'Projection', 17, NULL),
    ('stat_categories', 'modeling', 'Modeling', 18, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('stat_coverage_types', 'full', 'Full', 1, NULL),
    ('stat_coverage_types', 'partial', 'Partial', 2, NULL),
    ('stat_coverage_types', 'estimated', 'Estimated', 3, NULL),
    ('stat_coverage_types', 'manual', 'Manual', 4, NULL),
    ('stat_coverage_types', 'official', 'Official', 5, NULL),
    ('stat_coverage_types', 'unverified', 'Unverified', 6, NULL),
    ('stat_coverage_types', 'missing', 'Missing', 7, NULL),
    ('stat_coverage_types', 'not_applicable', 'Not Applicable', 8, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('calculation_methods', 'raw_source', 'Raw Source', 1, NULL),
    ('calculation_methods', 'sum', 'Sum', 2, NULL),
    ('calculation_methods', 'average', 'Average', 3, NULL),
    ('calculation_methods', 'median', 'Median', 4, NULL),
    ('calculation_methods', 'min', 'Minimum', 5, NULL),
    ('calculation_methods', 'max', 'Maximum', 6, NULL),
    ('calculation_methods', 'rate', 'Rate', 7, NULL),
    ('calculation_methods', 'percentage', 'Percentage', 8, NULL),
    ('calculation_methods', 'weighted_average', 'Weighted Average', 9, NULL),
    ('calculation_methods', 'rolling_average', 'Rolling Average', 10, NULL),
    ('calculation_methods', 'z_score', 'Z-Score', 11, NULL),
    ('calculation_methods', 'percentile_rank', 'Percentile Rank', 12, NULL),
    ('calculation_methods', 'model_formula', 'Model Formula', 13, NULL),
    ('calculation_methods', 'simulation', 'Simulation', 14, NULL),
    ('calculation_methods', 'manual_override', 'Manual Override', 15, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('source_file_types', 'csv', 'CSV', 1, NULL),
    ('source_file_types', 'xlsx', 'Excel', 2, NULL),
    ('source_file_types', 'json', 'JSON', 3, NULL),
    ('source_file_types', 'xml', 'XML', 4, NULL),
    ('source_file_types', 'parquet', 'Parquet', 5, NULL),
    ('source_file_types', 'pdf', 'PDF', 6, NULL),
    ('source_file_types', 'html', 'HTML', 7, NULL),
    ('source_file_types', 'api_response', 'API Response', 8, NULL),
    ('source_file_types', 'manual_entry', 'Manual Entry', 9, NULL),
    ('source_file_types', 'image', 'Image', 10, NULL),
    ('source_file_types', 'markdown', 'Markdown', 11, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('import_frequencies', 'real_time', 'Real Time', 1, NULL),
    ('import_frequencies', 'hourly', 'Hourly', 2, NULL),
    ('import_frequencies', 'daily', 'Daily', 3, NULL),
    ('import_frequencies', 'weekly', 'Weekly', 4, NULL),
    ('import_frequencies', 'event_based', 'Event Based', 5, NULL),
    ('import_frequencies', 'seasonal', 'Seasonal', 6, NULL),
    ('import_frequencies', 'manual', 'Manual', 7, NULL),
    ('import_frequencies', 'ad_hoc', 'Ad Hoc', 8, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('import_statuses', 'pending', 'Pending', 1, NULL),
    ('import_statuses', 'running', 'Running', 2, NULL),
    ('import_statuses', 'complete', 'Complete', 3, NULL),
    ('import_statuses', 'complete_with_warnings', 'Complete With Warnings', 4, NULL),
    ('import_statuses', 'failed', 'Failed', 5, NULL),
    ('import_statuses', 'cancelled', 'Cancelled', 6, NULL),
    ('import_statuses', 'retrying', 'Retrying', 7, NULL),
    ('import_statuses', 'skipped', 'Skipped', 8, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('data_quality_statuses', 'valid', 'Valid', 1, NULL),
    ('data_quality_statuses', 'warning', 'Warning', 2, NULL),
    ('data_quality_statuses', 'error', 'Error', 3, NULL),
    ('data_quality_statuses', 'missing_required', 'Missing Required', 4, NULL),
    ('data_quality_statuses', 'duplicate', 'Duplicate', 5, NULL),
    ('data_quality_statuses', 'outlier', 'Outlier', 6, NULL),
    ('data_quality_statuses', 'stale', 'Stale', 7, NULL),
    ('data_quality_statuses', 'unverified', 'Unverified', 8, NULL),
    ('data_quality_statuses', 'manually_verified', 'Manually Verified', 9, NULL),
    ('data_quality_statuses', 'source_conflict', 'Source Conflict', 10, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('confidence_levels', 'very_low', 'Very Low', 1, '0-20'),
    ('confidence_levels', 'low', 'Low', 2, '21-40'),
    ('confidence_levels', 'medium', 'Medium', 3, '41-60'),
    ('confidence_levels', 'high', 'High', 4, '61-80'),
    ('confidence_levels', 'very_high', 'Very High', 5, '81-100')
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('verification_statuses', 'unverified', 'Unverified', 1, NULL),
    ('verification_statuses', 'source_verified', 'Source Verified', 2, NULL),
    ('verification_statuses', 'manual_verified', 'Manual Verified', 3, NULL),
    ('verification_statuses', 'cross_verified', 'Cross Verified', 4, NULL),
    ('verification_statuses', 'model_estimated', 'Model Estimated', 5, NULL),
    ('verification_statuses', 'deprecated', 'Deprecated', 6, NULL),
    ('verification_statuses', 'rejected', 'Rejected', 7, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('model_types', 'rating', 'Rating Model', 1, NULL),
    ('model_types', 'ranking', 'Ranking Model', 2, NULL),
    ('model_types', 'projection', 'Projection Model', 3, NULL),
    ('model_types', 'classification', 'Classification Model', 4, NULL),
    ('model_types', 'simulation', 'Simulation Model', 5, NULL),
    ('model_types', 'probability', 'Probability Model', 6, NULL),
    ('model_types', 'course_fit', 'Course Fit Model', 7, NULL),
    ('model_types', 'weather_fit', 'Weather Fit Model', 8, NULL),
    ('model_types', 'trend_model', 'Trend Model', 11, NULL),
    ('model_types', 'risk_model', 'Risk Model', 12, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('model_run_statuses', 'queued', 'Queued', 1, NULL),
    ('model_run_statuses', 'running', 'Running', 2, NULL),
    ('model_run_statuses', 'complete', 'Complete', 3, NULL),
    ('model_run_statuses', 'failed', 'Failed', 4, NULL),
    ('model_run_statuses', 'cancelled', 'Cancelled', 5, NULL),
    ('model_run_statuses', 'stale', 'Stale', 6, NULL),
    ('model_run_statuses', 'archived', 'Archived', 7, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('model_output_types', 'score', 'Score', 1, NULL),
    ('model_output_types', 'rating', 'Rating', 2, NULL),
    ('model_output_types', 'rank', 'Rank', 3, NULL),
    ('model_output_types', 'percentile', 'Percentile', 4, NULL),
    ('model_output_types', 'probability', 'Probability', 5, NULL),
    ('model_output_types', 'projection', 'Projection', 6, NULL),
    ('model_output_types', 'classification', 'Classification', 7, NULL),
    ('model_output_types', 'recommendation', 'Recommendation', 8, NULL),
    ('model_output_types', 'flag', 'Flag', 9, NULL),
    ('model_output_types', 'explanation', 'Explanation', 10, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('content_types', 'article', 'Article', 1, NULL),
    ('content_types', 'blog_post', 'Blog Post', 2, NULL),
    ('content_types', 'tournament_preview', 'Tournament Preview', 3, NULL),
    ('content_types', 'course_preview', 'Course Preview', 4, NULL),
    ('content_types', 'player_breakdown', 'Player Breakdown', 7, NULL),
    ('content_types', 'model_report', 'Model Report', 8, NULL),
    ('content_types', 'weekly_recap', 'Weekly Recap', 9, NULL),
    ('content_types', 'newsletter', 'Newsletter', 10, NULL),
    ('content_types', 'social_post', 'Social Post', 11, NULL),
    ('content_types', 'video_script', 'Video Script', 12, NULL),
    ('content_types', 'dashboard_embed', 'Dashboard Embed', 13, NULL),
    ('content_types', 'transcript', 'Transcript', 14, NULL),
    ('content_types', 'video', 'Video', 15, NULL),
    ('content_types', 'pdf', 'PDF', 16, NULL),
    ('content_types', 'rss_item', 'RSS Item', 17, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('publish_statuses', 'draft', 'Draft', 1, NULL),
    ('publish_statuses', 'review', 'Review', 2, NULL),
    ('publish_statuses', 'scheduled', 'Scheduled', 3, NULL),
    ('publish_statuses', 'published', 'Published', 4, NULL),
    ('publish_statuses', 'updated', 'Updated', 5, NULL),
    ('publish_statuses', 'archived', 'Archived', 6, NULL),
    ('publish_statuses', 'deleted', 'Deleted', 7, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('job_statuses', 'queued', 'Queued', 1, NULL),
    ('job_statuses', 'running', 'Running', 2, NULL),
    ('job_statuses', 'success', 'Success', 3, NULL),
    ('job_statuses', 'success_with_warnings', 'Success With Warnings', 4, NULL),
    ('job_statuses', 'failed', 'Failed', 5, NULL),
    ('job_statuses', 'cancelled', 'Cancelled', 6, NULL),
    ('job_statuses', 'retrying', 'Retrying', 7, NULL),
    ('job_statuses', 'paused', 'Paused', 8, NULL),
    ('job_statuses', 'skipped', 'Skipped', 9, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('odds_formats', 'american', 'American', 1, NULL),
    ('odds_formats', 'decimal', 'Decimal', 2, NULL),
    ('odds_formats', 'fractional', 'Fractional', 3, NULL),
    ('odds_formats', 'implied_probability', 'Implied Probability', 4, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

INSERT INTO core.lookup_values (lookup_group, code, name, sort_order, detail) VALUES
    ('bet_market_types', 'outright_winner', 'Outright Winner', 1, NULL),
    ('bet_market_types', 'top_5', 'Top 5', 2, NULL),
    ('bet_market_types', 'top_10', 'Top 10', 3, NULL),
    ('bet_market_types', 'top_20', 'Top 20', 4, NULL),
    ('bet_market_types', 'make_cut', 'Make Cut', 5, NULL),
    ('bet_market_types', 'miss_cut', 'Miss Cut', 6, NULL),
    ('bet_market_types', 'matchup', 'Matchup', 7, NULL),
    ('bet_market_types', 'three_ball', 'Three Ball', 8, NULL),
    ('bet_market_types', 'first_round_leader', 'First Round Leader', 9, NULL),
    ('bet_market_types', 'round_score', 'Round Score', 10, NULL),
    ('bet_market_types', 'nationality_top', 'Top Nationality', 11, NULL),
    ('bet_market_types', 'group_winner', 'Group Winner', 12, NULL),
    ('bet_market_types', 'nationality_outright', 'Outright Winner by Nationality', 15, NULL)
ON CONFLICT (lookup_group, code) DO NOTHING;

-- Nullable reference links preserve preexisting rows and existing importer inputs.
-- The foundation creates these domain tables in the public schema.
ALTER TABLE public.events
    ADD COLUMN IF NOT EXISTS event_type_code TEXT REFERENCES core.event_types(code),
    ADD COLUMN IF NOT EXISTS event_status_code TEXT REFERENCES core.event_statuses(code),
    ADD COLUMN IF NOT EXISTS cut_rule_code TEXT REFERENCES core.cut_rules(code);

ALTER TABLE public.courses
    ADD COLUMN IF NOT EXISTS course_theme_code TEXT REFERENCES core.course_themes(code),
    ADD COLUMN IF NOT EXISTS timezone_name TEXT REFERENCES core.time_zones(timezone_name);

COMMIT;
