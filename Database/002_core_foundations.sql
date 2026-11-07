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
    ('stat_directions
