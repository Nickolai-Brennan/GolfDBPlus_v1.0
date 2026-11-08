CREATE TABLE golf.tour (
    tour_id text PRIMARY KEY,
    tour_name text NOT NULL
);

INSERT INTO golf.tour VALUES ('pga', 'PGA TOUR');

-- Tour season labels can differ from the calendar year of play.
CREATE TABLE golf.tour_season (
    tour_id text REFERENCES golf.tour,
    season smallint, -- (year)
    season_label text,
    starts_on date,
    ends_on date,
    CHECK (starts_on <= ends_on),
    PRIMARY KEY (tour_id, season)
);