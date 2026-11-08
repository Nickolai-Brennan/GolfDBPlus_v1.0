-- Call after staging, normalization, and identity resolution. Current rows accept
-- only newer observations. Immutable rows use their observation or run key.
-- Send a complete normalized row. NULL represents a known missing value.

PREPARE write_player_info(uuid, text, text, date, text, text, text, boolean, smallint, text, bigint) AS
INSERT INTO analytics.player_info AS prior
    (player_id, given_name, family_name, birth_date, birthplace, residence, college, is_amateur, turned_pro_year, headshot_url, observation_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (player_id) DO UPDATE SET
    given_name = excluded.given_name,
    family_name = excluded.family_name,
    birth_date = excluded.birth_date,
    birthplace = excluded.birthplace,
    residence = excluded.residence,
    college = excluded.college,
    is_amateur = excluded.is_amateur,
    turned_pro_year = excluded.turned_pro_year,
    headshot_url = excluded.headshot_url,
    observation_id = excluded.observation_id
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_course_info(uuid, numeric, numeric, numeric, bigint) AS
INSERT INTO analytics.course_info AS prior
    (course_id, latitude, longitude, altitude_ft, observation_id)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (course_id) DO UPDATE SET
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    altitude_ft = excluded.altitude_ft,
    observation_id = excluded.observation_id
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_event_info(uuid, numeric, text, numeric, bigint) AS
INSERT INTO analytics.event_info AS prior
    (event_id, purse_amount, purse_currency, winner_fedex_points, observation_id)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (event_id) DO UPDATE SET
    purse_amount = excluded.purse_amount,
    purse_currency = excluded.purse_currency,
    winner_fedex_points = excluded.winner_fedex_points,
    observation_id = excluded.observation_id
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_event_course(uuid, uuid) AS
INSERT INTO analytics.event_course AS prior
    (event_id, course_id)
VALUES ($1, $2)
ON CONFLICT (event_id, course_id) DO NOTHING;

PREPARE write_course_attributes(uuid, text, date, bigint, text, text, text, numeric, numeric, numeric) AS
INSERT INTO analytics.course_attributes AS prior
    (course_id, setup_code, valid_from, observation_id, fairway_grass, rough_grass, green_grass, fairway_width_yards, green_area_sqft, green_speed_ft)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
ON CONFLICT (course_id, setup_code, valid_from, observation_id) DO NOTHING;

PREPARE write_course_scorecard(uuid, uuid, smallint, smallint, smallint, integer, bigint) AS
INSERT INTO analytics.course_scorecard AS prior
    (event_id, course_id, round_number, hole_number, par, yards, observation_id)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (event_id, course_id, round_number, hole_number) DO UPDATE SET
    par = excluded.par,
    yards = excluded.yards,
    observation_id = excluded.observation_id
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_event_leaderboard(uuid, bigint, uuid, integer, text, integer, text, text) AS
INSERT INTO analytics.event_leaderboard AS prior
    (event_id, observation_id, player_id, position, position_display, score_to_par, thru_display, status)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (event_id, observation_id, player_id) DO NOTHING;

PREPARE write_event_results(uuid, uuid, bigint, integer, text, text, integer, integer, numeric, text, numeric) AS
INSERT INTO analytics.event_results AS prior
    (event_id, player_id, observation_id, position, position_display, status, total_strokes, score_to_par, earnings_amount, earnings_currency, fedex_points)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
ON CONFLICT (event_id, player_id, observation_id) DO NOTHING;

PREPARE write_player_round(uuid, uuid, smallint, uuid, bigint, timestamptz, smallint, integer, integer) AS
INSERT INTO analytics.player_round AS prior
    (event_id, player_id, round_number, course_id, observation_id, tee_time, start_hole, strokes, score_to_par)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (event_id, player_id, round_number) DO UPDATE SET
    course_id = excluded.course_id,
    observation_id = excluded.observation_id,
    tee_time = excluded.tee_time,
    start_hole = excluded.start_hole,
    strokes = excluded.strokes,
    score_to_par = excluded.score_to_par
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_player_hole_score(uuid, uuid, smallint, smallint, uuid, bigint, smallint) AS
INSERT INTO analytics.player_hole_score AS prior
    (event_id, player_id, round_number, hole_number, course_id, observation_id, strokes)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (event_id, player_id, round_number, hole_number) DO UPDATE SET
    course_id = excluded.course_id,
    observation_id = excluded.observation_id,
    strokes = excluded.strokes
WHERE (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = excluded.observation_id)
    > (SELECT (observed_at, observation_id) FROM intake.observation
       WHERE observation_id = prior.observation_id)
   OR (prior.observation_id IS NULL AND excluded.observation_id IS NOT NULL);

PREPARE write_course_hole_source_metrics(uuid, uuid, smallint, smallint, bigint, integer, numeric, numeric, integer) AS
INSERT INTO analytics.course_hole_source_metrics AS prior
    (event_id, course_id, round_number, hole_number, observation_id, sample_count, avg_strokes, avg_to_par, source_rank)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (event_id, course_id, round_number, hole_number, observation_id) DO NOTHING;

PREPARE write_player_statistics(uuid, text, uuid, smallint, text, integer, bigint, numeric, text, integer, numeric, numeric) AS
INSERT INTO analytics.player_statistics AS prior
    (player_id, season_id, event_id, round_number, metric_code, metric_version, observation_id, numeric_value, display_value, sample_count, numerator, denominator)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
ON CONFLICT (player_id, season_id, event_id, round_number, metric_code, metric_version, observation_id) DO NOTHING;

PREPARE write_player_output(uuid, text, text, uuid, uuid, timestamptz, timestamptz, text, numeric, text, integer, bigint) AS
INSERT INTO analytics.player_output AS prior
    (player_id, model_code, model_version, run_id, event_id, as_of, generated_at, output_code, numeric_value, display_value, sample_count, observation_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
ON CONFLICT (run_id, model_code, model_version, player_id, event_id, output_code) DO NOTHING;

-- Register canonical entities only after checking the provider mapping. Create
-- the UUID and its first provider mapping in one transaction.
PREPARE write_season(text,integer,text) AS
INSERT INTO public.seasons ("seasonID",season_year,"tourID") VALUES ($1,$2,$3)
ON CONFLICT ("seasonID") DO NOTHING;

PREPARE create_player(text,text,text) AS
INSERT INTO public.players_tracking (player_fullname,nationality_country,current_location)
VALUES ($1,$2,$3) RETURNING playerid;

PREPARE create_course(text,text,text) AS
INSERT INTO public.courses (course_name,country_code,location_text)
VALUES ($1,$2,$3) RETURNING "coursesID";

PREPARE create_event(text,text,text,uuid,date,date,text,text,text) AS
INSERT INTO public.events
    (event_name,"tourID","seasonID","coursesID",starts_on,ends_on,event_type_code,event_status_code,cut_rule_code)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING "eventsID";

PREPARE write_metric_definition(text,integer,text,text,text) AS
INSERT INTO analytics.metric_definition (metric_code,version,label,definition,unit_code)
VALUES ($1,$2,$3,$4,$5) ON CONFLICT (metric_code,version) DO NOTHING;

PREPARE map_metric(text,text,text,integer) AS
INSERT INTO intake.metric_id_mapping AS prior
    (provider,external_id,metric_code,metric_version)
VALUES ($1,$2,$3,$4)
ON CONFLICT (provider,external_id) DO UPDATE SET metric_code = prior.metric_code
WHERE (prior.metric_code,prior.metric_version) = (excluded.metric_code,excluded.metric_version)
RETURNING metric_code,metric_version;

-- Correct reviewed canonical metadata by UUID after resolving identity.
PREPARE update_event_calendar(uuid,text,uuid,date,date,text,text,text) AS
UPDATE public.events
SET event_name=$2,"coursesID"=$3,starts_on=$4,ends_on=$5,
    event_type_code=$6,event_status_code=$7,cut_rule_code=$8
WHERE "eventsID"=$1 RETURNING "eventsID";
