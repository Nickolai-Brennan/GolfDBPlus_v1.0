-- Source queries for the performance schema.
PREPARE performance_round_totals(uuid, uuid) AS
SELECT * FROM performance.player_tracker_round_totals
WHERE event_id = $1 AND player_id = $2
ORDER BY round_number, course_id;

PREPARE performance_shot_predictions(uuid, uuid, text) AS
SELECT * FROM performance.shot_predictability_display
WHERE event_id = $1 AND player_id = $2 AND model_version = $3
ORDER BY round_number, hole_number, shot_id, as_of;
