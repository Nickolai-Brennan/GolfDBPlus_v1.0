"""Emit a transactional, repeatable load of verified April 2021 Masters stats."""

import csv
import hashlib
import io
import json
import sys
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Database/Queries"))
from reconcile_historical_players import reconcile

FIELDS = ("round_score", "sg_total", "sg_t2g", "sg_ott", "sg_app", "sg_arg", "sg_putt",
          "driving_dist", "driving_acc", "gir", "scrambling")
PERCENT = {"driving_acc", "gir", "scrambling"}


def main():
    source_dir = ROOT / "Data/Source-Files"
    source = source_dir / "raw_pga_536_2021.tsv"
    audit = io.StringIO()
    reconcile(source_dir / "pga_results_2001-2025.tsv", source,
              ROOT / "docs/data/player_ids.csv", ROOT / "docs/data/masters_2021_pgatour_roster.csv", audit)
    audit.seek(0)
    crosswalk = {r["datagolf_id"]: r["pgatour_id"] for r in csv.DictReader(audit)
                 if r["identity_status"] == "verified_pgatour"}
    rows = []
    with source.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            if (row["course_num"], row["course_name"], row["course_par"]) != (
                "14", "Augusta National Golf Club", "72"
            ):
                raise ValueError("Unexpected course in verified round archive")
            metrics = {}
            for field in FIELDS:
                raw = row[field].strip()
                if not raw:
                    continue
                value = Decimal(raw)
                if not value.is_finite() or (field in PERCENT and not 0 <= value <= 1):
                    raise ValueError(f"Invalid {field} for {row['dg_id']}")
                metrics[field] = str(value * 100 if field in PERCENT else value)
            rows.append([crosswalk[row["dg_id"]], row["dg_id"], int(row["round_num"]),
                         int(row["round_score"]), int(row["start_hole"]), metrics])
    sha = hashlib.sha256(source.read_bytes()).hexdigest()
    payload = json.dumps(rows, separators=(",", ":")).replace("'", "''")
    template = Path(__file__).with_name("load_masters_stats.sql")
    print(template.read_text().replace("__ARCHIVE_SHA__", sha).replace("__ROWS_JSON__", payload))


if __name__ == "__main__":
    main()
