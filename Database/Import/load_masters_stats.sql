-- Run the SQL emitted by prepare_masters_stats.py. It supplies the validated rows.
BEGIN;

CREATE TEMP TABLE masters_input ON COMMIT DROP AS
SELECT v->>0 AS pgatour_id, v->>1 AS datagolf_id, (v->>2)::smallint AS round_number,
       (v->>3)::integer AS score, (v->>4)::smallint AS start_hole, v->5 AS metrics
FROM jsonb_array_elements('__ROWS_JSON__'::jsonb) AS j(v);

INSERT INTO public.seasons ("seasonID",season_year,"tourID")
VALUES ('2021-PGA',2021,'PGA') ON CONFLICT DO NOTHING;

-- The official event is R2021536 (April 8–11), distinct from the November edition.
INSERT INTO public.courses (course_name,"pgatour_coursesID")
VALUES ('Augusta National Golf Club','014')
ON CONFLICT ("pgatour_coursesID") WHERE "pgatour_coursesID" IS NOT NULL DO NOTHING;

INSERT INTO public.events (event_name,"tourID","seasonID","coursesID","pgatour_eventsID",starts_on,ends_on)
SELECT '2021 Masters Tournament','PGA','2021-PGA',c."coursesID",'R2021536','2021-04-08','2021-04-11'
FROM public.courses c WHERE c."pgatour_coursesID"='014'
ON CONFLICT ("seasonID","pgatour_eventsID") WHERE "pgatour_eventsID" IS NOT NULL DO NOTHING;

INSERT INTO intake.event_id_mapping (provider,namespace,season_id,external_id,event_id)
SELECT ids.provider,'tournament','2021-PGA',ids.external_id,e."eventsID"
FROM public.events e CROSS JOIN (VALUES ('pgatour','R2021536'),('datagolf','536')) ids(provider,external_id)
WHERE (e."seasonID",e."pgatour_eventsID")=('2021-PGA','R2021536')
ON CONFLICT DO NOTHING;

INSERT INTO analytics.event_course (event_id,course_id)
SELECT e."eventsID",c."coursesID" FROM public.events e CROSS JOIN public.courses c
WHERE (e."seasonID",e."pgatour_eventsID",c."pgatour_coursesID")=('2021-PGA','R2021536','014')
ON CONFLICT DO NOTHING;

INSERT INTO intake.observation (provider,operation,request_key,observed_at,payload_sha256,raw_uri)
VALUES ('datagolf','historical_raw_round_stats','pga:2021:536:__ARCHIVE_SHA__','2026-11-08T09:29:06Z',
        '__ARCHIVE_SHA__','https://github.com/Nickolai-Brennan/GolfDBPlus_v1.0/blob/f9962331e4f867be21a462b6b99d00132ef0fe8a/Data/Source-Files/raw_pga_536_2021.tsv')
ON CONFLICT DO NOTHING;

CREATE TEMP TABLE masters_context ON COMMIT DROP AS
SELECT e."eventsID" AS event_id,c."coursesID" AS course_id,o.observation_id
FROM public.events e CROSS JOIN public.courses c CROSS JOIN intake.observation o
WHERE (e."seasonID",e."pgatour_eventsID",c."pgatour_coursesID")=('2021-PGA','R2021536','014')
  AND (o.provider,o.operation,o.request_key,o.observed_at)=
      ('datagolf','historical_raw_round_stats','pga:2021:536:__ARCHIVE_SHA__','2026-11-08T09:29:06Z');

CREATE TEMP TABLE masters_resolved ON COMMIT DROP AS
SELECT i.*,p.player_id
FROM masters_input i
JOIN intake.player_id_mapping p ON p.provider='pgatour' AND p.external_id=i.pgatour_id
LEFT JOIN intake.player_id_mapping d ON d.provider='datagolf' AND d.external_id=i.datagolf_id
WHERE d.player_id IS NULL OR d.player_id=p.player_id;

-- Preserve authoritative scores already present. Conflicts fail the whole load.
DO $$
BEGIN
    IF (SELECT count(*) FROM masters_context) <> 1 OR EXISTS (
        SELECT 1 FROM masters_context c
        JOIN intake.event_id_mapping m ON m.season_id='2021-PGA' AND m.namespace='tournament'
        WHERE ((m.provider,m.external_id)=('pgatour','R2021536') OR
               (m.provider,m.external_id)=('datagolf','536')) AND m.event_id<>c.event_id
    ) OR EXISTS (
        SELECT 1 FROM masters_resolved i CROSS JOIN masters_context c
        JOIN analytics.player_round r ON r.event_id=c.event_id
        WHERE (r.player_id,r.round_number)=(i.player_id,i.round_number)
          AND ((r.strokes IS NOT NULL AND r.strokes<>i.score)
               OR (r.course_id IS NOT NULL AND r.course_id<>c.course_id))
    ) THEN
        RAISE EXCEPTION 'Masters identity or existing round conflict';
    END IF;
END $$;

INSERT INTO analytics.player_round
    (event_id,player_id,round_number,course_id,observation_id,start_hole,strokes,score_to_par)
SELECT c.event_id,i.player_id,i.round_number,c.course_id,c.observation_id,i.start_hole,i.score,i.score-72
FROM masters_resolved i CROSS JOIN masters_context c
ON CONFLICT DO NOTHING;

INSERT INTO analytics.player_statistics
    (player_id,season_id,event_id,round_number,metric_code,metric_version,observation_id,numeric_value)
SELECT i.player_id,'2021-PGA',c.event_id,i.round_number,m.metric_code,m.metric_version,c.observation_id,v.value::numeric
FROM masters_resolved i CROSS JOIN masters_context c
CROSS JOIN LATERAL jsonb_each_text(i.metrics) v
JOIN intake.metric_id_mapping m ON m.provider='datagolf' AND m.external_id=v.key
ON CONFLICT DO NOTHING;

INSERT INTO intake.record(observation_id,record_key,payload,state,reason)
SELECT c.observation_id,'round:'||i.datagolf_id||':'||i.round_number,
       to_jsonb(i), CASE WHEN p.player_id IS NULL THEN 'pending' ELSE 'accepted' END,
       CASE WHEN p.player_id IS NULL THEN 'Canonical PGA TOUR player mapping missing or provider IDs conflict' END
FROM masters_input i CROSS JOIN masters_context c
LEFT JOIN masters_resolved p USING (pgatour_id,datagolf_id,round_number)
ON CONFLICT (observation_id,record_key) DO UPDATE SET state='accepted',reason=NULL
WHERE intake.record.state='pending' AND excluded.state='accepted'
  AND intake.record.payload=excluded.payload;

SELECT c.observation_id,
       (SELECT count(*) FROM masters_input) AS archive_rounds,
       (SELECT count(*) FROM masters_resolved) AS mapped_rounds,
       (SELECT count(DISTINCT player_id) FROM masters_resolved) AS mapped_players,
       (SELECT count(*) FROM intake.record r WHERE r.observation_id=c.observation_id AND r.state='pending') AS pending_rounds,
       (SELECT count(*) FROM analytics.player_statistics s WHERE s.observation_id=c.observation_id) AS metric_values
FROM masters_context c;

COMMIT;
