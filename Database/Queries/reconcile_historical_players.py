#!/usr/bin/env python3
"""Emit a row-level identity audit for the checked-in historical results TSV."""

import argparse
import csv
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MASTERS_EDITION = ("2021", "2021-04-08", "2021-04-11", "2021 Masters Tournament")
MASTERS_EVENT_ID = "R2021536"
MASTERS_ALIAS = {
    "matthewfitzpatrick": "mattfitzpatrick",
    "ollieosborne": "charlesosborne",
}


def name_key(name):
    return "".join(char for char in unicodedata.normalize("NFKD", name.casefold())
                   if char.isalnum())


def masters_name_key(name):
    key = name_key(name)
    return MASTERS_ALIAS.get(key, key)


def masters_roster(path):
    roster = {}
    with path.open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source):
            key = masters_name_key(row["player_name"])
            player_id = row["pga_player_id"]
            profile = re.fullmatch(
                r"https://www\.pgatour\.com/(?:[a-z-]+/)?player/([0-9]+)(?:/[^?#]*)?",
                row["profile_url"],
            )
            if (row["pgatour_event_id"] != MASTERS_EVENT_ID or not key or key in roster
                    or not profile or profile[1] != player_id):
                raise ValueError(f"Invalid or duplicate Masters roster entry for {key}")
            roster[key] = player_id
    if len(roster) != len(set(roster.values())):
        raise ValueError("Duplicate PGA TOUR player IDs in the Masters roster")
    return roster


def masters_rounds(path):
    by_name = defaultdict(dict)
    id_by_name = {}
    name_by_id = {}
    with path.open(encoding="utf-8-sig", newline="") as source:
        for row in csv.DictReader(source, delimiter="\t"):
            if (row["tour"], row["season"], row["event_id"], row["event_completed"]) != (
                "pga", "2021", "536", "2021-04-11"
            ):
                raise ValueError("Unexpected event in the Masters round source")
            last, first = row["player_name"].split(",", 1)
            key = masters_name_key(f"{first} {last}")
            player_id = row["dg_id"]
            round_number = int(row["round_num"])
            if (not player_id.isdecimal() or round_number not in range(1, 5)
                    or round_number in by_name[key]
                    or id_by_name.setdefault(key, player_id) != player_id
                    or name_by_id.setdefault(player_id, key) != key):
                raise ValueError(f"Conflicting Masters player or round identity for {key}")
            by_name[key][round_number] = int(row["round_score"])
    return id_by_name, by_name


def reconcile(results_path, rounds_path, directory_path, roster_path, output):
    ids, rounds = masters_rounds(rounds_path)
    roster = masters_roster(roster_path)
    if roster.keys() != ids.keys():
        raise ValueError("The Masters roster and round source contain different players")
    # The PGA TOUR directory supplies master IDs, but name matches are only hints.
    candidates = defaultdict(set)
    with directory_path.open(encoding="utf-8-sig", newline="") as directory:
        for row in csv.DictReader(directory):
            if row["pga_player_id"]:
                candidates[name_key(row["player_name"])].add(row["pga_player_id"])

    # Buffer the audit until the two Masters sources pass the full field check.
    audit = []
    matched = set()
    with results_path.open(encoding="utf-8-sig", newline="") as source:
        for row_number, row in enumerate(csv.DictReader(source, delimiter="\t"), start=1):
            key = name_key(row["name"])
            edition = tuple(row[field] for field in ("season", "start", "end", "tournament"))
            player_id = ""
            pgatour_id = ""
            hints = sorted(candidates[key])
            status = {0: "unmatched", 1: "name_candidate"}.get(len(hints), "ambiguous_name")
            if edition == MASTERS_EDITION:
                key = masters_name_key(row["name"])
                scores = {number: int(row[f"round{number}"]) for number in range(1, 5)
                          if row[f"round{number}"]}
                if key in matched or not scores or scores != rounds.get(key):
                    raise ValueError(f"Masters identity or round score conflict at row {row_number}")
                matched.add(key)
                player_id = ids[key]
                pgatour_id = roster[key]
                if hints and hints != [pgatour_id]:
                    raise ValueError(f"Masters roster disagrees with directory candidate at row {row_number}")
                status = "verified_pgatour"
            audit.append((row_number, *edition, row["name"], status,
                          player_id, "|".join(hints), pgatour_id))

    if not matched or matched != ids.keys():
        raise ValueError("The Masters player sets do not match across the two sources")

    writer = csv.writer(output)
    writer.writerow(("source_row", "season", "start", "end", "tournament", "player_name",
                     "identity_status", "datagolf_id", "pgatour_id_candidates", "pgatour_id"))
    writer.writerows(audit)
    return Counter(record[6] for record in audit), sum(map(len, rounds.values()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results", type=Path,
                        default=ROOT / "Data/Source-Files/pga_results_2001-2025.tsv")
    parser.add_argument("--masters-rounds", type=Path,
                        default=ROOT / "Data/Source-Files/raw_pga_536_2021.tsv")
    parser.add_argument("--player-directory", type=Path,
                        default=ROOT / "docs/data/player_ids.csv")
    parser.add_argument("--masters-roster", type=Path,
                        default=ROOT / "docs/data/masters_2021_pgatour_roster.csv")
    args = parser.parse_args()
    try:
        counts, rounds = reconcile(
            args.results, args.masters_rounds, args.player_directory, args.masters_roster, sys.stdout
        )
    except (OSError, ValueError, KeyError, csv.Error) as error:
        parser.exit(1, f"Identity audit failed: {error}\n")
    print(f"Masters rounds verified: {rounds}. Row counts: {dict(sorted(counts.items()))}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
