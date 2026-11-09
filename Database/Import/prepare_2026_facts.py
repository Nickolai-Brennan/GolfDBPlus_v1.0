"""Validate archive facts and prepare connector-sized JSON batches for SQL loading."""

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import minimize_scalar
from scipy.special import softmax
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import log_loss

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "Data/Source-Files"
API = ROOT / "PGA-Tour-Data-API/data"
EVENT = "R2026030"
HOLE = ["tournament_id", "player_id", "round", "course_id", "hole"]
ROUND = HOLE[:-1]
SHOT = HOLE + ["stroke"]
MODEL = "putt-outcomes-2026-v1"


def model_putts(shots, times):
    # The previous stroke's measured remaining distance is available before a putt.
    ordered = shots.sort_values(SHOT)
    group = ordered.groupby(HOLE, sort=False)
    previous = group["stroke"].shift()
    ordered["start_yards"] = group["distance_remaining"].shift().where(
        ordered.stroke.eq(previous + 1) & group["stroke_type"].shift().eq("STROKE")
    )
    putts = ordered.loc[
        ordered.from_location.eq("Green") & ordered.stroke_type.eq("STROKE")
        & ordered.start_yards.gt(0) & ordered.start_yards.le(50)
        & (ordered.final_stroke | ordered.distance_remaining.ge(0))
    ].copy()
    putts["target"] = np.select([putts.final_stroke, putts.distance_remaining.le(1)], [0, 1], default=2)
    starts = times.groupby("tournament_id").tee_time.min()
    dates = putts.tournament_id.map(starts)
    ends = times.groupby("tournament_id").tee_time.max()
    if (dates.isna().any() or
            ends[starts.lt("2026-06-01")].ge("2026-06-01").any() or
            ends[starts.ge("2026-06-01") & starts.lt("2026-07-01")].ge("2026-07-01").any()):
        raise ValueError("The source events do not respect the chronological split")
    train = dates.lt("2026-06-01")
    calibrate = dates.ge("2026-06-01") & dates.lt("2026-07-01")
    holdout = dates.ge("2026-07-01")
    distance = np.log1p(3 * putts.start_yards.to_numpy())
    features = np.column_stack([distance, distance**2, distance**3])
    fit = LogisticRegression(max_iter=500).fit(features[train], putts.target[train])
    logits = fit.decision_function(features)
    result = minimize_scalar(
        lambda t: log_loss(putts.target[calibrate], softmax(logits[calibrate] / t, axis=1)),
        bounds=(0.2, 5.0), method="bounded",
    )
    if not result.success:
        raise RuntimeError("Temperature calibration failed")
    probs = softmax(logits / result.x, axis=1)
    actual = np.eye(3)[putts.target[holdout]]
    predicted = probs[holdout]
    baseline = np.broadcast_to(np.bincount(putts.target[train], minlength=3) / train.sum(), actual.shape)
    ece = []
    for outcome in range(3):
        error = 0
        for lower in np.arange(10) / 10:
            mask = (predicted[:, outcome] >= lower) & (predicted[:, outcome] < lower + 0.1)
            if lower == 0.9:
                mask |= predicted[:, outcome] == 1
            if mask.any():
                error += mask.mean() * abs(predicted[mask, outcome].mean() - actual[mask, outcome].mean())
        ece.append(error)
    metrics = {
        "fit_putts": int(train.sum()), "calibration_putts": int(calibrate.sum()),
        "holdout_putts": int(holdout.sum()), "holdout_events": int(putts[holdout].tournament_id.nunique()),
        "temperature": float(result.x), "holdout_log_loss": log_loss(actual, predicted),
        "uncalibrated_log_loss": log_loss(actual, softmax(logits[holdout], axis=1)),
        "baseline_log_loss": log_loss(actual, baseline),
        "holdout_brier": np.square(actual - predicted).sum(axis=1).mean(),
        "baseline_brier": np.square(actual - baseline).sum(axis=1).mean(),
        "classwise_ece": ece, "model_version": MODEL, "as_of": "2026-07-01T00:00:00Z",
        "coefficients": fit.coef_.tolist(), "intercepts": fit.intercept_.tolist(),
    }
    if max(ece) > 0.05 or metrics["holdout_log_loss"] >= metrics["baseline_log_loss"] or metrics["holdout_brier"] >= metrics["baseline_brier"]:
        raise RuntimeError(f"Holdout gate failed: {metrics}")
    putts[["perfect", "probable", "worst"]] = probs
    return putts, metrics


def write_batches(out, name, frame, size):
    for start in range(0, len(frame), size):
        (out / f"{name}-{start // size:03}.json").write_text(
            frame.iloc[start:start + size].to_json(orient="values", date_format="iso", double_precision=8),
            encoding="utf-8",
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--batch-size", type=int, default=800)
    args = parser.parse_args()
    if args.batch_size < 1:
        parser.error("--batch-size must be positive")
    out = args.output
    out.mkdir(parents=True, exist_ok=False)
    shots = pd.read_parquet(DATA / "shots_2026.parquet")
    setup = pd.read_parquet(DATA / "course_setup_2026.parquet")
    times = pd.read_parquet(DATA / "tee_times_2026.parquet")
    if any(not frame.season.eq(2026).all() for frame in (shots, setup, times)):
        raise ValueError("Unexpected season in 2026 archive")
    leaderboard = pd.read_csv(API / f"leaderboard_{EVENT}.csv", dtype={"player_id": str})
    rcols = [f"round_{i}" for i in range(1, 5)]
    results = leaderboard.melt(id_vars="player_id", value_vars=rcols, var_name="round", value_name="published")
    results["round"] = results["round"].str[-1].astype(int)
    results["published"] = pd.to_numeric(results.published, errors="coerce")
    results = results.dropna(subset="published")
    results["tournament_id"] = EVENT
    finals = shots.loc[shots.tournament_id.eq(EVENT) & shots.final_stroke & shots.stroke_type.eq("STROKE")]
    if finals.duplicated(HOLE).any():
        raise ValueError("Multiple final strokes for a replay hole")
    if not (finals.hole_score.gt(0) & finals.hole_score.mod(1).eq(0)).all():
        raise ValueError("Invalid final hole score")
    holes = finals[HOLE + ["hole_score"]].merge(
        setup[["tournament_id", "round", "course_id", "hole", "par"]],
        on=["tournament_id", "round", "course_id", "hole"], validate="many_to_one",
    )
    totals = holes.groupby(ROUND).agg(score=("hole_score", "sum"), holes=("hole", "size"), par=("par", "sum")).reset_index()
    rounds = results.merge(totals, on=ROUND[:-1], validate="one_to_one")
    if len(rounds) != len(results) or not rounds.holes.eq(18).all() or not rounds.score.eq(rounds.published).all():
        raise ValueError("Archived round totals do not reconcile with the published leaderboard")
    rounds["over_under"] = rounds.score - rounds.par
    rounds = rounds.merge(times[ROUND + ["tee_time", "start_tee"]], on=ROUND, validate="one_to_one")
    if len(rounds) != len(results):
        raise ValueError("Missing tee times for published rounds")
    verified_holes = holes.merge(rounds[ROUND], on=ROUND, validate="many_to_one")

    duplicate = shots.duplicated(SHOT, keep=False)
    # Exclude the full ambiguous stroke group, including the first row.
    unique = shots.loc[~duplicate].copy()
    putts, metrics = model_putts(unique, times)
    replay = unique[unique.tournament_id.eq(EVENT) & unique.stroke_type.eq("STROKE")].merge(
        verified_holes[HOLE], on=HOLE, validate="many_to_one",
    )
    replay = replay.merge(putts[SHOT + ["start_yards", "perfect", "probable", "worst"]],
                          on=SHOT, how="left", validate="one_to_one")
    replay["source_shot_id"] = "archive2026:" + replay.hole.astype(str) + ":" + replay.stroke.astype(str)
    replay["is_putt"] = replay.from_location.eq("Green")
    replay["shot_distance"] = replay.distance.where(~replay.is_putt, replay.distance * 3)
    replay["remaining"] = replay.distance_remaining.mask(replay.final_stroke, 0)

    venues = times[["course_id", "course_name"]].drop_duplicates()
    events = times[["tournament_id", "tournament_name"]].drop_duplicates()
    if venues.course_id.duplicated().any() or events.tournament_id.duplicated().any():
        raise ValueError("Conflicting event or course labels")
    event_courses = times[["tournament_id", "course_id"]].drop_duplicates()
    events = events.merge(event_courses[event_courses.groupby("tournament_id").course_id.transform("size").eq(1)],
                          on="tournament_id", how="left")
    # Scheduled dates for the replay event are independently present in the API archive.
    events["starts_on"] = events.tournament_id.map({EVENT: "2026-07-02"})
    events["ends_on"] = events.tournament_id.map({EVENT: "2026-07-05"})
    leaderboard["position_display"] = leaderboard.position.astype(str)
    leaderboard["rank"] = pd.to_numeric(leaderboard.position_display.str.extract(r"^T?(\d+)$")[0])
    leaderboard["score_to_par"] = pd.to_numeric(leaderboard.total.replace({"E": "0"}), errors="coerce")
    leaderboard["status"] = np.select([leaderboard.position_display.eq("CUT"), leaderboard.position_display.eq("WD")],
                                       ["cut", "withdrawn"], default="finished")
    leaderboard["event_id"] = EVENT

    write_batches(out, "venues", venues, args.batch_size)
    write_batches(out, "events", events[["tournament_id", "tournament_name", "course_id", "starts_on", "ends_on"]], args.batch_size)
    write_batches(out, "event_courses", event_courses, args.batch_size)
    write_batches(out, "course", setup[["tournament_id", "course_id", "round", "hole", "par", "yardage"]], args.batch_size)
    write_batches(out, "rounds", rounds[ROUND + ["tee_time", "start_tee", "score", "over_under"]], args.batch_size)
    write_batches(out, "holes", verified_holes[HOLE + ["hole_score"]], args.batch_size)
    write_batches(out, "results", leaderboard[["event_id","player_id","rank","position_display","status","total_strokes","score_to_par"]], args.batch_size)
    write_batches(out, "shots", replay[ROUND + ["source_shot_id","hole","par","from_x","from_y","to_x","to_y",
                    "start_yards","is_putt","shot_distance","launch_direction","club_speed","apex_height","smash_factor",
                    "remaining","final_stroke","perfect","probable","worst"]], args.batch_size)
    metrics.update(replay_rounds=len(rounds), replay_holes=len(verified_holes),
                   replay_results=len(leaderboard), replay_shots=len(replay),
                   replay_predictions=int(replay.perfect.notna().sum()), ambiguous_archive_rows=int(duplicate.sum()),
                   course_rows=int(setup["round"].between(0, 4).sum()),
                   excluded_nonregulation_course_rows=int((~setup["round"].between(0, 4)).sum()),
                   archive_shot_sha256=hashlib.file_digest(
                       (DATA / "shots_2026.parquet").open("rb"), "sha256").hexdigest())
    (out / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
