-- Reporting views over canonical facts. Coverage counts describe available data.
BEGIN;

CREATE OR REPLACE VIEW analytics.player_par_scoring AS
WITH holes AS (
    SELECT h.event_id, h.player_id, h.course_id, h.round_number, h.strokes,
           coalesce(r.par,d.par) AS par
    FROM analytics.player_hole_score h
    LEFT JOIN analytics.course_scorecard r
      USING (event_id,course_id,round_number,hole_number)
    LEFT JOIN analytics.course_scorecard d
      ON (d.event_id,d.course_id,d.round_number,d.hole_number) =
         (h.event_id,h.course_id,0,h.hole_number)
)
SELECT event_id, player_id, course_id, round_number, par,
       count(*) AS holes_played, sum(strokes) AS total_strokes,
       avg(strokes) AS average_strokes, sum(strokes - par) AS total_to_par,
       count(*) FILTER (WHERE strokes < par) AS birdie_or_better
FROM holes
GROUP BY event_id,player_id,course_id,round_number,par;

CREATE OR REPLACE VIEW analytics.event_data_coverage AS
SELECT e."eventsID" AS event_id, e."seasonID" AS season_id,
       e.event_name, coalesce(r.round_rows,0) AS round_rows,
       coalesce(h.hole_rows,0) AS hole_rows,
       coalesce(l.publications,0) AS leaderboard_publications,
       coalesce(f.publications,0) AS result_publications
FROM public.events e
LEFT JOIN (SELECT event_id,count(*) AS round_rows FROM analytics.player_round GROUP BY event_id) r
  ON r.event_id=e."eventsID"
LEFT JOIN (SELECT event_id,count(*) AS hole_rows FROM analytics.player_hole_score GROUP BY event_id) h
  ON h.event_id=e."eventsID"
LEFT JOIN (SELECT event_id,count(DISTINCT observation_id) AS publications
           FROM analytics.event_leaderboard GROUP BY event_id) l ON l.event_id=e."eventsID"
LEFT JOIN (SELECT event_id,count(DISTINCT observation_id) AS publications
           FROM analytics.event_results GROUP BY event_id) f ON f.event_id=e."eventsID";

CREATE OR REPLACE VIEW intake.observation_coverage AS
SELECT o.observation_id,o.provider,o.operation,o.request_key,o.observed_at,
       count(r.record_key) AS records,
       count(*) FILTER (WHERE r.state='pending') AS pending,
       count(*) FILTER (WHERE r.state='accepted') AS accepted,
       count(*) FILTER (WHERE r.state='quarantined') AS quarantined
FROM intake.observation o LEFT JOIN intake.record r USING (observation_id)
GROUP BY o.observation_id;

COMMIT;
