"""Small live smoke suite for representative non-default PGA TOUR feeds.

This intentionally checks only events whose response shapes have been verified
and whose data is historical. It is not part of the offline test suite: the
PGA TOUR service is browser-facing and may change or rate-limit requests.
"""

from __future__ import annotations

import pga_tour_api as pga


def _require_rows(name: str, frame, minimum: int = 1) -> None:
    if len(frame) < minimum:
        raise RuntimeError(f"{name} returned {len(frame)} rows; expected at least {minimum}")


def main() -> None:
    checks = []
    playoff = pga.pga_playoff_scorecard("R2024003")
    _require_rows("PlayoffScorecardV3 (WM Phoenix Open 2024)", playoff, 2)
    checks.append(("playoff scorecard", len(playoff)))
    playoff_shots = pga.pga_playoff_shot_details("R2024003")
    _require_rows("PlayoffShotDetailsCompressed (WM Phoenix Open 2024)", playoff_shots)
    checks.append(("playoff shot details", len(playoff_shots)))
    team = pga.pga_team_stroke_play_leaderboard("R2023018")
    _require_rows("TeamStrokePlayLeaderboardCompressed (Zurich Classic 2023)", team)
    checks.append(("team stroke play", len(team)))
    match_play = pga.pga_match_play_leaderboard("R2023470")
    _require_rows("MatchPlayLeaderboardCompressed (WGC-Dell 2023)", match_play)
    if match_play["round"].isna().all():
        raise RuntimeError("match-play response did not contain round metadata")
    checks.append(("match play", len(match_play)))
    cup = pga.pga_cup_team_roster("R2024500")
    _require_rows("CupTeamRoster (Presidents Cup 2024)", cup)
    checks.append(("cup team roster", len(cup)))
    for name, rows in checks:
        print(f"OK  {name}: {rows} rows")


if __name__ == "__main__":
    main()
