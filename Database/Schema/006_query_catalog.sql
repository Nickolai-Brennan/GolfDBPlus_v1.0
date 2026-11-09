BEGIN;

-- Provider catalog metadata is separate from reviewed metric definitions and values.
CREATE TABLE IF NOT EXISTS statistic.provider_stat_catalog (
    provider text NOT NULL,
    external_id text NOT NULL CHECK (btrim(external_id) <> ''),
    label text NOT NULL,
    category text NOT NULL,
    subcategory text NOT NULL,
    PRIMARY KEY (provider, external_id)
);

-- Ranking publications retain source positions and points at their native grain.
CREATE TABLE IF NOT EXISTS statistic.player_ranking_publication (
    provider text NOT NULL,
    ranking_code text NOT NULL,
    scope_key text NOT NULL,
    observation_id bigint REFERENCES intake.observation,
    player_id uuid REFERENCES public.players_tracking,
    position integer NOT NULL CHECK (position > 0),
    position_display text,
    points numeric,
    PRIMARY KEY (provider, ranking_code, scope_key, observation_id, player_id)
);

-- Additional radar or trajectory measures require a verified source and unit.
CREATE TABLE IF NOT EXISTS performance.shot_source_measurement (
    shot_id uuid REFERENCES performance.player_tracker_shot_tourcast,
    measurement_code text CHECK (measurement_code IN (
        'ball_speed', 'spin_rate', 'spin_axis', 'launch_angle',
        'apex_range', 'apex_side', 'flight_time'
    )),
    observation_id bigint REFERENCES intake.observation,
    unit text NOT NULL CHECK (btrim(unit) <> ''),
    value numeric NOT NULL,
    PRIMARY KEY (shot_id, measurement_code, observation_id)
);

-- Keep units beside measurements and never mix putt feet with shot yards.
CREATE OR REPLACE VIEW performance.shot_measurement AS
SELECT s.shot_id, s.event_id, s.player_id, s.course_id, s.round_number,
       s.hole_number, s.start_shot_class, s.observation_id,
       m.measurement_code, m.unit, m.value
FROM performance.player_tracker_shot_tourcast s
CROSS JOIN LATERAL (VALUES
    ('travel_distance', s.shot_distance_unit, s.shot_distance),
    ('start_distance_to_pin', 'yd', s.start_distance_to_pin_yards),
    ('end_distance_to_pin', 'yd', s.shot_outcome_distance_to_pin_yards),
    ('swing_speed', 'mph', s.shot_swing_speed_mph),
    ('apex_height', 'ft', s.shot_apex_feet),
    ('smash_factor', 'ratio', s.shot_smash_rate),
    ('launch_direction', 'deg', s.shot_direction_degrees),
    ('swing_plane', 'deg', s.shot_plane_degrees)
) m(measurement_code, unit, value)
WHERE m.value IS NOT NULL
UNION ALL
SELECT s.shot_id, s.event_id, s.player_id, s.course_id, s.round_number,
       s.hole_number, s.start_shot_class, m.observation_id,
       m.measurement_code, m.unit, m.value
FROM performance.shot_source_measurement m
JOIN performance.player_tracker_shot_tourcast s USING (shot_id);

COMMIT;
