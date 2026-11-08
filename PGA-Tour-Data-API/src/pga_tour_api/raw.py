"""Standard-library client for PGA TOUR's browser-facing data services."""

from __future__ import annotations

import base64
import gzip
import json
import os
import random
import time
import urllib.error
import urllib.request
from importlib import resources
from typing import Any, Optional


GRAPHQL_URL = "https://orchestrator.pgatour.com/graphql"
REST_URL = "https://data-api.pgatour.com"
CONFIG_URL = "https://orchestrator-config.pgatour.com"

# Public browser key observed on 2026-09-23. This is not a user credential and
# can rotate. PGA_API_KEY always takes precedence.
DEFAULT_BROWSER_KEY = "da2-gsrx5bibzbb4njvhl7t37wqyl4"


class PgaApiError(RuntimeError):
    """Raised for transport, HTTP, GraphQL, and payload-decoding failures."""


class PgaApi:
    """Client for the public data calls used by ``pgatour.com``.

    Parameters:
        api_key: Public frontend key. Defaults to ``PGA_API_KEY`` and then the
            browser key bundled with this release.
        min_interval: Minimum delay between requests in seconds. The default
            is deliberately conservative because no official limit is published.
        timeout: Per-request timeout in seconds.
        user_agent: Descriptive User-Agent sent with every request.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        min_interval: float = 1.0,
        timeout: float = 30.0,
        user_agent: str = "pga-tour-unofficial-api/0.1",
    ) -> None:
        self.api_key = api_key or os.environ.get("PGA_API_KEY") or DEFAULT_BROWSER_KEY
        self.min_interval = min_interval
        self.timeout = timeout
        self.user_agent = user_agent
        self._last_request = 0.0

    def _headers(self) -> dict[str, str]:
        return {
            "Accept": "application/graphql-response+json, application/json",
            "Content-Type": "application/json",
            "Origin": "https://www.pgatour.com",
            "Referer": "https://www.pgatour.com/",
            "User-Agent": self.user_agent,
            "x-api-key": self.api_key,
            "x-pgat-platform": "web",
        }

    def _request(self, url: str, body: Optional[dict[str, Any]] = None) -> Any:
        wait = self.min_interval - (time.monotonic() - self._last_request)
        if wait > 0:
            time.sleep(wait)

        data = json.dumps(body).encode("utf-8") if body is not None else None
        request = urllib.request.Request(
            url,
            data=data,
            headers=self._headers(),
            method="POST" if body is not None else "GET",
        )

        for attempt in range(3):
            try:
                self._last_request = time.monotonic()
                with urllib.request.urlopen(request, timeout=self.timeout) as response:
                    return json.load(response)
            except urllib.error.HTTPError as exc:
                if exc.code not in {408, 429, 500, 502, 503, 504} or attempt == 2:
                    detail = exc.read(300).decode("utf-8", "replace")
                    raise PgaApiError(f"HTTP {exc.code}: {detail}") from exc
            except urllib.error.URLError as exc:
                if attempt == 2:
                    raise PgaApiError(str(exc)) from exc
            time.sleep((2**attempt) + random.random() / 4)

        raise PgaApiError("request failed after retries")

    @staticmethod
    def decompress(payload: str) -> Any:
        """Decode a ``base64(gzip(JSON))`` response payload."""
        try:
            return json.loads(gzip.decompress(base64.b64decode(payload)))
        except Exception as exc:
            raise PgaApiError(f"could not decode compressed payload: {exc}") from exc

    @staticmethod
    def _query_text(operation: str) -> str:
        try:
            return (
                resources.files("pga_tour_api.queries")
                .joinpath(f"{operation}.graphql")
                .read_text(encoding="utf-8")
            )
        except (FileNotFoundError, ModuleNotFoundError) as exc:
            raise PgaApiError(f"unknown GraphQL operation: {operation}") from exc

    def graphql(self, operation: str, variables: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        """Run a bundled GraphQL operation and return its ``data`` object."""
        response = self._request(
            GRAPHQL_URL,
            {
                "operationName": operation,
                "query": self._query_text(operation),
                "variables": variables or {},
            },
        )
        if response.get("errors"):
            messages = "; ".join(
                item.get("message", "") for item in response["errors"]
            )
            raise PgaApiError(messages)
        return response.get("data", {})

    def rest(self, path: str) -> Any:
        """GET a path from ``data-api.pgatour.com``."""
        return self._request(f"{REST_URL}/{path.lstrip('/')}")

    def config(self) -> dict[str, Any]:
        """Return the frontend's current tournaments and active seasons."""
        return self._request(f"{CONFIG_URL}/web-config")

    def _root(self, operation: str, variables: dict[str, Any], root: str) -> Any:
        return self.graphql(operation, variables).get(root)

    def _compressed(self, operation: str, variables: dict[str, Any], root: str) -> Any:
        value = self._root(operation, variables, root)
        if not value or not value.get("payload"):
            return None
        return self.decompress(value["payload"])

    # Discovery and REST -------------------------------------------------

    def current_tournament(self, tour: str = "R") -> str:
        """Return the default/current tournament ID for a tour."""
        events = self.config().get("defaultTournaments", {}).get(tour, [])
        if not events:
            raise PgaApiError(f"no current tournament for tour {tour!r}")
        return events[0].get("leaderboardId") or events[0]["id"]

    def schedule(self, year: int, tour: str = "R") -> dict[str, Any]:
        """Return a season schedule."""
        return self.rest(f"schedule/{tour}/{year}")

    def players(self, tour: str = "R") -> dict[str, Any]:
        """Return the full player directory for a tour."""
        return self.rest(f"player/list/{tour}")

    def player_profile(self, player_id: str) -> dict[str, Any]:
        """Return profile overview data for a player."""
        return self.rest(f"player/profiles/{player_id}")

    def player_career(self, player_id: str) -> dict[str, Any]:
        """Return career achievements and totals for a player."""
        return self.rest(f"player/profiles/{player_id}/career")

    def player_results(self, player_id: str, season: Optional[int] = None) -> dict[str, Any]:
        """Return tournament results for a player, optionally for one season."""
        suffix = f"?season={season}" if season is not None else ""
        return self.rest(f"player/profiles/{player_id}/results{suffix}")

    def player_stats(self, player_id: str) -> dict[str, Any]:
        """Return the complete profile statistics response for a player."""
        return self.rest(f"player/profiles/{player_id}/stats")

    def player_bio(self, player_id: str) -> dict[str, Any]:
        """Return biography and amateur highlights for a player."""
        return self.rest(f"player/profiles/{player_id}/bio")

    def odds_markets(self, tournament_id: str) -> Any:
        """Return the active betting-market catalog for a tournament."""
        return self.rest(f"odds/tournament/{tournament_id}")

    def player_odds(self, tournament_id: str, player_id: str) -> Any:
        """Return active betting markets for one player."""
        return self.rest(f"odds/tournament/{tournament_id}/player/{player_id}")

    def odds_interactivity(self) -> Any:
        """Return configuration used by the odds widgets."""
        return self.rest("odds/interactivity")

    def speed_rounds(self, tour: str = "R") -> Any:
        """Return the speed-round video index for a tour."""
        return self.rest(f"content/watch/speedRounds/{tour}")

    # Tournament GraphQL -------------------------------------------------

    def leaderboard(self, tournament_id: str) -> Any:
        """Return a decoded full leaderboard."""
        return self._compressed(
            "LeaderboardCompressedV3",
            {"leaderboardCompressedV3Id": tournament_id},
            "leaderboardCompressedV3",
        )

    def current_leaders(self, tournament_id: str) -> Any:
        """Return and decode the compact current-leaders payload."""
        return self._compressed(
            "CurrentLeadersCompressed",
            {"tournamentId": tournament_id},
            "currentLeadersCompressed",
        )

    def field(self, tournament_id: str, include_withdrawn: bool = True) -> Any:
        """Return the event field, alternates, and optional withdrawals."""
        return self._root(
            "Field",
            {"fieldId": tournament_id, "includeWithdrawn": include_withdrawn, "changesOnly": False},
            "field",
        )

    def field_stats(self, tournament_id: str, stat_type: str = "CURRENT_FORM") -> Any:
        """Return current-form or course-fit data for the event field."""
        return self._root(
            "FieldStats",
            {"tournamentId": tournament_id, "fieldStatType": stat_type},
            "fieldStats",
        )

    def leaderboard_holes(self, tournament_id: str, round: Optional[int] = None) -> Any:
        """Return whole-field hole-by-hole scores for a round."""
        return self._root(
            "LeaderboardHoleByHole",
            {"tournamentId": tournament_id, "round": round},
            "leaderboardHoleByHole",
        )

    def tee_times(self, tournament_id: str) -> Any:
        """Return and decode tee groups and player assignments."""
        return self._compressed(
            "TeeTimesCompressedV2",
            {"teeTimesCompressedV2Id": tournament_id},
            "teeTimesCompressedV2",
        )

    def scorecard(self, tournament_id: str, player_id: str) -> Any:
        """Return and decode one player's hole-by-hole scorecard."""
        return self._compressed(
            "ScorecardCompressedV3",
            {"tournamentId": tournament_id, "playerId": player_id},
            "scorecardCompressedV3",
        )

    def shot_details(
        self,
        tournament_id: str,
        player_id: str,
        round: int,
        include_radar: bool = False,
    ) -> Any:
        """Return and decode shot-level tracking for one player and round."""
        return self._compressed(
            "shotDetailsV4Compressed",
            {
                "tournamentId": tournament_id,
                "playerId": player_id,
                "round": round,
                "includeRadar": include_radar,
            },
            "shotDetailsV4Compressed",
        )

    def odds(self, tournament_id: str) -> Any:
        """Return and decode tournament winner odds."""
        return self._compressed(
            "oddsToWinCompressed",
            {"tournamentId": tournament_id},
            "oddsToWinCompressed",
        )

    def historical_odds(
        self,
        tournament_id: str,
        player_id: str,
        market_id: str = "WINNER",
        time_stamp: Optional[str] = None,
    ) -> Any:
        """Return historical odds for one player and market."""
        variables: dict[str, Any] = {
            "playerId": player_id,
            "tournamentId": tournament_id,
            "marketId": market_id,
        }
        if time_stamp is not None:
            variables["timeStamp"] = time_stamp
        return self._root("HistoricalOdds", variables, "historicalOdds")

    def historical_tournaments_odds(
        self,
        tournament_id: str,
        market_id: str = "WINNER",
        time_stamp: Optional[str] = None,
    ) -> Any:
        """Return historical tournament odds and market options."""
        variables: dict[str, Any] = {
            "tournamentId": tournament_id,
            "marketId": market_id,
        }
        if time_stamp is not None:
            variables["timeStamp"] = time_stamp
        return self._root(
            "HistoricalTournamentsOdds", variables, "historicalTournamentsOdds"
        )

    def coverage(self, tournament_id: str) -> Any:
        """Return television and streaming coverage windows."""
        return self._root("Coverage", {"tournamentId": tournament_id}, "coverage")

    def weather(self, tournament_id: str) -> Any:
        """Return hourly and daily tournament weather forecasts."""
        return self._root("Weather", {"tournamentId": tournament_id}, "weather")

    def course_stats(self, tournament_id: str) -> Any:
        """Return per-hole course scoring statistics."""
        return self._root("CourseStats", {"tournamentId": tournament_id}, "courseStats")

    def tournaments(self, ids: list[str]) -> Any:
        """Return metadata for one or more tournament IDs."""
        return self._root("Tournaments", {"ids": ids}, "tournaments")

    def tournament_overview(self, tournament_id: str) -> Any:
        """Return overview tiles, defending champion, and past champions."""
        return self._root(
            "TournamentOverview", {"tournamentId": tournament_id}, "tournamentOverview"
        )

    def tournament_past_results(self, tournament_id: str, year: Optional[int] = None) -> Any:
        """Return a historical leaderboard for an event and optional year."""
        return self._root(
            "TournamentPastResults",
            {"tournamentPastResultsId": tournament_id, "year": year},
            "tournamentPastResults",
        )

    def scorecard_comparison(
        self,
        tournament_id: str,
        player_ids: list[str],
        category: str = "SCORING",
    ) -> Any:
        """Compare a group of players in a scorecard-stat category."""
        return self._root(
            "ScorecardStatsComparisonCategories",
            {
                "tournamentId": tournament_id,
                "playerIds": player_ids,
                "category": category,
            },
            "scorecardStatsComparison",
        )

    # Statistics and content --------------------------------------------

    def stat_overview(self, year: Optional[int] = None, tour: str = "R") -> Any:
        """Return all available stat categories and IDs for a season."""
        return self._root("StatOverview", {"tourCode": tour, "year": year}, "statOverview")

    def stats(
        self,
        stat_id: str,
        year: Optional[int] = None,
        tour: str = "R",
        event_query: Optional[str] = None,
    ) -> Any:
        """Return a raw ranking table for one stat and season."""
        return self._root(
            "StatDetails",
            {"tourCode": tour, "statId": stat_id, "year": year, "eventQuery": event_query},
            "statDetails",
        )

    def fedex_cup(
        self,
        year: Optional[int] = None,
        tour: str = "R",
        event_query: Optional[str] = None,
    ) -> Any:
        """Return raw FedExCup or equivalent tour standings."""
        return self._root(
            "TourCupSplit",
            {"tourCode": tour, "id": None, "year": year, "eventQuery": event_query},
            "tourCupSplit",
        )

    def signature_standings(self, tour: str = "R") -> Any:
        """Return signature-event or Aon standings."""
        return self._root(
            "SignatureStandings", {"tourCode": tour}, "signatureStandings"
        )

    def priority_rankings(self, year: Optional[int] = None, tour: str = "R") -> Any:
        """Return exemption and priority-ranking categories."""
        return self._root(
            "PriorityRankings",
            {"tourCode": tour, "year": year},
            "priorityRankings",
        )

    def course_stats_overview(self, year: Optional[int] = None, tour: str = "R") -> Any:
        """Return the season's course-statistics overview."""
        return self._root(
            "CourseStatsOverview",
            {"tourCode": tour, "year": year},
            "courseStatsOverview",
        )

    def player_tournament_status(self, player_id: str) -> Any:
        """Return a player's status in the active tournament, if present."""
        return self._root(
            "getPlayerTournamentStatus",
            {"playerId": player_id},
            "playerTournamentStatus",
        )

    def news(
        self,
        tour: str = "R",
        limit: int = 20,
        offset: int = 0,
        franchises: Optional[list[str]] = None,
        player_ids: Optional[list[str]] = None,
    ) -> Any:
        """Return paginated news with optional franchise and player filters."""
        return self._root(
            "NewsArticles",
            {
                "tour": tour,
                "franchises": franchises,
                "playerIds": player_ids,
                "limit": limit,
                "offset": offset,
                "tags": None,
                "sectionName": None,
            },
            "newsArticles",
        )

    def news_franchises(self, tour: str = "R", all_franchises: bool = True) -> Any:
        """Return news categories available for a tour."""
        return self._root(
            "NewsFranchises",
            {"tourCode": tour, "allFranchises": all_franchises},
            "newsFranchises",
        )

    def videos(
        self,
        tournament_id: Optional[str] = None,
        player_ids: Optional[list[str]] = None,
        limit: int = 18,
        offset: int = 0,
    ) -> Any:
        """Return video highlights with optional tournament/player filters."""
        return self._root(
            "Videos",
            {
                "tournamentId": tournament_id,
                "playerIds": player_ids,
                "category": None,
                "franchise": None,
                "franchises": None,
                "tourCode": "R",
                "season": None,
                "limit": limit,
                "offset": offset,
                "holeNumber": None,
                "rating": None,
            },
            "videos",
        )

    def tourcast_videos(
        self,
        tournament_id: str,
        player_id: str,
        round: int,
        hole: Optional[int] = None,
        shot: Optional[int] = None,
    ) -> Any:
        """Return TOURCAST clips for a player, round, hole, or shot."""
        return self._root(
            "TourcastVideos",
            {
                "tournamentId": tournament_id,
                "playerId": player_id,
                "round": round,
                "hole": hole,
                "shot": shot,
            },
            "tourcastVideos",
        )

    def content(self, path: str) -> Any:
        """Return and decode a generic CMS fragment by site path."""
        return self._compressed(
            "GenericContentCompressed",
            {"path": path},
            "genericContentCompressed",
        )

    def dp_world_tour_eligibility(self, year: Optional[int] = None,
                                  tour: str = "R") -> Any:
        """Return raw DP World Tour Race to Dubai eligibility standings."""
        return self._root("TourCupSplit", {"tourCode": tour, "id": "2700",
                          "year": year, "eventQuery": None}, "tourCupSplit")

    def playoff_scorecard(self, tournament_id: str) -> Any:
        """Return raw playoff scorecard summaries and hole scores."""
        return self._root("PlayoffScorecardV3", {"tournamentId": tournament_id},
                          "playoffScorecardV3")

    def playoff_shot_details(self, tournament_id: str) -> Any:
        """Return decoded playoff shot details."""
        return self._compressed("PlayoffShotDetailsCompressed", {"tournamentId": tournament_id},
                                "playoffShotDetailsCompressed")

    def team_stroke_play_leaderboard(self, tournament_id: str) -> Any:
        """Return decoded team-stroke-play standings."""
        return self._compressed("TeamStrokePlayLeaderboardCompressed",
            {"teamStrokePlayLeaderboardCompressedId": tournament_id},
            "teamStrokePlayLeaderboardCompressed")

    def match_play_leaderboard(self, tournament_id: str) -> Any:
        """Return decoded match-play rounds, brackets, matches and players."""
        return self._compressed("MatchPlayLeaderboardCompressed",
            {"matchPlayLeaderboardCompressedId": tournament_id},
            "matchPlayLeaderboardCompressed")

    def cup_team_roster(self, tournament_id: str) -> Any:
        """Return team/cup roster and player results."""
        return self._root("CupTeamRoster", {"tournamentId": tournament_id}, "cupTeamRoster")

    def power_rankings(self, path: str) -> Any:
        """Return a raw editorial Power Rankings content fragment."""
        return self._root("GetPowerRankingsTable", {"path": path}, "getPowerRankingsTable")

    def expert_picks(self, path: str) -> Any:
        """Return a raw editorial Expert Picks content fragment."""
        return self._root("GetExpertPicksTable", {"path": path}, "getExpertPicksTable")


    def scorecard_stats(self, tournament_id: str, player_id: str) -> Any:
        """Return decoded player tournament statistics, including every round."""
        return self._compressed("ScorecardStatsV3Compressed",
            {"scorecardStatsV3CompressedId": tournament_id, "playerId": player_id},
            "scorecardStatsV3Compressed")

    def course_stats_details(self, query_type: str = "TOUGHEST_COURSE",
                             year: int | None = None, tour: str = "R",
                             round: str = "ALL") -> Any:
        """Return the full course/hole ranking table and selector metadata."""
        return self._root("CourseStatsDetails",
            {"tourCode": tour, "queryType": query_type, "year": year, "round": round},
            "courseStatsDetails")

    def record_catalog(self, tour: str = "R") -> Any:
        """Return the hierarchical all-time record catalogue."""
        return self._root("AllTimeRecordCategories", {"tourCode": tour},
                          "allTimeRecordCategories")

    def all_time_records(self, record_id: str, tour: str = "R") -> Any:
        """Return one all-time record table, unchanged from the source."""
        return self._root("AllTimeRecordStat",
            {"tourCode": tour, "recordId": record_id}, "allTimeRecordStat")

    def player_comparison(self, player_ids: list[str], category: str = "SCORING",
                          year: int | None = None, tour: str = "R",
                          tournament_id: str | None = None) -> Any:
        """Return the PGA TOUR season/category player comparison table."""
        return self._root("PlayerComparison", {
            "tourCode": tour, "playerIds": player_ids, "category": category,
            "year": year, "tournamentId": tournament_id}, "playerComparison")

    def university_rankings(self, year: int | None = None, week: int | None = None) -> Any:
        """Return PGA TOUR University rankings, selectors and event histories."""
        return self._root("UniversityRankings", {"year": year, "week": week}, "universityRankings")

    def university_total_points(self, season: int | None = None, week: int | None = None) -> Any:
        """Return PGA TOUR University combined points table."""
        return self._root("UniversityTotalPoints", {"season": season, "week": week}, "universityTotalPoints")
