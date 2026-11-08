-- PostgreSQL 15+. Apply after the Shot Tracker V1 schemas are installed.
CREATE SCHEMA IF NOT EXISTS reporting;

CREATE OR REPLACE VIEW reporting.admin_dashboard_facts AS
WITH primary_schedule AS (
    SELECT DISTINCT ON (event_id)
           event_id, tour_id, season
    FROM golf.schedule_entry
    ORDER BY event_id, (tour_id = 'pga') DESC, season DESC, tour_id
),
event_context AS (
    SELECT e.event_id, e.event_name, e.start_date, e.schedule_batch_id,
           s.tour_id, s.season, b.source_code, b.retrieved_at
    FROM golf.event_edition e
    LEFT JOIN primary_schedule s USING (event_id)
    LEFT JOIN ingest.batch b ON b.batch_id = e.schedule_batch_id
),
facts AS (
    SELECT 'batch:' || b.batch_id::text AS fact_id,
           'collection_batch'::text AS fact_kind,
           b.retrieved_at AS fact_at,
           b.source_code,
           'Miscellaneous'::text AS collection,
           'Data Intake'::text AS data_category,
           'Collection Batch'::text AS data_type,
           NULL::text AS tour_id, NULL::smallint AS season,
           NULL::bigint AS event_id, NULL::text AS event_name,
           NULL::bigint AS course_id, NULL::text AS course_name,
           NULL::bigint AS player_id, NULL::text AS player_name,
           NULL::smallint AS round_number, NULL::smallint AS hole_number,
           0::bigint AS item_count, 0::bigint AS data_point_count
    FROM ingest.batch b

    UNION ALL

    SELECT 'record:' || r.batch_id::text || ':' || r.record_key,
           'collected_item', b.retrieved_at, b.source_code,
           'Miscellaneous', 'Data Intake', 'Staged Record',
           NULL::text, NULL::smallint,
           NULL::bigint, NULL::text, NULL::bigint, NULL::text,
           NULL::bigint, NULL::text, NULL::smallint, NULL::smallint,
           1::bigint, 0::bigint
    FROM ingest.record r
    JOIN ingest.batch b USING (batch_id)

    UNION ALL

    SELECT 'event:' || e.event_id::text,
           'event', COALESCE(e.retrieved_at, e.start_date::timestamptz),
           e.source_code, 'Counting Stats', 'Event Data', 'Event Data',
           e.tour_id, e.season, e.event_id, e.event_name,
           NULL::bigint, NULL::text, NULL::bigint, NULL::text,
           NULL::smallint, NULL::smallint, 0::bigint, 0::bigint
    FROM event_context e

    UNION ALL

    SELECT 'course:' || c.course_id::text,
           'course', NULL::timestamptz, NULL::text,
           'Miscellaneous', 'Course Data', 'Course Data',
           NULL::text, NULL::smallint, NULL::bigint, NULL::text,
           c.course_id, c.course_name, NULL::bigint, NULL::text,
           NULL::smallint, NULL::smallint, 0::bigint, 0::bigint
    FROM golf.course c

    UNION ALL

    SELECT 'course_hole:' || h.course_id::text || ':' || h.hole_number::text,
           'course_hole', NULL::timestamptz, NULL::text,
           'Counting Stats', 'Course Data', 'Hole Data',
           NULL::text, NULL::smallint, NULL::bigint, NULL::text,
           h.course_id, c.course_name, NULL::bigint, NULL::text,
           NULL::smallint, h.hole_number, 0::bigint, 0::bigint
    FROM golf.course_hole h
    JOIN golf.course c USING (course_id)

    UNION ALL

    SELECT 'event_round:' || r.event_id::text || ':' || r.round_number::text
           || ':' || r.course_id::text,
           'event_round', COALESCE(b.retrieved_at, r.played_on::timestamptz),
           b.source_code, 'Counting Stats', 'Scores', 'Event Data',
           e.tour_id, e.season, r.event_id, e.event_name,
           r.course_id, c.course_name, NULL::bigint, NULL::text,
           r.round_number, NULL::smallint, 0::bigint, 0::bigint
    FROM golf.event_round r
    JOIN event_context e USING (event_id)
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN ingest.batch b ON b.batch_id = e.schedule_batch_id

    UNION ALL

    SELECT 'round_hole:' || h.event_id::text || ':' || h.round_number::text
           || ':' || h.course_id::text || ':' || h.hole_number::text,
           'round_hole_setup', COALESCE(b.retrieved_at, r.played_on::timestamptz),
           b.source_code, 'Counting Stats', 'Scores', 'Hole Data',
           e.tour_id, e.season, h.event_id, e.event_name,
           h.course_id, c.course_name, NULL::bigint, NULL::text,
           h.round_number, h.hole_number, 0::bigint, 1::bigint
    FROM golf.round_hole_setup h
    JOIN event_context e USING (event_id)
    LEFT JOIN golf.event_round r
        ON r.event_id = h.event_id
       AND r.round_number = h.round_number
       AND r.course_id = h.course_id
    LEFT JOIN golf.course c ON c.course_id = h.course_id
    LEFT JOIN ingest.batch b ON b.batch_id = e.schedule_batch_id

    UNION ALL

    SELECT 'result:' || r.event_id::text || ':' || r.player_id::text,
           'event_result', b.retrieved_at, b.source_code,
           'Scores', 'Scores', 'Player Data',
           e.tour_id, e.season, r.event_id, e.event_name,
           NULL::bigint, NULL::text, r.player_id, p.display_name,
           NULL::smallint, NULL::smallint, 0::bigint, 1::bigint
    FROM golf.event_result r
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b USING (batch_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'player_round:' || r.event_id::text || ':' || r.player_id::text
           || ':' || r.round_number::text,
           'player_round', b.retrieved_at, b.source_code,
           'Scores', 'Scores', 'Player Data',
           e.tour_id, e.season, r.event_id, e.event_name,
           r.course_id, c.course_name, r.player_id, p.display_name,
           r.round_number, NULL::smallint, 0::bigint, 1::bigint
    FROM golf.player_round r
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b USING (batch_id)
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'player_hole:' || h.event_id::text || ':' || h.player_id::text
           || ':' || h.round_number::text || ':' || h.hole_number::text,
           'player_hole', b.retrieved_at, b.source_code,
           'Counting Stats', 'Scores', 'Hole Data',
           e.tour_id, e.season, h.event_id, e.event_name,
           h.course_id, c.course_name, h.player_id, p.display_name,
           h.round_number, h.hole_number, 0::bigint, 1::bigint
    FROM golf.player_hole h
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b USING (batch_id)
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'shot:' || s.shot_id::text,
           'shot', b.retrieved_at, b.source_code,
           'Counting Stats', 'Shot Data', 'Shot Data',
           e.tour_id, e.season, s.event_id, e.event_name,
           s.course_id, c.course_name, s.player_id, p.display_name,
           s.round_number, s.hole_number, 0::bigint, 1::bigint
    FROM golf.shot s
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b USING (batch_id)
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'shot_radar:' || r.shot_id::text,
           'shot_radar', b.retrieved_at, b.source_code,
           'Statistics', 'Shot Data', 'Shot Data',
           e.tour_id, e.season, s.event_id, e.event_name,
           s.course_id, c.course_name, s.player_id, p.display_name,
           s.round_number, s.hole_number, 0::bigint, 1::bigint
    FROM golf.shot_radar r
    JOIN golf.shot s USING (shot_id)
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b ON b.batch_id = r.batch_id
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'shot_path_point:' || p.path_id::text || ':' || p.point_index::text,
           'shot_path_point', b.retrieved_at, b.source_code,
           'Statistics', 'Shot Data', 'Shot Data',
           e.tour_id, e.season, s.event_id, e.event_name,
           s.course_id, c.course_name, s.player_id, pl.display_name,
           s.round_number, s.hole_number, 0::bigint, 1::bigint
    FROM golf.shot_path_point p
    JOIN golf.shot_path path USING (path_id)
    JOIN golf.shot s USING (shot_id)
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b ON b.batch_id = path.batch_id
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player pl ON pl.player_id = s.player_id

    UNION ALL

    SELECT 'shot_media:' || m.shot_id::text || ':' || m.source_code
           || ':' || m.external_media_id,
           'shot_media', b.retrieved_at, m.source_code,
           'Miscellaneous', 'Shot Data', 'Shot Data',
           e.tour_id, e.season, s.event_id, e.event_name,
           s.course_id, c.course_name, s.player_id, p.display_name,
           s.round_number, s.hole_number, 0::bigint, 1::bigint
    FROM golf.shot_media m
    JOIN golf.shot s USING (shot_id)
    JOIN event_context e USING (event_id)
    JOIN ingest.batch b ON b.batch_id = m.batch_id
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p ON p.player_id = s.player_id

    UNION ALL

    SELECT 'metric:' || m.observation_id::text,
           'metric_observation', b.retrieved_at, m.source_code,
           'Statistics', d.category,
           CASE WHEN lower(d.category) LIKE '%stroke%gained%'
                THEN 'Strokes Gained' ELSE 'Stat Tracking' END,
           m.tour_id, m.season, m.event_id, e.event_name,
           m.course_id, c.course_name, m.player_id, p.display_name,
           m.round_number, m.hole_number, 0::bigint, 1::bigint
    FROM golf.metric_observation m
    JOIN golf.metric_definition d
      ON d.metric_code = m.metric_code
     AND d.definition_version = m.definition_version
    JOIN ingest.batch b USING (batch_id)
    LEFT JOIN event_context e USING (event_id)
    LEFT JOIN golf.course c USING (course_id)
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'ranking_entry:' || e.snapshot_id::text || ':' || e.player_id::text,
           'ranking_entry', b.retrieved_at, b.source_code,
           'Rankings', 'Rankings', 'Player Data',
           NULL::text, NULL::smallint, NULL::bigint, NULL::text,
           NULL::bigint, NULL::text, e.player_id, p.display_name,
           NULL::smallint, NULL::smallint, 0::bigint, 1::bigint
    FROM golf.ranking_entry e
    JOIN golf.ranking_snapshot s USING (snapshot_id)
    JOIN golf.ranking_system rs USING (ranking_code)
    JOIN ingest.batch b ON b.batch_id = s.batch_id
    LEFT JOIN golf.player p USING (player_id)

    UNION ALL

    SELECT 'fedex_entry:' || e.snapshot_id::text || ':' || e.player_id::text,
           'fedex_entry', b.retrieved_at, b.source_code,
           'Rankings', 'Rankings', 'Player Data',
           s.tour_id, s.season, NULL::bigint, NULL::text,
           NULL::bigint, NULL::text, e.player_id, p.display_name,
           NULL::smallint, NULL::smallint, 0::bigint, 1::bigint
    FROM golf.fedex_entry e
    JOIN golf.fedex_snapshot s USING (snapshot_id)
    JOIN ingest.batch b ON b.batch_id = s.batch_id
    LEFT JOIN golf.player p USING (player_id)
)
SELECT fact_id, fact_kind, fact_at, source_code, collection, data_category,
       data_type, tour_id, season, event_id, event_name, course_id, course_name,
       player_id, player_name, round_number, hole_number, item_count,
       data_point_count
FROM facts;

COMMENT ON VIEW reporting.admin_dashboard_facts IS
'Admin dashboard export grain. YTD items are ingest.record rows; batches are separate. Data points count result, round, hole, shot, metric, ranking, and telemetry facts. Reference entities are counted separately.';

COMMENT ON COLUMN reporting.admin_dashboard_facts.data_point_count IS
'One for each score, round-hole setup, player hole, shot, radar, path point, media item, metric observation, or ranking entry; zero for reference rows and staging-only records.';

COMMENT ON COLUMN reporting.admin_dashboard_facts.tour_id IS
'For event-scoped non-metric facts, the primary schedule is selected deterministically with PGA preferred. Metrics and standings use their stored tour.';
