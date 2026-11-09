BEGIN;

-- Keep PGA TOUR publication averages distinct from Data Golf round facts.
INSERT INTO analytics.metric_definition (metric_code, version, label, definition, unit_code)
VALUES
 ('pga_sg_total_avg',1,'PGA TOUR SG: Total','Published average total strokes gained per measured round.','strokes'),
 ('pga_sg_t2g_avg',1,'PGA TOUR SG: Tee-to-Green','Published average non-putting strokes gained per measured round.','strokes'),
 ('pga_sg_ott_avg',1,'PGA TOUR SG: Off-the-Tee','Published average off-the-tee strokes gained per measured round.','strokes'),
 ('pga_sg_app_avg',1,'PGA TOUR SG: Approach','Published average approach strokes gained per measured round.','strokes'),
 ('pga_sg_arg_avg',1,'PGA TOUR SG: Around-the-Green','Published average around-the-green strokes gained per measured round.','strokes'),
 ('pga_sg_putt_avg',1,'PGA TOUR SG: Putting','Published average putting strokes gained per measured round.','strokes'),
 ('dg_sg_total_round',1,'Data Golf SG: Total','Course and round field-average score minus player round score, as published by Data Golf.','strokes'),
 ('dg_sg_t2g_round',1,'Data Golf SG: Tee-to-Green','Reported tee-to-green strokes gained for one player round.','strokes'),
 ('dg_sg_ott_round',1,'Data Golf SG: Off-the-Tee','Reported off-the-tee strokes gained for one player round.','strokes'),
 ('dg_sg_app_round',1,'Data Golf SG: Approach','Reported approach strokes gained for one player round.','strokes'),
 ('dg_sg_arg_round',1,'Data Golf SG: Around-the-Green','Reported around-the-green strokes gained for one player round.','strokes'),
 ('dg_sg_putt_round',1,'Data Golf SG: Putting','Reported putting strokes gained for one player round.','strokes'),
 ('dg_round_score',1,'Data Golf Round Score','Reported total strokes for one player round.','strokes'),
 ('dg_driving_dist_round',1,'Data Golf Driving Distance','Published round driving distance. Drive eligibility depends on Data Golf coverage.','yards'),
 ('dg_driving_acc_round',1,'Data Golf Driving Accuracy','Published round driving accuracy under source eligibility and lie rules. Stored as 0 to 100.','percent'),
 ('dg_gir_round',1,'Data Golf Greens in Regulation','Published round greens in regulation under source coverage rules. Stored as 0 to 100.','percent'),
 ('dg_scrambling_round',1,'Data Golf Scrambling','Published round success rate on eligible recovery shots. Stored as 0 to 100.','percent')
ON CONFLICT (metric_code,version) DO NOTHING;

INSERT INTO intake.metric_id_mapping (provider,external_id,metric_code,metric_version)
VALUES
 ('pgatour','02675','pga_sg_total_avg',1),
 ('pgatour','02674','pga_sg_t2g_avg',1),
 ('pgatour','02567','pga_sg_ott_avg',1),
 ('pgatour','02568','pga_sg_app_avg',1),
 ('pgatour','02569','pga_sg_arg_avg',1),
 ('pgatour','02564','pga_sg_putt_avg',1),
 ('datagolf','sg_total','dg_sg_total_round',1),
 ('datagolf','sg_t2g','dg_sg_t2g_round',1),
 ('datagolf','sg_ott','dg_sg_ott_round',1),
 ('datagolf','sg_app','dg_sg_app_round',1),
 ('datagolf','sg_arg','dg_sg_arg_round',1),
 ('datagolf','sg_putt','dg_sg_putt_round',1),
 ('datagolf','round_score','dg_round_score',1),
 ('datagolf','driving_dist','dg_driving_dist_round',1),
 ('datagolf','driving_acc','dg_driving_acc_round',1),
 ('datagolf','gir','dg_gir_round',1),
 ('datagolf','scrambling','dg_scrambling_round',1)
ON CONFLICT (provider,external_id) DO NOTHING;

COMMIT;
