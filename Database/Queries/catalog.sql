-- Player search uses canonical identities. NULL filters are unrestricted.
PREPARE player_directory(text, text, text, integer, integer) AS
SELECT p.playerid, p.player_fullname, p.nationality_country, id.external_id AS pgatour_id
FROM public.players_tracking p
LEFT JOIN LATERAL (
    SELECT m.external_id FROM intake.player_id_mapping m
    WHERE m.player_id = p.playerid AND m.provider = 'pgatour'
    ORDER BY (m.external_id IS DISTINCT FROM p."pgatourID"), m.external_id LIMIT 1
) id ON true
WHERE ($1 IS NULL OR strpos(lower(p.player_fullname), lower($1)) > 0)
  AND ($2 IS NULL OR p.nationality_country = $2)
  AND ($3 IS NULL OR EXISTS (
      SELECT 1 FROM intake.player_id_mapping m
      WHERE m.player_id = p.playerid AND m.provider = 'pgatour' AND m.external_id = $3))
ORDER BY p.player_fullname, p.playerid
LIMIT LEAST(GREATEST(COALESCE($4, 100), 1), 500)
OFFSET GREATEST(COALESCE($5, 0), 0);

PREPARE player_provider_ids(uuid) AS
SELECT provider, external_id, observation_id
FROM intake.player_id_mapping WHERE player_id = $1 ORDER BY provider, external_id;

PREPARE player_event_history(uuid, text, integer, integer) AS
SELECT s.*, e.event_name, e.starts_on, e.ends_on
FROM statistic.results_events_positioning s
JOIN public.events e ON e."eventsID" = s.event_id
WHERE s.player_id = $1 AND ($2 IS NULL OR s.season_id = $2)
ORDER BY e.starts_on DESC NULLS LAST, s.event_id, s.observation_id DESC
LIMIT LEAST(GREATEST(COALESCE($3, 100), 1), 500)
OFFSET GREATEST(COALESCE($4, 0), 0);

PREPARE event_directory(text, text, date, date, integer, integer) AS
SELECT * FROM analytics.schedule_tour_season s
WHERE ($1 IS NULL OR s.season_id = $1)
  AND ($2 IS NULL OR strpos(lower(s.event_name), lower($2)) > 0)
  AND ($3 IS NULL OR s.ends_on >= $3)
  AND ($4 IS NULL OR s.starts_on <= $4)
ORDER BY s.starts_on NULLS LAST, s.event_name, s.event_id
LIMIT LEAST(GREATEST(COALESCE($5, 100), 1), 500)
OFFSET GREATEST(COALESCE($6, 0), 0);

-- Registry of players with recorded rounds. Official field entries are a separate source.
PREPARE event_round_field(uuid, smallint) AS
SELECT r.player_id, r.player_name, r.course_id, r.round_number, r.tee_time, r.score, r.over_under
FROM statistic.results_scoring_round r
WHERE r.event_id = $1 AND ($2 IS NULL OR r.round_number = $2)
ORDER BY r.round_number, r.tee_time NULLS LAST, r.player_id;

PREPARE event_scorecard(uuid, uuid, smallint) AS
SELECT * FROM performance.player_tracker_hole
WHERE event_id = $1 AND player_id = $2 AND round_number = $3
ORDER BY hole_number;

PREPARE stat_catalog_search(text, text, text) AS
SELECT c.*, m.metric_code, m.metric_version, d.unit_code
FROM statistic.provider_stat_catalog c
LEFT JOIN intake.metric_id_mapping m USING (provider, external_id)
LEFT JOIN analytics.metric_definition d
  ON (d.metric_code, d.version) = (m.metric_code, m.metric_version)
WHERE c.provider = $1 AND ($2 IS NULL OR c.category = $2)
  AND ($3 IS NULL OR c.external_id = $3 OR strpos(lower(c.label), lower($3)) > 0)
ORDER BY c.category, c.subcategory, c.label, c.external_id;

PREPARE metric_definition_search(text) AS
SELECT * FROM analytics.metric_definition
WHERE $1 IS NULL OR metric_code = $1 OR strpos(lower(label), lower($1)) > 0
ORDER BY metric_code, version DESC;

-- A publication is explicit. NULL event and round select exact season grain.
PREPARE metric_publication(text, integer, text, uuid, smallint, bigint) AS
SELECT s.*, p.player_fullname
FROM analytics.player_statistics s
JOIN public.players_tracking p ON p.playerid = s.player_id
WHERE (s.metric_code,s.metric_version,s.season_id,s.observation_id) = ($1,$2,$3,$6)
  AND s.event_id IS NOT DISTINCT FROM $4 AND s.round_number IS NOT DISTINCT FROM $5
ORDER BY p.player_fullname, s.player_id;

PREPARE provider_stat_publication(text, text, text, uuid, smallint, bigint) AS
SELECT s.*, p.player_fullname
FROM intake.metric_id_mapping m
JOIN analytics.player_statistics s
  ON (s.metric_code,s.metric_version) = (m.metric_code,m.metric_version)
JOIN intake.observation o ON o.observation_id = s.observation_id AND o.provider = m.provider
JOIN public.players_tracking p ON p.playerid = s.player_id
WHERE (m.provider,m.external_id,s.season_id,s.observation_id) = ($1,$2,$3,$6)
  AND s.event_id IS NOT DISTINCT FROM $4 AND s.round_number IS NOT DISTINCT FROM $5
ORDER BY p.player_fullname, s.player_id;

-- Explicit ASC/DESC avoids assuming that every metric rewards a higher value.
PREPARE metric_leaderboard(text, integer, text, uuid, smallint, bigint, text, integer) AS
SELECT rank() OVER metric_order AS position, s.player_id, p.player_fullname,
       s.numeric_value, s.sample_count, s.numerator, s.denominator
FROM analytics.player_statistics s
JOIN public.players_tracking p ON p.playerid = s.player_id
WHERE (s.metric_code,s.metric_version,s.season_id,s.observation_id) = ($1,$2,$3,$6)
  AND s.event_id IS NOT DISTINCT FROM $4 AND s.round_number IS NOT DISTINCT FROM $5
  AND s.numeric_value IS NOT NULL AND $7 IN ('asc','desc')
WINDOW metric_order AS (ORDER BY CASE WHEN $7 = 'asc' THEN s.numeric_value ELSE -s.numeric_value END)
ORDER BY position, s.player_id
LIMIT LEAST(GREATEST(COALESCE($8, 100), 1), 500);

PREPARE published_ranking(text, text, text, bigint) AS
SELECT r.*, p.player_fullname
FROM statistic.player_ranking_publication r
JOIN public.players_tracking p ON p.playerid = r.player_id
WHERE (r.provider,r.ranking_code,r.scope_key,r.observation_id) = ($1,$2,$3,$4)
ORDER BY r.position, r.player_id;

PREPARE player_ranking_history(uuid, text, text, text, timestamptz, timestamptz) AS
SELECT r.*, o.observed_at, o.source_published_at
FROM statistic.player_ranking_publication r
JOIN intake.observation o USING (observation_id)
WHERE (r.player_id,r.provider,r.ranking_code,r.scope_key) = ($1,$2,$3,$4)
  AND COALESCE(o.source_published_at, o.observed_at) >= $5
  AND COALESCE(o.source_published_at, o.observed_at) < $6
ORDER BY COALESCE(o.source_published_at, o.observed_at), r.observation_id;

PREPARE shot_measurement_values(uuid, uuid, smallint, text, integer) AS
SELECT * FROM performance.shot_measurement
WHERE event_id = $1 AND ($2 IS NULL OR player_id = $2)
  AND ($3 IS NULL OR round_number = $3) AND ($4 IS NULL OR measurement_code = $4)
ORDER BY player_id, round_number, hole_number, shot_id, measurement_code
LIMIT LEAST(GREATEST(COALESCE($5, 100), 1), 2000);

PREPARE shot_measurement_summary(uuid, uuid, smallint, text) AS
SELECT measurement_code, unit, count(*) AS samples, min(value) AS minimum,
       avg(value) AS mean, percentile_disc(0.5) WITHIN GROUP (ORDER BY value) AS median,
       max(value) AS maximum
FROM performance.shot_measurement
WHERE event_id = $1 AND ($2 IS NULL OR player_id = $2)
  AND ($3 IS NULL OR round_number = $3) AND ($4 IS NULL OR measurement_code = $4)
GROUP BY measurement_code, unit ORDER BY measurement_code, unit;

PREPARE shot_map_points(uuid, uuid, smallint, smallint, integer) AS
SELECT shot_id, player_id, course_id, round_number, hole_number, coordinate_frame,
       start_coordinates, end_coordinates, start_shot_class, hole_finished
FROM performance.player_tracker_shot_tourcast
WHERE event_id = $1 AND ($2 IS NULL OR player_id = $2)
  AND ($3 IS NULL OR round_number = $3) AND ($4 IS NULL OR hole_number = $4)
  AND (start_coordinates IS NOT NULL OR end_coordinates IS NOT NULL)
ORDER BY player_id, round_number, hole_number, shot_id
LIMIT LEAST(GREATEST(COALESCE($5, 100), 1), 2000);

PREPARE player_metric_series(uuid, text, integer, text, uuid, smallint, timestamptz, timestamptz) AS
SELECT s.*, o.provider, o.source_published_at, o.observed_at
FROM analytics.player_statistics s JOIN intake.observation o USING (observation_id)
WHERE (s.player_id,s.metric_code,s.metric_version,s.season_id) = ($1,$2,$3,$4)
  AND s.event_id IS NOT DISTINCT FROM $5 AND s.round_number IS NOT DISTINCT FROM $6
  AND COALESCE(o.source_published_at, o.observed_at) >= $7
  AND COALESCE(o.source_published_at, o.observed_at) < $8
ORDER BY COALESCE(o.source_published_at, o.observed_at), s.observation_id;

PREPARE player_round_history(uuid, text, uuid, integer) AS
SELECT r.* FROM statistic.results_scoring_round r
JOIN public.events e ON e."eventsID" = r.event_id
WHERE r.player_id = $1 AND ($2 IS NULL OR r.season_id = $2)
  AND ($3 IS NULL OR r.event_id = $3)
ORDER BY e.starts_on DESC NULLS LAST, r.event_id, r.round_number
LIMIT LEAST(GREATEST(COALESCE($4, 100), 1), 500);

PREPARE event_projection_outputs(uuid, text, text, uuid) AS
SELECT o.*, p.player_fullname
FROM analytics.player_output o JOIN public.players_tracking p ON p.playerid = o.player_id
WHERE (o.event_id,o.model_code,o.model_version,o.run_id) = ($1,$2,$3,$4)
ORDER BY o.output_code, p.player_fullname, o.player_id;

PREPARE course_directory(text, text, integer, integer) AS
SELECT c."coursesID", c.course_name, c.country_code, c.location_text
FROM public.courses c
WHERE ($1 IS NULL OR strpos(lower(c.course_name), lower($1)) > 0)
  AND ($2 IS NULL OR c.country_code = $2)
ORDER BY c.course_name, c."coursesID"
LIMIT LEAST(GREATEST(COALESCE($3, 100), 1), 500)
OFFSET GREATEST(COALESCE($4, 0), 0);

PREPARE entity_content_search(text, uuid, text, integer) AS
SELECT c.content_id, c.title, c.canonical_url, c.source_system, c.content_type, c.published_at
FROM public.content_items c
WHERE EXISTS (
    SELECT 1 FROM public.content_entity_mentions m
    WHERE m.content_id = c.content_id AND (m.entity_type,m.entity_id) = ($1,$2)
      AND m.review_status = 'approved')
  AND ($3 IS NULL OR c.search_vector @@ plainto_tsquery('english', $3))
ORDER BY c.published_at DESC NULLS LAST, c.content_id
LIMIT LEAST(GREATEST(COALESCE($4, 50), 1), 200);

-- Round leaderboards use score to par so multi-course rounds remain comparable.
PREPARE event_round_ranking(uuid, smallint) AS
SELECT rank() OVER (ORDER BY over_under) AS position, r.*
FROM statistic.results_scoring_round r
WHERE event_id = $1 AND round_number = $2 AND score IS NOT NULL AND over_under IS NOT NULL
ORDER BY position, player_id;

PREPARE event_hole_difficulty_ranking(uuid, smallint, integer) AS
SELECT rank() OVER (ORDER BY avg_to_par DESC) AS difficulty_rank, m.*
FROM analytics.course_hole_metrics m
WHERE event_id = $1 AND round_number = $2 AND avg_to_par IS NOT NULL
  AND par_sample_count >= GREATEST(COALESCE($3, 1), 1)
ORDER BY difficulty_rank, course_id, hole_number;

-- Require one measurement, unit, observation and direction for comparable ranks.
PREPARE event_shot_measurement_ranking(uuid, text, text, bigint, text, integer) AS
WITH totals AS (
    SELECT player_id, count(*) AS samples, avg(value) AS mean
    FROM performance.shot_measurement
    WHERE (event_id,measurement_code,unit,observation_id) = ($1,$2,$3,$4)
      AND $5 IN ('asc','desc')
    GROUP BY player_id
    HAVING count(*) >= GREATEST(COALESCE($6, 1), 1)
)
SELECT rank() OVER (ORDER BY CASE WHEN $5 = 'asc' THEN t.mean ELSE -t.mean END) AS position,
       t.*, p.player_fullname
FROM totals t JOIN public.players_tracking p ON p.playerid = t.player_id
ORDER BY position, t.player_id;
