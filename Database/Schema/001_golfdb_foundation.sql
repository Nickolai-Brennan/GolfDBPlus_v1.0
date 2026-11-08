-- PostgreSQL 15+; canonical GolfDB+ entity registry.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS tours (
  "tourID" TEXT PRIMARY KEY CHECK ("tourID" IN ('PGA','DP','LIV','SEN','ASIA')),
  tour_name TEXT NOT NULL
);
INSERT INTO tours ("tourID",tour_name) VALUES
('PGA','PGA TOUR'),('DP','DP World Tour'),('LIV','LIV Golf'),
('SEN','Senior/Champions'),('ASIA','Asian Tour')
ON CONFLICT ("tourID") DO NOTHING;

CREATE TABLE IF NOT EXISTS seasons (
  "seasonID" TEXT PRIMARY KEY,
  season_year INTEGER NOT NULL CHECK (season_year BETWEEN 1900 AND 2200),
  "tourID" TEXT NOT NULL REFERENCES tours("tourID"),
  CONSTRAINT season_format CHECK ("seasonID" = season_year::text || '-' || "tourID"),
  UNIQUE(season_year,"tourID")
);

CREATE TABLE IF NOT EXISTS players_tracking (
  playerid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_fullname TEXT NOT NULL,
  nationality_country CHAR(3) CHECK (nationality_country ~ '^[A-Z]{3}$'),
  current_location TEXT,
  "datagolfID" TEXT,
  "pgatourID" TEXT,
  "espnID" TEXT,
  "cbssportsID" TEXT,
  "rickrungoodID" TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_players_datagolf ON players_tracking("datagolfID") WHERE "datagolfID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_players_pgatour ON players_tracking("pgatourID") WHERE "pgatourID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_players_espn ON players_tracking("espnID") WHERE "espnID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_players_cbs ON players_tracking("cbssportsID") WHERE "cbssportsID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_players_rrg ON players_tracking("rickrungoodID") WHERE "rickrungoodID" IS NOT NULL;

CREATE TABLE IF NOT EXISTS courses (
  "coursesID" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_name TEXT NOT NULL,
  country_code CHAR(3) CHECK (country_code ~ '^[A-Z]{3}$'),
  country_flag TEXT, -- optional UI asset reference; do not use as country identifier
  "pgatour_coursesID" TEXT,
  "datagolf_coursesID" TEXT,
  location_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_courses_pgatour ON courses("pgatour_coursesID") WHERE "pgatour_coursesID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_courses_datagolf ON courses("datagolf_coursesID") WHERE "datagolf_coursesID" IS NOT NULL;

CREATE TABLE IF NOT EXISTS events (
  "eventsID" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  "tourID" TEXT NOT NULL REFERENCES tours("tourID"),
  "seasonID" TEXT NOT NULL REFERENCES seasons("seasonID"),
  "coursesID" UUID REFERENCES courses("coursesID"),
  "pgatour_eventsID" TEXT,
  "datagolf_eventsID" TEXT,
  starts_on DATE,
  ends_on DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT event_season_tour_match CHECK ("seasonID" LIKE '%-' || "tourID"),
  CONSTRAINT valid_event_dates CHECK (ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on)
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_event_pgatour_season ON events("seasonID","pgatour_eventsID") WHERE "pgatour_eventsID" IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_event_datagolf_season ON events("seasonID","datagolf_eventsID") WHERE "datagolf_eventsID" IS NOT NULL;

CREATE TABLE IF NOT EXISTS event_documents (
  document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "eventsID" UUID NOT NULL REFERENCES events("eventsID") ON DELETE CASCADE,
  source_system TEXT NOT NULL,
  original_url TEXT NOT NULL,
  title TEXT,
  document_type TEXT NOT NULL,
  round_number SMALLINT CHECK (round_number BETWEEN 1 AND 4),
  published_at TIMESTAMPTZ,
  discovered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  retrieved_at TIMESTAMPTZ,
  sha256 CHAR(64),
  mime_type TEXT,
  bytes BIGINT,
  stored_path TEXT,
  access_status TEXT NOT NULL DEFAULT 'discovered'
    CHECK (access_status IN ('discovered','downloaded','restricted','failed','skipped')),
  license_notes TEXT,
  UNIQUE("eventsID",original_url)
);

CREATE TABLE IF NOT EXISTS content_items (
  content_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  canonical_url TEXT NOT NULL UNIQUE,
  source_system TEXT NOT NULL,
  content_type TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  discovered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  content_text TEXT,
  language_code TEXT DEFAULT 'en',
  sha256 CHAR(64),
  search_vector TSVECTOR GENERATED ALWAYS AS (
    to_tsvector('english',coalesce(title,'') || ' ' || coalesce(content_text,''))
  ) STORED
);
CREATE INDEX IF NOT EXISTS ix_content_search ON content_items USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS ix_content_published ON content_items(published_at);

CREATE TABLE IF NOT EXISTS content_entity_mentions (
  content_id UUID NOT NULL REFERENCES content_items(content_id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('player','event','course')),
  entity_id UUID NOT NULL,
  matched_text TEXT NOT NULL,
  confidence NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
  review_status TEXT NOT NULL DEFAULT 'pending',
  PRIMARY KEY(content_id,entity_type,entity_id,matched_text)
);
-- Application/ETL must validate entity_id against its entity_type target table.
-- Source data may contain aliases and ambiguous player names: review before linking.
