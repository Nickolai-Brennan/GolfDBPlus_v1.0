-- Run after install and after preparing all three query files on this connection.
BEGIN;
EXECUTE write_season('2026-PGA',2026,'PGA');
INSERT INTO public.players_tracking (playerid,player_fullname,"pgatourID")
VALUES ('00000000-0000-0000-0000-000000000001','Fixture Player','00042');
INSERT INTO public.courses ("coursesID",course_name)
VALUES ('00000000-0000-0000-0000-000000000002','Fixture Course');
INSERT INTO public.events ("eventsID",event_name,"tourID","seasonID")
VALUES ('00000000-0000-0000-0000-000000000003','Fixture Event','PGA','2026-PGA');
EXECUTE write_event_course('00000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000002');

DO $$
DECLARE
    p constant uuid := '00000000-0000-0000-0000-000000000001';
    c constant uuid := '00000000-0000-0000-0000-000000000002';
    e constant uuid := '00000000-0000-0000-0000-000000000003';
    obs bigint;
    newer bigint;
    repeat_obs bigint;
    resolved uuid;
BEGIN
    EXECUTE 'EXECUTE register_observation(''pgatour'',''fixture'',''test'',
        ''2026-01-01T00:00:00Z'',NULL,' || quote_literal(repeat('a',64)) || ',''fixture://round'',''{}'')'
        INTO obs;
    EXECUTE 'EXECUTE register_observation(''pgatour'',''fixture'',''test'',
        ''2026-01-01T00:00:00Z'',NULL,' || quote_literal(repeat('a',64)) || ',''fixture://round'',''{}'')'
        INTO repeat_obs;
    IF obs IS NULL OR repeat_obs IS DISTINCT FROM obs THEN
        RAISE EXCEPTION 'Observation replay changed identity';
    END IF;
    INSERT INTO intake.observation (provider,operation,request_key,observed_at,payload_sha256,raw_uri)
    VALUES ('pgatour','fixture','test','2026-01-02T00:00:00Z',repeat('a',64),'fixture://round')
    RETURNING observation_id INTO newer;

    EXECUTE format('EXECUTE map_player(''pgatour'',''00042'',%L,%s)',p,obs);
    EXECUTE 'EXECUTE resolve_player(''pgatour'',''00042'')' INTO resolved;
    IF resolved IS DISTINCT FROM p THEN RAISE EXCEPTION 'Provider text ID did not resolve'; END IF;

    EXECUTE format('EXECUTE write_player_info(%L,''Old'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,%s)',p,obs);
    EXECUTE format('EXECUTE write_player_info(%L,''New'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,%s)',p,newer);
    EXECUTE format('EXECUTE write_player_info(%L,''Old'',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,%s)',p,obs);
    IF (SELECT given_name FROM analytics.player_info WHERE player_id = p) IS DISTINCT FROM 'New' THEN
        RAISE EXCEPTION 'Old observation overwrote the current row';
    END IF;

    EXECUTE format('EXECUTE write_course_scorecard(%L,%L,0,1,4,420,%s)',e,c,obs);
    EXECUTE format('EXECUTE write_course_scorecard(%L,%L,2,1,5,510,%s)',e,c,obs);
    FOR r IN 1..2 LOOP
        EXECUTE format('EXECUTE write_player_round(%L,%L,%s,%L,%s,NULL,1,4,NULL)',e,p,r,c,obs);
        EXECUTE format('EXECUTE write_player_hole_score(%L,%L,%s,1,%L,%s,4)',e,p,r,c,obs);
        EXECUTE format('EXECUTE write_player_hole_score(%L,%L,%s,1,%L,%s,4)',e,p,r,c,obs);
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM analytics.course_hole_metrics
        WHERE event_id=e AND round_number=0 AND sample_count=2 AND avg_to_par=-0.5
          AND birdie=1 AND par_count=1) THEN
        RAISE EXCEPTION 'Full-event metrics failed to reconcile rounds';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM analytics.course_hole_metrics
        WHERE event_id=e AND round_number=2 AND sample_count=1 AND avg_to_par=-1) THEN
        RAISE EXCEPTION 'Round setup did not override the event setup';
    END IF;
    IF (SELECT count(*) FROM analytics.course_difficulty_evaluation
        WHERE course_id=c AND season_id='2026-PGA' AND difficulty_rank=1
        AND avg_to_par_per_hole=-0.5) <> 2 THEN
        RAISE EXCEPTION 'Season and event difficulty splits did not reconcile';
    END IF;
END $$;
ROLLBACK;
