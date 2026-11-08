create schema if not exists golf;

CREATE TABLE golf.player (
    player_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name text NOT NULL,
    given_name text,
    family_name text,
    birth_date date,
    nationality_code text,
    headshot_url text,
    is_amateur boolean
);
