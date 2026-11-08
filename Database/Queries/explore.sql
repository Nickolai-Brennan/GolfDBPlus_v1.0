-- Date windows are start-inclusive and end-exclusive.
PREPARE event_window(text,date,date) AS
SELECT * FROM analytics.schedule_tour_season
WHERE tour_id=$1 AND starts_on >= $2 AND starts_on < $3
ORDER BY starts_on,event_id;

PREPARE event_round_scores(uuid,smallint) AS
SELECT r.*,p.player_fullname
FROM analytics.player_round r JOIN public.players_tracking p ON p.playerid=r.player_id
WHERE event_id=$1 AND round_number=$2 ORDER BY score_to_par NULLS LAST,player_id;

PREPARE player_holes(uuid,uuid,smallint) AS
SELECT * FROM analytics.player_hole_score
WHERE player_id=$1 AND event_id=$2 AND round_number=$3 ORDER BY hole_number;

PREPARE player_par_splits(uuid,date,date) AS
SELECT s.par,sum(s.holes_played) AS holes_played,sum(s.total_strokes) AS total_strokes,
       sum(s.total_to_par) AS total_to_par,
       sum(s.total_strokes)/nullif(sum(s.holes_played),0) AS average_strokes
FROM analytics.player_par_scoring s JOIN public.events e ON e."eventsID"=s.event_id
WHERE s.player_id=$1 AND e.starts_on >= $2 AND e.starts_on < $3
GROUP BY s.par ORDER BY s.par NULLS LAST;

PREPARE player_metric_history(uuid,text,integer,text,timestamptz,timestamptz) AS
SELECT s.*,o.observed_at,o.source_published_at
FROM analytics.player_statistics s JOIN intake.observation o USING (observation_id)
WHERE s.player_id=$1 AND s.metric_code=$2 AND s.metric_version=$3 AND o.provider=$4
  AND o.observed_at >= $5 AND o.observed_at < $6
  AND (o.source_published_at IS NULL OR o.source_published_at < $6)
ORDER BY o.observed_at,s.statistic_id;

PREPARE result_publications(uuid,timestamptz) AS
SELECT o.observation_id,o.provider,o.observed_at,o.source_published_at,count(*) AS players
FROM analytics.event_results r JOIN intake.observation o USING (observation_id)
WHERE r.event_id=$1 AND o.observed_at <= $2
  AND (o.source_published_at IS NULL OR o.source_published_at <= $2)
GROUP BY o.observation_id ORDER BY o.observed_at DESC,o.observation_id DESC;

PREPARE event_venues(uuid) AS
SELECT c.* FROM analytics.event_course v JOIN public.courses c ON c."coursesID"=v.course_id
WHERE v.event_id=$1 ORDER BY c.course_name,c."coursesID";

PREPARE course_hole_source_history(uuid,uuid,smallint) AS
SELECT m.*,o.provider,o.observed_at
FROM analytics.course_hole_source_metrics m JOIN intake.observation o USING (observation_id)
WHERE m.course_id=$1 AND m.event_id=$2 AND m.round_number=$3
ORDER BY m.hole_number,o.observed_at,o.observation_id;

PREPARE event_coverage(text) AS
SELECT * FROM analytics.event_data_coverage WHERE season_id=$1 ORDER BY event_name,event_id;

PREPARE intake_coverage(text,timestamptz,timestamptz) AS
SELECT * FROM intake.observation_coverage
WHERE provider=$1 AND observed_at >= $2 AND observed_at < $3
ORDER BY observed_at,observation_id;

PREPARE quarantined_records(bigint) AS
SELECT record_key,reason,payload FROM intake.record
WHERE observation_id=$1 AND state='quarantined' ORDER BY record_key;

PREPARE lookup_values(text) AS
SELECT code,name,detail FROM core.lookup_values
WHERE lookup_group=$1 AND is_active ORDER BY sort_order,code;

-- Discover columns and keys without constructing SQL from caller input.
PREPARE schema_columns(text) AS
SELECT table_name,ordinal_position,column_name,data_type,is_nullable,column_default
FROM information_schema.columns WHERE table_schema=$1
ORDER BY table_name,ordinal_position;
