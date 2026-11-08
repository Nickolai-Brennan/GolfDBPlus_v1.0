-- PostgreSQL 15+. Apply once to a new database via psql -v ON_ERROR_STOP=1.
BEGIN;
CREATE SCHEMA ingest;
CREATE SCHEMA reporting;

-- Immutable raw files/responses live at storage_uri. The digest makes retries idempotent.
CREATE TABLE ingest.source (
    source_code text PRIMARY KEY,
    display_name text NOT NULL
);
INSERT INTO ingest.source VALUES
    ('historical_tsv', 'Historical PGA results TSV'),
    ('pga_tour', 'PGA TOUR / Tourcast'),
    ('owgr', 'Official World Golf Ranking'),
    ('golfdb_plus', 'GolfDB+'),
    ('datagolf', 'Data Golf'),
    ('shot_tracker', 'Shot Tracker');

CREATE TABLE ingest.batch (
    batch_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_code text NOT NULL REFERENCES ingest.source,
    dataset text NOT NULL,
    sha256 text NOT NULL CHECK (sha256 ~ '^[a-f0-9]{64}$'),
    storage_uri text NOT NULL,
    retrieved_at timestamptz NOT NULL DEFAULT now(),
    request_context jsonb NOT NULL DEFAULT '{}',
    parser_version text,
    status text NOT NULL DEFAULT 'received'
        CHECK (status IN ('received', 'validated', 'loaded', 'failed')),
    UNIQUE (source_code, dataset, sha256)
);

CREATE TABLE ingest.record (
    batch_id bigint NOT NULL REFERENCES ingest.batch,
    record_key text NOT NULL,
    payload jsonb NOT NULL,
    resolution_status text NOT NULL DEFAULT 'pending'
        CHECK (resolution_status IN ('pending', 'loaded', 'duplicate', 'rejected', 'needs_review')),
    issue text,
    PRIMARY KEY (batch_id, record_key)
);