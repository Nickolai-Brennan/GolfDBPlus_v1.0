-- Source queries for the statistic schema.
PREPARE statistic_player_registry(text) AS
SELECT * FROM statistic.player_registry WHERE pgatour_id = $1;

PREPARE statistic_event_scoring(uuid, bigint) AS
SELECT * FROM statistic.results_scoring_event_basic
WHERE event_id = $1 AND observation_id = $2
ORDER BY total_score NULLS LAST, player_id;

PREPARE statistic_course_card(uuid, uuid, smallint) AS
SELECT * FROM statistic.course_scorecard
WHERE event_id = $1 AND course_id = $2 AND round_number = $3
ORDER BY hole_number;
