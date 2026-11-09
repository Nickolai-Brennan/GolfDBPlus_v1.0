"""Generate transactional SQL batches from the verified 2026 replay inputs."""

import argparse
import hashlib
import json
import re
from pathlib import Path

from prepare_2026_facts import API, DATA, EVENT, MODEL

# The source bytes are versioned. A stable snapshot identifier makes retries safe.
SOURCE_REVISION = "e8957e8c2ee612e041e15a57044ac37d782d2755"
SNAPSHOT_AT = "2026-11-08T22:53:00Z"
EVENT_LINK = """JOIN intake.event_id_mapping e
 ON (e.provider,e.namespace,e.season_id,e.external_id) = ('pgatour','tournament','2026-PGA',r->>0)"""
PLAYER_LINK = """JOIN intake.player_id_mapping p
 ON (p.provider,p.external_id) = ('pgatour',r->>1)"""
OBS = "JOIN intake.observation o ON o.provider='pgatour' AND o.request_key="
QUERIES = {
    "venues": """
INSERT INTO public.courses ("pgatour_coursesID",course_name)
SELECT r->>0,r->>1 FROM rows
ON CONFLICT ("pgatour_coursesID") WHERE "pgatour_coursesID" IS NOT NULL DO NOTHING""",
    "events": """
INSERT INTO public.events ("seasonID","tourID","pgatour_eventsID",event_name,"coursesID",starts_on,ends_on)
SELECT '2026-PGA','PGA',r->>0,r->>1,c."coursesID",(r->>3)::date,(r->>4)::date
FROM rows LEFT JOIN public.courses c ON c."pgatour_coursesID"=r->>2
ON CONFLICT ("seasonID","pgatour_eventsID") WHERE "pgatour_eventsID" IS NOT NULL DO NOTHING""",
    "event_courses": """
INSERT INTO analytics.event_course (event_id,course_id)
SELECT e.event_id,c.external_course FROM rows
JOIN public.courses pc ON pc."pgatour_coursesID"=r->>1
CROSS JOIN LATERAL (SELECT pc."coursesID" AS external_course) c
""" + EVENT_LINK + " ON CONFLICT DO NOTHING",
    "course": """
INSERT INTO analytics.course_scorecard (event_id,course_id,round_number,hole_number,par,yards,observation_id)
SELECT e.event_id,c."coursesID",(r->>2)::smallint,(r->>3)::smallint,(r->>4)::smallint,(r->>5)::int,o.observation_id
FROM rows JOIN public.courses c ON c."pgatour_coursesID"=r->>1
""" + EVENT_LINK + "\n" + OBS + "'verified2026:course_setup' WHERE (r->>2)::smallint BETWEEN 0 AND 4 ON CONFLICT DO NOTHING",
    "rounds": """
INSERT INTO analytics.player_round (event_id,player_id,round_number,course_id,observation_id,tee_time,start_hole,strokes,score_to_par)
SELECT e.event_id,p.player_id,(r->>2)::smallint,c."coursesID",o.observation_id,(r->>4)::timestamptz,
       (r->>5)::smallint,(r->>6)::numeric::int,(r->>7)::numeric::int
FROM rows JOIN public.courses c ON c."pgatour_coursesID"=r->>3
""" + EVENT_LINK + "\n" + PLAYER_LINK + "\n" + OBS + "'verified2026:shots' ON CONFLICT DO NOTHING",
    "holes": """
INSERT INTO analytics.player_hole_score (event_id,player_id,round_number,course_id,hole_number,strokes,observation_id)
SELECT e.event_id,p.player_id,(r->>2)::smallint,c."coursesID",(r->>4)::smallint,(r->>5)::numeric::smallint,o.observation_id
FROM rows JOIN public.courses c ON c."pgatour_coursesID"=r->>3
""" + EVENT_LINK + "\n" + PLAYER_LINK + "\n" + OBS + "'verified2026:shots' ON CONFLICT DO NOTHING",
    "results": """
INSERT INTO analytics.event_results (event_id,player_id,observation_id,position,position_display,status,total_strokes,score_to_par)
SELECT e.event_id,p.player_id,o.observation_id,(r->>2)::numeric::int,r->>3,r->>4,(r->>5)::numeric::int,(r->>6)::numeric::int
FROM rows
""" + EVENT_LINK + "\n" + PLAYER_LINK + "\n" + OBS + "'verified2026:leaderboard' ON CONFLICT DO NOTHING",
    "shots": """
, mapped AS (
  SELECT r,e.event_id,p.player_id,c."coursesID" AS course_id,o.observation_id
  FROM rows JOIN public.courses c ON c."pgatour_coursesID"=r->>3
""" + EVENT_LINK + "\n" + PLAYER_LINK + "\n" + OBS + """'verified2026:shots'
), inserted AS (
 INSERT INTO performance.player_tracker_shot_tourcast
 (event_id,player_id,round_number,course_id,source_shot_id,hole_number,par,observation_id,
  coordinate_frame,start_coordinates,end_coordinates,start_distance_to_pin_yards,start_shot_class,
  shot_distance,shot_distance_unit,shot_direction_degrees,shot_swing_speed_mph,shot_apex_feet,
  shot_smash_rate,shot_outcome_distance_to_pin_yards,hole_finished)
 SELECT event_id,player_id,(r->>2)::smallint,course_id,r->>4,(r->>5)::smallint,(r->>6)::smallint,observation_id,
        'tourcast-native:'||(r->>3)||':'||(r->>5),
        CASE WHEN r->>7 IS NOT NULL AND r->>8 IS NOT NULL THEN point((r->>7)::float8,(r->>8)::float8) END,
        CASE WHEN r->>9 IS NOT NULL AND r->>10 IS NOT NULL THEN point((r->>9)::float8,(r->>10)::float8) END,
        (r->>11)::numeric,CASE WHEN (r->>12)::boolean THEN 'putt' END,
        (r->>13)::numeric,CASE WHEN r->>13 IS NOT NULL THEN CASE WHEN (r->>12)::boolean THEN 'ft' ELSE 'yd' END END,
        (r->>14)::numeric,(r->>15)::numeric,(r->>16)::numeric,(r->>17)::numeric,(r->>18)::numeric,(r->>19)::boolean
 FROM mapped
 ON CONFLICT (event_id,player_id,round_number,source_shot_id) DO NOTHING
 RETURNING shot_id,event_id,player_id,round_number,source_shot_id
), shots AS (
 SELECT * FROM inserted
 UNION ALL
 SELECT s.shot_id,s.event_id,s.player_id,s.round_number,s.source_shot_id
 FROM mapped m JOIN performance.player_tracker_shot_tourcast s
 ON (s.event_id,s.player_id,s.round_number,s.source_shot_id)=(m.event_id,m.player_id,(m.r->>2)::smallint,m.r->>4)
), outputs AS (
 INSERT INTO performance.shot_performance_predictability_output
 (shot_id,model_version,as_of,shot_class,shot_start_distance_to_pin_yards,shot_start_setting,
  factors,perfect_probability,probable_probability,worst_probability)
 SELECT s.shot_id,'""" + MODEL + """','2026-07-01T00:00:00Z','putt',(m.r->>11)::numeric,'green',
        '{"scope":"retrospective","feature":"start_distance_feet","perfect":"holed","probable":"miss within 3 feet","worst":"miss beyond 3 feet"}'::jsonb,
        (m.r->>20)::numeric,(m.r->>21)::numeric,1-(m.r->>20)::numeric-(m.r->>21)::numeric
 FROM mapped m JOIN shots s
 ON (s.event_id,s.player_id,s.round_number,s.source_shot_id)=(m.event_id,m.player_id,(m.r->>2)::smallint,m.r->>4)
 WHERE m.r->>20 IS NOT NULL
 ON CONFLICT DO NOTHING RETURNING shot_id
)
SELECT (SELECT count(*) FROM rows) AS supplied,(SELECT count(*) FROM mapped) AS mapped,
       (SELECT count(*) FROM inserted) AS shots_added,(SELECT count(*) FROM outputs) AS outputs_added""",
}


def literal(text):
    return "'" + text.replace("'", "''") + "'"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batches", type=Path)
    args = parser.parse_args()
    out = args.batches
    sources = {
        "course_setup": DATA / "course_setup_2026.parquet",
        "shots": DATA / "shots_2026.parquet",
        "leaderboard": API / f"leaderboard_{EVENT}.csv",
        "tee_times": DATA / "tee_times_2026.parquet",
    }
    values = []
    for tag, path in sources.items():
        with path.open("rb") as file:
            sha = hashlib.file_digest(file, "sha256").hexdigest()
        repo_path = path.relative_to(DATA.parent.parent).as_posix()
        uri = f"https://github.com/Nickolai-Brennan/GolfDBPlus_v1.0/blob/{SOURCE_REVISION}/{repo_path}"
        values.append("(" + ",".join(map(literal, [
            "pgatour", "archive_2026_verified_load", f"verified2026:{tag}", SNAPSHOT_AT, sha, uri,
        ])) + ")")
    (out / "00-observations.sql").write_text(
        "INSERT INTO intake.observation(provider,operation,request_key,observed_at,payload_sha256,raw_uri) VALUES\n"
        + ",\n".join(values) + "\nON CONFLICT DO NOTHING;", encoding="utf-8",
    )
    (out / "03-mappings.sql").write_text("""
INSERT INTO intake.event_id_mapping(provider,namespace,season_id,external_id,event_id)
SELECT 'pgatour','tournament',"seasonID","pgatour_eventsID","eventsID" FROM public.events
WHERE "seasonID"='2026-PGA' AND "pgatour_eventsID" IS NOT NULL ON CONFLICT DO NOTHING;
INSERT INTO intake.course_id_mapping(provider,external_id,course_id)
SELECT 'pgatour',"pgatour_coursesID","coursesID" FROM public.courses
WHERE "pgatour_coursesID" IS NOT NULL ON CONFLICT DO NOTHING;
""", encoding="utf-8")
    for priority, name in enumerate(QUERIES, 1):
        number = priority if priority < 3 else priority + 1
        for path in sorted(out.glob(f"{name}-*.json")):
            batch = path.read_text(encoding="utf-8")
            if not isinstance(json.loads(batch), list):
                raise ValueError(f"Invalid batch: {path}")
            index = re.search(r"(\d+)\.json$", path.name)[1]
            (out / f"{number:02}-{name}-{index}.sql").write_text(
                f"WITH rows AS (SELECT value AS r FROM jsonb_array_elements({literal(batch)}::jsonb))\n"
                + QUERIES[name].strip() + ";\n", encoding="utf-8",
            )


if __name__ == "__main__":
    main()
