-- Bind UUIDs from intake.*_id_mapping, never from name-only matching.
PREPARE player_profile(uuid) AS
SELECT p.*, i.given_name,i.family_name,i.birth_date,i.birthplace,i.residence,
       i.college,i.is_amateur,i.turned_pro_year,i.headshot_url,i.observation_id
FROM public.players_tracking p LEFT JOIN analytics.player_info i ON i.player_id = p.playerid
WHERE p.playerid = $1;

PREPARE player_stats(uuid,text,timestamptz) AS
SELECT s.*, d.label, d.unit_code, o.provider, o.observed_at, o.source_published_at
FROM analytics.player_statistics s
JOIN analytics.metric_definition d
  ON (d.metric_code,d.version) = (s.metric_code,s.metric_version)
JOIN intake.observation o USING (observation_id)
WHERE s.player_id = $1 AND s.season_id = $2 AND o.observed_at <= $3
  AND (o.source_published_at IS NULL OR o.source_published_at <= $3)
ORDER BY o.observed_at DESC, s.statistic_id DESC;

PREPARE player_outputs(uuid,text,timestamptz) AS
SELECT * FROM analytics.player_output
WHERE player_id = $1 AND model_code = $2 AND generated_at <= $3
ORDER BY generated_at DESC, output_id DESC;

PREPARE season_schedule(text) AS
SELECT * FROM analytics.schedule_tour_season
WHERE season_id = $1 ORDER BY starts_on NULLS LAST,event_name,event_id;

PREPARE event_metadata(uuid) AS
SELECT * FROM analytics.schedule_tour_season WHERE event_id = $1;

PREPARE event_leaderboard(uuid,bigint) AS
SELECT * FROM analytics.event_leaderboard
WHERE event_id = $1 AND observation_id = $2 ORDER BY position NULLS LAST,player_id;

PREPARE event_results(uuid,bigint) AS
SELECT * FROM analytics.event_results
WHERE event_id = $1 AND observation_id = $2 ORDER BY position NULLS LAST,player_id;

PREPARE course_profile(uuid) AS
SELECT c.*, i.latitude,i.longitude,i.altitude_ft,i.observation_id
FROM public.courses c LEFT JOIN analytics.course_info i ON i.course_id = c."coursesID"
WHERE c."coursesID" = $1;

PREPARE course_setup(uuid,text,date,timestamptz) AS
SELECT a.* FROM analytics.course_attributes a
JOIN intake.observation o USING (observation_id)
WHERE course_id = $1 AND setup_code = $2 AND valid_from <= $3
  AND o.observed_at <= $4 AND (o.source_published_at IS NULL OR o.source_published_at <= $4)
ORDER BY valid_from DESC,o.observed_at DESC,observation_id DESC LIMIT 1;

PREPARE course_scorecard(uuid,uuid,smallint) AS
SELECT DISTINCT ON (hole_number) * FROM analytics.course_scorecard
WHERE event_id = $1 AND course_id = $2 AND round_number IN (0,$3)
ORDER BY hole_number,round_number DESC;

PREPARE course_performance(uuid,uuid) AS
SELECT * FROM analytics.course_performance WHERE event_id = $1 AND course_id = $2;

PREPARE course_difficulty(text,text,uuid) AS
SELECT * FROM analytics.course_difficulty_evaluation
WHERE season_id = $1 AND split = $2 AND event_id IS NOT DISTINCT FROM $3
ORDER BY difficulty_rank NULLS LAST,course_id;

PREPARE hole_metrics(uuid,uuid,smallint) AS
SELECT * FROM analytics.course_hole_metrics
WHERE event_id = $1 AND course_id = $2 AND round_number = $3
ORDER BY avg_to_par DESC NULLS LAST,hole_number;
