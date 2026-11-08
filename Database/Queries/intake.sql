-- Prepared statements for a collector connection. Archive bytes before registering
-- a retrieval. Use a transaction to register, stage, validate and promote a batch.
PREPARE register_observation(text,text,text,timestamptz,timestamptz,text,text,jsonb) AS
INSERT INTO intake.observation AS prior
    (provider,operation,request_key,observed_at,source_published_at,payload_sha256,raw_uri,request_parameters)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
ON CONFLICT (provider,operation,request_key,observed_at) DO UPDATE
SET payload_sha256 = prior.payload_sha256
WHERE (prior.source_published_at,prior.payload_sha256,prior.raw_uri,prior.request_parameters)
      IS NOT DISTINCT FROM
      (excluded.source_published_at,excluded.payload_sha256,excluded.raw_uri,excluded.request_parameters)
RETURNING observation_id;

-- Zero returned rows indicate conflicting retry inputs. Abort the batch.
PREPARE stage_record(bigint,text,jsonb) AS
INSERT INTO intake.record AS prior (observation_id,record_key,payload)
VALUES ($1,$2,$3)
ON CONFLICT (observation_id,record_key) DO UPDATE SET payload = prior.payload
WHERE prior.payload = excluded.payload
RETURNING observation_id,record_key,state;

-- A repeated mapping may confirm the existing target. A different target
-- returns no row and must be reviewed before changing identity.
PREPARE map_player(text,text,uuid,bigint) AS
INSERT INTO intake.player_id_mapping AS prior VALUES ($1,$2,$3,$4)
ON CONFLICT (provider,external_id) DO UPDATE SET player_id = prior.player_id
WHERE prior.player_id = excluded.player_id RETURNING player_id;

PREPARE map_course(text,text,uuid,bigint) AS
INSERT INTO intake.course_id_mapping AS prior VALUES ($1,$2,$3,$4)
ON CONFLICT (provider,external_id) DO UPDATE SET course_id = prior.course_id
WHERE prior.course_id = excluded.course_id RETURNING course_id;

PREPARE map_event(text,text,text,text,uuid,bigint) AS
INSERT INTO intake.event_id_mapping AS prior VALUES ($1,$2,$3,$4,$5,$6)
ON CONFLICT (provider,namespace,season_id,external_id) DO UPDATE SET event_id = prior.event_id
WHERE prior.event_id = excluded.event_id RETURNING event_id;

PREPARE resolve_player(text,text) AS
SELECT player_id FROM intake.player_id_mapping WHERE (provider,external_id) = ($1,$2);

PREPARE resolve_course(text,text) AS
SELECT course_id FROM intake.course_id_mapping WHERE (provider,external_id) = ($1,$2);

PREPARE resolve_event(text,text,text,text) AS
SELECT event_id FROM intake.event_id_mapping
WHERE (provider,namespace,season_id,external_id) = ($1,$2,$3,$4);

PREPARE quarantine_record(bigint,text,text) AS
UPDATE intake.record SET state = 'quarantined', reason = $3
WHERE (observation_id,record_key) = ($1,$2) AND state = 'pending'
RETURNING observation_id, record_key;

-- Caller marks accepted in the same transaction as canonical writes.
PREPARE accept_record(bigint,text) AS
UPDATE intake.record SET state = 'accepted', reason = NULL
WHERE (observation_id,record_key) = ($1,$2) AND state = 'pending'
RETURNING observation_id, record_key;
