# PGA Tour GraphQL API Documentation

Reverse-engineered from pgatour.com network traffic (HAR captures).
Captured: 2026-03-19; re-checked 2026-08-15 against frontend `pgatour-prod-2.29.2`.
Public API key unchanged. Tour `Y` (PGA Tour Americas) is first-class.
See the 0.3.0 wrappers for Field, TournamentPastResults, CourseStats,
LeaderboardHoleByHole, Weather, SignatureStandings, PriorityRankings,
and REST `/odds/tournament/{id}` + `/leaderboard/{id}`.

## Base Endpoint

```
POST https://orchestrator.pgatour.com/graphql
Content-Type: application/json
```

### Required Headers

| Header | Value | Notes |
|--------|-------|-------|
| `Content-Type` | `application/json` | Standard |
| `Accept` | `application/graphql-response+json, application/json` | Optional but recommended |
| `x-api-key` | `da2-gsrx5bibzbb4njvhl7t37wqyl4` | Required. Hardcoded in PGA Tour frontend JS — same for all users |
| `x-pgat-platform` | `web` | Required |
| `Origin` | `https://www.pgatour.com` | Recommended |
| `Referer` | `https://www.pgatour.com/` | Recommended |

**Without `x-api-key` and `x-pgat-platform`, the endpoint returns HTTP 503.**

## REST Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET https://data-api.pgatour.com/player/list/{tourCode}` | Full player directory (2,486 players for PGA Tour) |
| `GET https://data-api.pgatour.com/schedule/{tourCode}/{year}` | Full season schedule (48 events for 2026) with dates, purse, course, champion |
| `GET https://data-api.pgatour.com/player/profiles/{playerId}` | Player profile overview (career highlights, bio basics, overview stats) |
| `GET https://data-api.pgatour.com/player/profiles/{playerId}/career` | Career achievements (starts, cuts, wins, finishes, earnings) |
| `GET https://data-api.pgatour.com/player/profiles/{playerId}/results` | Tournament-by-tournament results with round scores |
| `GET https://data-api.pgatour.com/player/profiles/{playerId}/stats` | Full stat profile (131 stats with ranks, values, categories) |
| `GET https://data-api.pgatour.com/player/profiles/{playerId}/bio` | Biographical text, amateur highlights |
| `GET https://data-api.pgatour.com/odds/interactivity` | Odds interactivity config |
| `GET https://data-api.pgatour.com/content/watch/speedRounds/{tourCode}` | Speed rounds content |

## GraphQL Operations Summary

| Operation | Description | Compressed | Key Variables |
|-----------|-------------|------------|---------------|
| `Coverage` | Broadcast/streaming info for a tournament | No | `tournamentId` |
| `CurrentLeadersCompressed` | Quick leaderboard snapshot | Yes (gzip+base64) | `tournamentId` |
| `GenericContentCompressed` | CMS content blocks | Yes (gzip+base64) | `path` |
| `LeaderboardCompressedV3` | Full leaderboard with all player scores | Yes (gzip+base64) | `leaderboardCompressedV3Id` |
| `NewsArticles` | News articles list | No | `franchises, limit, offset, tour` |
| `NewsFranchises` | News franchise/category list | No | `tourCode` |
| `ScorecardCompressedV3` | Hole-by-hole scorecard for a player | Yes (gzip+base64) | `tournamentId, playerId` |
| `ScorecardStatsComparisonCategories` | Stat comparison categories for scorecard view | No | `tournamentId, playerIds, category` |
| `StatDetails` | Any PGA stat with full player rankings (300+ stats) | No | `tourCode, statId, year, eventQuery` |
| `TeeTimesCompressedV2` | Tee times with groupings and start tees | Yes (gzip+base64) | `teeTimesCompressedV2Id` |
| `TourCupSplit` | FedExCup standings | No | `tourCode, id, year` |
| `TourcastVideos` | Shot-by-shot video clips for a player round | No | `tournamentId, playerId, round` |
| `Tournaments` | Tournament metadata, weather, courses | No | `ids: [tournamentId]` |
| `Videos` | Player video highlights | No | `tourCode, playerIds, season, tournamentId` |
| `oddsToWinCompressed` | Odds to win for tournament field | Yes (gzip+base64) | `tournamentId` |
| `shotDetailsV4Compressed` | Shot-level tracking data with coordinates | Yes (gzip+base64) | `tournamentId, playerId, round` |

## Tour Codes

| Code | Tour |
|------|------|
| `R` | PGA Tour |
| `S` | PGA Tour Champions |
| `H` | Korn Ferry Tour |

## Compressed Payload Decoding

Several operations return compressed payloads. To decode:

```python
import base64, gzip, json

payload = response['data']['operationName']['payload']
decoded = base64.b64decode(payload)
decompressed = gzip.decompress(decoded)
data = json.loads(decompressed)
```

---

## Detailed Operation Reference

### Coverage

Broadcast/streaming info for a tournament

**Variables:**
```json
{
  "tournamentId": "R2026475"
}
```

**Query:**
```graphql
query Coverage($tournamentId: ID!) { coverage(tournamentId: $tournamentId) { id tournamentName countryCode coverageType { ... on BroadcastAudioStream { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastFullTelecast { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastFeaturedGroup { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime courseId groups { id extendedCoverage playerLastNames liveStatus } promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastFeaturedHole { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime courseId featuredHoles promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastCoverageCarousel { __typename carousel { ... on BroadcastFullTelecast { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastFeaturedGroup { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime courseId groups { id extendedCoverage playerLastNames liveStatus } promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } ... on BroadcastFeaturedHole { __typename id streamTitle roundNumber channelTitle roundDisplay startTime endTime courseId featuredHoles promoImage promoImages liveStatus network { id networkName backgroundColor backgroundColorDark networkLogo networkLogoDark priorityNum url iOSLink appleAppStore androidLink googlePlayStore simulcast simulcastUrl streamUrl iosStreamUrl androidStreamUrl } } } } } }}
```

### CurrentLeadersCompressed

Quick leaderboard snapshot

**Variables:**
```json
{
  "tournamentId": "R2026475"
}
```

**Query:**
```graphql
query CurrentLeadersCompressed($tournamentId: ID!) { currentLeadersCompressed(tournamentId: $tournamentId) { id payload }}
```

### GenericContentCompressed

CMS content blocks

**Variables:**
```json
{
  "path": "/content/dam/pga-tour/fragments/pages/fedexcup/fedexcup-overview"
}
```

**Query:**
```graphql
query GenericContentCompressed($path: String!) { genericContentCompressed(path: $path) { path payload }}
```

### LeaderboardCompressedV3

Full leaderboard with all player scores

**Variables:**
```json
{
  "leaderboardCompressedV3Id": "R2026475"
}
```

**Query:**
```graphql
query LeaderboardCompressedV3($leaderboardCompressedV3Id: ID!) { leaderboardCompressedV3(id: $leaderboardCompressedV3Id) { id payload }}
```

### NewsArticles

News articles list

**Variables:**
```json
{
  "franchises": [
    ""
  ],
  "limit": 20,
  "offset": 0,
  "tour": "R"
}
```

**Query:**
```graphql
query NewsArticles($tour: TourCode, $franchises: [String!], $playerIds: [ID!], $limit: Int, $offset: Int, $tags: [String!], $sectionName: String) { newsArticles( tour: $tour franchises: $franchises playerIds: $playerIds limit: $limit offset: $offset tags: $tags sectionName: $sectionName ) { articles { ...NewsArticleFragment } franchiseSponsors { franchise image label accessibilityText backgroundColor } integratedComponents { index partner } }}fragment NewsArticleFragment on NewsArticle { id analyticsTags contentTournamentIds dateTextOverride aiGenerated isLive headline teaserHeadline teaserContent articleImage url publishDate updateDate franchise franchiseDisplayName shareURL sponsor { name description logo image websiteUrl gam sponsorPrefix logoAsset { imageOrg imagePath } logoDarkAsset { imageOrg imagePath } } brightcoveId externalLinkOverride players { id name } teaserImageOverride author { firstName lastName } articleFormType}
```

### NewsFranchises

News franchise/category list

**Variables:**
```json
{
  "tourCode": "R",
  "allFranchises": false
}
```

**Query:**
```graphql
query NewsFranchises($tourCode: String, $allFranchises: Boolean) { newsFranchises(tourCode: $tourCode, allFranchises: $allFranchises) { franchise franchiseLabel }}
```

### ScorecardCompressedV3

Hole-by-hole scorecard for a player

**Variables:**
```json
{
  "playerId": "39971",
  "tournamentId": "R2026475"
}
```

**Query:**
```graphql
query ScorecardCompressedV3($tournamentId: ID!, $playerId: ID!) { scorecardCompressedV3(tournamentId: $tournamentId, playerId: $playerId) { id payload }}
```

### ScorecardStatsComparisonCategories

Stat comparison categories for scorecard view

**Variables:**
```json
{
  "tournamentId": "R2026475",
  "playerIds": [],
  "category": "SCORING"
}
```

**Query:**
```graphql
query ScorecardStatsComparisonCategories($tournamentId: String!, $playerIds: [String!]!, $category: PlayerComparisonCategory!) { scorecardStatsComparison( tournamentId: $tournamentId playerIds: $playerIds category: $category ) { tournamentId category categoryPills { displayText category } }}
```

### StatDetails

Any PGA stat with full player rankings (300+ stats)

**Variables:**
```json
{
  "tourCode": "R",
  "statId": "02675",
  "year": null,
  "eventQuery": null
}
```

**Query:**
```graphql
query StatDetails($tourCode: TourCode!, $statId: String!, $year: Int, $eventQuery: StatDetailEventQuery) { statDetails( tourCode: $tourCode statId: $statId year: $year eventQuery: $eventQuery ) { __typename tourCode year displaySeason statId statType tournamentPills { tournamentId displayName } yearPills { year displaySeason } statTitle statDescription tourAvg lastProcessed statHeaders statCategories { category displayName subCategories { displayName stats { statId statTitle } } } rows { ... on StatDetailsPlayer { __typename playerId playerName country countryFlag rank rankDiff rankChangeTendency stats { statName statValue color } } ... on StatDetailTourAvg { __typename displayName value } } sponsorLogo }}
```

### TeeTimesCompressedV2

Tee times with groupings and start tees

**Variables:**
```json
{
  "teeTimesCompressedV2Id": "R2026475"
}
```

**Query:**
```graphql
query TeeTimesCompressedV2($teeTimesCompressedV2Id: ID!) { teeTimesCompressedV2(id: $teeTimesCompressedV2Id) { id payload }}
```

**Decompressed Response Schema:**
```json
{
  "__typename": "TeeTimesV2",
  "id": "R2026475",
  "courses": [{"id": "665", "courseName": "Innisbrook Resort and Golf Club - Copperhead Course"}],
  "defaultRound": 1,
  "rounds": [{
    "roundInt": 1,
    "roundDisplay": "R1",
    "roundStatus": "IN_PROGRESS",
    "groups": [{
      "groupNumber": 1,
      "teeTime": 1773920100000,
      "startTee": 1,
      "backNine": false,
      "players": [{"id": "46340", "firstName": "Alex", "lastName": "Smalley", "displayName": "Alex Smalley", "country": "USA"}]
    }]
  }]
}
```

### TourCupSplit

FedExCup standings

**Variables:**
```json
{
  "tourCode": "R",
  "id": "02671",
  "year": 2026
}
```

**Query:**
```graphql
query TourCupSplit($tourCode: TourCode!, $id: String, $year: Int, $eventQuery: StatDetailEventQuery) { tourCupSplit(tourCode: $tourCode, id: $id, year: $year, eventQuery: $eventQuery) { ...TourCupSplitMeta fixedHeaders columnHeaders rankingsHeader rankEyebrow pointsEyebrow message partner partnerLink projectedPlayers { ...Player ...InfoRow } officialPlayers { ...Player ...InfoRow } yearPills { year displaySeason } winner { id rank firstName lastName displayName shortName countryFlag country earnings totals { label value } } }}fragment TourCupSplitMeta on TourCupSplit { id title detailCopy projectedTitle projectedLive season description logo logoAsset { imagePath imageOrg } options tournamentPills { tournamentId displayName }}fragment Player on TourCupCombinedPlayer { __typename id firstName lastName displayName shortName countryFlag country rankingData { projected official event movement movementAmount logo logoDark } pointData { projected official event movement movementAmount logo logoDark } projectedSort officialSort thisWeekRank previousWeekRank columnData tourBound}fragment InfoRow on TourCupCombinedInfo { logo logoDark text sortValue toolTip}
```

### TourcastVideos

Shot-by-shot video clips for a player round

**Variables:**
```json
{
  "playerId": "39971",
  "tournamentId": "R2026475",
  "round": 1
}
```

**Query:**
```graphql
query TourcastVideos($tournamentId: ID!, $playerId: ID!, $round: Int!, $hole: Int, $shot: Int) { tourcastVideos( tournamentId: $tournamentId playerId: $playerId round: $round hole: $hole shot: $shot ) { ...VideoFragment }}fragment VideoFragment on Video { category categoryDisplayName created description descriptionNode { ... on NewsArticleText { __typename value } ... on NewsArticleLink { __typename segments { type value data id format { variants } imageOrientation imageDescription } } } duration franchise franchiseDisplayName holeNumber id playerVideos { firstName id lastName shortName } poster pubdate roundNumber shareUrl shotNumber startsAt endsAt thumbnailAsset { imageOrg imagePath } thumbnail title tournamentId tourCode year accountId gamAccountId videoAccountId seqHoleNumber sponsor { name description logoPrefix logo logoDark image websiteUrl gam } pinned contentTournamentId}
```

### Tournaments

Tournament metadata, weather, courses

**Variables:**
```json
{
  "ids": [
    "R2026475"
  ]
}
```

**Query:**
```graphql
query Tournaments($ids: [ID!]) { tournaments(ids: $ids) { ...TournamentFragment }}fragment TournamentFragment on Tournament { id tournamentName tournamentLogo tournamentLocation tournamentStatus roundStatusDisplay roundDisplay roundStatus roundStatusColor currentRound timezone pdfUrl seasonYear displayDate country state city scoredLevel howItWorks howItWorksPill howItWorksWebview events { id eventName leaderboardId } courses { id courseName courseCode hostCourse scoringLevel } weather { logo logoDark logoAccessibility tempF tempC condition windDirection windSpeedMPH windSpeedKPH precipitation humidity logoAsset { imageOrg imagePath } logoDarkAsset { imageOrg imagePath } } ticketsURL tournamentSiteURL formatType features conductedByLabel conductedByLink beautyImage hideRolexClock hideSov headshotBaseUrl rightRailConfig { imageUrl imageAltText buttonLink buttonText } shouldSubscribe ticketsEnabled useTournamentSiteURL beautyImageAsset { imageOrg imagePath } disabledScorecardTabs leaderboardTakeover tournamentCategoryInfo { type logoLight logoLightAsset { imageOrg imagePath } logoDark logoDarkAsset { imageOrg imagePath } label } tournamentLogoAsset { imageOrg imagePath }}
```

### Videos

Player video highlights

**Variables:**
```json
{
  "tourCode": "R",
  "playerIds": [
    "39971"
  ],
  "season": "2026",
  "tournamentId": "475",
  "franchises": [
    "competition#highlights",
    "competition#extended-highlights",
    "competition#interviews",
    "competition#shot-of-the-day",
    "competition#round-recaps"
  ],
  "limit": 18
}
```

**Query:**
```graphql
query Videos($tournamentId: String, $playerIds: [String!], $category: String, $franchise: String, $franchises: [String!], $tourCode: TourCode, $season: String, $limit: Int, $offset: Int, $holeNumber: String, $rating: Int) { videos( tournamentId: $tournamentId playerIds: $playerIds category: $category franchise: $franchise franchises: $franchises tourCode: $tourCode season: $season limit: $limit offset: $offset holeNumber: $holeNumber rating: $rating ) { ...VideoFragment }}fragment VideoFragment on Video { category categoryDisplayName created description descriptionNode { ... on NewsArticleText { __typename value } ... on NewsArticleLink { __typename segments { type value data id format { variants } imageOrientation imageDescription } } } duration franchise franchiseDisplayName holeNumber id playerVideos { firstName id lastName shortName } poster pubdate roundNumber shareUrl shotNumber startsAt endsAt thumbnailAsset { imageOrg imagePath } thumbnail title tournamentId tourCode year accountId gamAccountId videoAccountId seqHoleNumber sponsor { name description logoPrefix logo logoDark image websiteUrl gam } pinned contentTournamentId}
```

### oddsToWinCompressed

Odds to win for tournament field

**Variables:**
```json
{
  "tournamentId": "R2026475"
}
```

**Query:**
```graphql
query oddsToWinCompressed($tournamentId: ID!) { oddsToWinCompressed(oddsToWinId: $tournamentId) { id payload }}
```

### shotDetailsV4Compressed

Shot-level tracking data with coordinates

**Variables:**
```json
{
  "playerId": "39971",
  "tournamentId": "R2026475",
  "round": 1
}
```

**Query:**
```graphql
query shotDetailsV4Compressed($tournamentId: ID!, $playerId: ID!, $round: Int!, $includeRadar: Boolean) { shotDetailsV4Compressed( tournamentId: $tournamentId playerId: $playerId round: $round includeRadar: $includeRadar ) { id payload }}
```

---

## Stat ID Catalog

Used with `StatDetails` operation. Data available from **2004-2026**.

### Strokes Gained

#### Strokes Gained Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02675` | SG: Total |
| `02674` | SG: Tee-to-Green |
| `02567` | SG: Off-the-Tee |
| `02568` | SG: Approach the Green |
| `02569` | SG: Around-the-Green |
| `02564` | SG: Putting |

### Off The Tee

#### Driving Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02674` | SG: Tee-to-Green |
| `02567` | SG: Off-the-Tee |
| `129` | Total Driving |
| `101` | Driving Distance |
| `102` | Driving Accuracy Percentage |
| `02402` | Ball Speed |

#### Distance (All Drives)

| Stat ID | Stat Name |
|---------|-----------|
| `159` | Longest Drives |
| `101` | Driving Distance |
| `496` | Driving Pct. 320+ (Measured) |
| `495` | Driving Pct. 300-320 (Measured) |
| `454` | Driving Pct. 300+ (Measured) |
| `455` | Driving Pct. 280-300 (Measured) |
| `456` | Driving Pct. 260-280 (Measured) |
| `457` | Driving Pct. 240-260 (Measured) |
| `458` | Driving Pct. <= 240 (Measured) |
| `317` | Driving Distance - All Drives |
| `02433` | Driving Pct. 320+ (All Drives) |
| `02432` | Driving Pct. 300-320 (All Drives) |
| `214` | Driving Pct. 300+ (All Drives) |
| `215` | Driving Pct. 280-300 (All Drives) |
| `216` | Driving Pct. 260-280 (All Drives) |
| `217` | Driving Pct. 240-260 (All Drives) |
| `218` | Driving Pct. <= 240 (All Drives) |
| `02341` | Percentage of Yardage covered by Tee Shots |
| `02342` | Percentage of Yardage covered by Tee Shots - Par 4's |
| `02343` | Percentage of Yardage covered by Tee Shots - Par 5's |

#### Distance (Measured Drives)

| Stat ID | Stat Name |
|---------|-----------|
| `101` | Driving Distance |
| `496` | Driving Pct. 320+ (Measured) |
| `495` | Driving Pct. 300-320 (Measured) |
| `454` | Driving Pct. 300+ (Measured) |
| `455` | Driving Pct. 280-300 (Measured) |
| `456` | Driving Pct. 260-280 (Measured) |
| `457` | Driving Pct. 240-260 (Measured) |
| `458` | Driving Pct. <= 240 (Measured) |

#### Accuracy

| Stat ID | Stat Name |
|---------|-----------|
| `102` | Driving Accuracy Percentage |
| `02435` | Rough Tendency |
| `459` | Left Rough Tendency |
| `460` | Right Rough Tendency |
| `080` | Right Rough Tendency (RTP Score) |
| `081` | Left Rough Tendency (RTP Score) |
| `01008` | Fairway Bunker Tendency |
| `461` | Missed Fairway Percent - Other |
| `213` | Hit Fairway Percentage |
| `02420` | Distance from Edge of Fairway |
| `02421` | Distance from Center of Fairway |
| `02422` | Left Tendency |
| `02423` | Right Tendency |
| `02438` | Good Drive Percentage |

#### Radar

| Stat ID | Stat Name |
|---------|-----------|
| `02401` | Club Head Speed |
| `02402` | Ball Speed |
| `02403` | Smash Factor |
| `02404` | Launch Angle |
| `02405` | Spin Rate |
| `02406` | Distance to Apex |
| `02407` | Apex Height |
| `02408` | Hang Time |
| `02409` | Carry Distance |
| `02410` | Carry Efficiency |
| `02411` | Total Distance Efficiency |
| `02412` | Total Driving Efficiency |

#### Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `080` | Right Rough Tendency (RTP Score) |
| `081` | Left Rough Tendency (RTP Score) |

### Approach the Green

#### Approach Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02568` | SG: Approach the Green |
| `158` | Ball Striking |
| `103` | Greens in Regulation Percentage |
| `331` | Proximity to Hole |
| `02331` | Approaches from > 100 yards |
| `02329` | Approaches from inside 100 yards |

#### Greens in Regulation

| Stat ID | Stat Name |
|---------|-----------|
| `103` | Greens in Regulation Percentage |
| `02437` | Greens or Fringe in Regulation |
| `326` | GIR Percentage - 200+ yards |
| `327` | GIR Percentage - 175-200 yards |
| `328` | GIR Percentage - 150-175 yards |
| `329` | GIR Percentage - 125-150 yards |
| `330` | GIR Percentage - < 125 yards |
| `077` | GIR Percentage - 100-125 yards |
| `02332` | GIR Percentage - 100+ yards |
| `02330` | GIR Percentage - < 100 yards |
| `078` | GIR Percentage - 75-100 yards |
| `079` | GIR Percentage - < 75 yards |
| `190` | GIR Percentage from Fairway |
| `02434` | GIR Pct. - Fairway Bunker |
| `199` | GIR Percentage from Other than Fairway |

#### Accuracy from Fairway

| Stat ID | Stat Name |
|---------|-----------|
| `331` | Proximity to Hole |
| `02361` | Approaches from > 275 yards |
| `02360` | Approaches from 250-275 yards |
| `02359` | Approaches from 225-250 yards |
| `02358` | Approaches from 200-225 yards |
| `336` | Approaches from > 200 yards |
| `337` | Approaches from 175-200 yards |
| `338` | Approaches from 150-175 yards |
| `339` | Approaches from 125-150 yards |
| `340` | Approaches from 50-125 yards |
| `074` | Approaches from 100-125 yards |
| `075` | Approaches from 75-100 yards |
| `076` | Approaches from 50-75 yards |
| `02329` | Approaches from inside 100 yards |
| `02331` | Approaches from > 100 yards |
| `431` | Fairway Proximity |

#### Accuracy from Rough

| Stat ID | Stat Name |
|---------|-----------|
| `437` | Rough Proximity |
| `432` | Left Rough Proximity |
| `433` | Right Rough Proximity |
| `02375` | Approaches from > 275 yards (Rgh) |
| `02374` | Approaches from 250-275 yards (Rgh) |
| `02373` | Approaches from 225-250 yards (Rgh) |
| `02372` | Approaches from 200-225 yards (Rgh) |
| `02371` | Approaches from > 100 yards (Rgh) |
| `02370` | Approaches from inside 100 yards (Rgh) |
| `02369` | Approaches from > 200 yards (Rgh) |
| `02368` | Approaches from 175-200 yards (Rgh) |
| `02367` | Approaches from 150-175 yards (Rgh) |
| `02366` | Approaches from 125-150 yards (Rgh) |
| `02365` | Approaches from 50-125 yards (Rgh) |
| `02364` | Approaches from 100-125 yards (Rgh) |
| `02363` | Approaches from 75-100 yards (Rgh) |
| `02362` | Approaches from 50-75 yards (Rgh) |

#### Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `02333` | Birdie or Better Percentage - Fairway |
| `02334` | Birdie or Better Percentage - Left Rough |
| `02335` | Birdie or Better Percentage - Right Rough |
| `02336` | Birdie or Better Percentage - Rough |
| `357` | Birdie or Better Percentage - 200+ yards |
| `358` | Birdie or Better Percentage - 175-200 yards |
| `359` | Birdie or Better Percentage - 150-175 yards |
| `360` | Birdie or Better Percentage - 125-150 yards |
| `361` | Birdie or Better Percentage - < 125 yards |
| `02379` | Approach > 275 yards (RTP) |
| `02378` | Approach 250-275 yards (RTP) |
| `02377` | Approach 225-250 yards (RTP) |
| `02376` | Approach 200-225 yards (RTP) |
| `480` | Approach > 200 yards (RTP Score) |
| `479` | Approach 175-200 yards (RTP Score) |
| `478` | Approach 150-175 yards (RTP Score) |
| `473` | Approach 125-150 yards (RTP Score) |
| `472` | Approach < 125 yards (RTP Score) |
| `028` | Approach 100-125 yards (RTP Score) |
| `029` | Approach 75-100 yards (RTP Score) |
| `030` | Approach 50-75 yards (RTP Score) |
| `02380` | Approaches 50-75 yards-Rgh (RTP) |
| `02381` | Approaches 75-100 yards-Rgh (RTP) |
| `02382` | Approaches 100-125 yards-Rgh (RTP) |
| `02383` | Approaches 50-125 yards-Rgh (RTP) |
| `02384` | Approaches 125-150 yards-Rgh (RTP) |
| `02385` | Approaches 150-175 yards-Rgh (RTP) |
| `02386` | Approaches 175-200 yards-Rgh (RTP) |
| `02387` | Approaches > 200 yards-Rgh (RTP) |
| `02388` | Approaches < 100 yards-Rgh (RTP) |
| `02389` | Approaches > 100 yards-Rgh (RTP) |
| `02390` | Approaches 200-225 yards-Rgh (RTP) |
| `02391` | Approaches 225-250 yards-Rgh (RTP) |
| `02392` | Approaches 250-275 yards-Rgh (RTP) |
| `02393` | Approaches > 275 yards-Rgh (RTP) |
| `469` | Approaches Left Rough (RTP Score) |
| `470` | Approaches Right Rough (RTP Score) |
| `471` | Fairway Approach (RTP Score) |

#### Going for it

| Stat ID | Stat Name |
|---------|-----------|
| `419` | Going for the Green |
| `486` | Going for the Green - Hit Green Pct. |
| `02357` | Going for the Green - Birdie or Better |
| `436` | Par 5 Going for the Green |
| `02426` | Average Going for it Shot Distance (in Yards) |
| `02431` | Average Distance after Going for it Shot |

#### Holeouts, Other

| Stat ID | Stat Name |
|---------|-----------|
| `350` | Total Hole Outs |
| `351` | Longest Hole Outs (in yards) |
| `02325` | Average Approach Shot Distance |
| `02338` | Average Approach Distance - Birdie or Better |
| `02339` | Average Approach Distance - Par |
| `02340` | Average Approach Distance - Bogey or Worse |
| `02430` | Average Distance to Hole After Tee Shot |

### Around the Green

#### Short Game Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02569` | SG: Around-the-Green |
| `130` | Scrambling |
| `374` | Proximity to Hole (ARG) |
| `111` | Sand Save Percentage |
| `363` | Scrambling from Rough |
| `366` | Scrambling from > 30 yards |

#### Up and Down

| Stat ID | Stat Name |
|---------|-----------|
| `130` | Scrambling |
| `362` | Scrambling from the Sand |
| `363` | Scrambling from the Rough |
| `364` | Scrambling from the Fringe |
| `365` | Scrambling from Other Locations |
| `366` | Scrambling from > 30 yards |
| `367` | Scrambling from 20-30 yards |
| `368` | Scrambling from 10-20 yards |
| `369` | Scrambling from < 10 yards |
| `111` | Sand Save Percentage |
| `370` | Sand Saves from 30+ yards |
| `371` | Sand Saves from 20-30 yards |
| `372` | Sand Saves from 10-20 yards |
| `373` | Sand Saves from < 10 yards |

#### Accuracy

| Stat ID | Stat Name |
|---------|-----------|
| `374` | Proximity to Hole (ARG) |
| `375` | Proximity to Hole from Sand |
| `377` | Proximity to Hole from Fringe |
| `376` | Proximity to Hole from Rough |
| `378` | Proximity to Hole from Other Locations |
| `379` | Proximity to Hole from 30+ yards |
| `380` | Proximity to Hole from 20-30 yards |
| `381` | Proximity to Hole from 10-20 yards |
| `382` | Proximity to Hole from < 10 yards |
| `481` | Scrambling Average Distance to Hole |

#### Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `466` | Scrambling > 30 yds (RTP Score) |
| `467` | Scrambling 20-30 yds (RTP Score) |
| `468` | Scrambling 10-20 yds (RTP Score) |
| `465` | Scrambling Fringe (RTP Score) |
| `464` | Scrambling Rough (RTP Score) |

### Putting

#### Putting Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02564` | SG: Putting |
| `104` | Putting Average |
| `119` | Putts Per Round |
| `413` | One-Putt Percentage |
| `426` | 3-Putt Avoidance |
| `484` | Putting Inside 10’ |

#### Putting Averages

| Stat ID | Stat Name |
|---------|-----------|
| `02428` | Total Putting |
| `02439` | Bonus Putting |
| `104` | Putting Average |
| `402` | Overall Putting Average |
| `115` | Birdie or Better Conversion Percentage |

#### Putts per Round

| Stat ID | Stat Name |
|---------|-----------|
| `119` | Putts Per Round |
| `393` | Putts per Round - Round 1 |
| `394` | Putts per Round - Round 2 |
| `395` | Putts per Round - Round 3 |
| `396` | Putts per Round - Round 4 |
| `397` | Putts per Round - Round 5 |
| `398` | 1-Putts per Round |
| `399` | 2-Putts per Round |
| `400` | 3-Putts per Round |
| `401` | 3+ Putts per Round |

#### One-Putts

| Stat ID | Stat Name |
|---------|-----------|
| `413` | One-Putt Percentage |
| `414` | One-Putt Percentage - Round 1 |
| `415` | One-Putt Percentage - Round 2 |
| `416` | One-Putt Percentage - Round 3 |
| `417` | One-Putt Percentage - Round 4 |
| `418` | One-Putt Percentage - Round 5 |
| `420` | Total 1 Putts - Inside 5' |
| `421` | Total 1 Putts - 5-10' |
| `422` | Total 1 Putts - 10-15' |
| `423` | Total 1 Putts - 15-20' |
| `424` | Total 1 Putts - 20-25' |
| `425` | Total 1 Putts - > 25' |
| `398` | 1-Putts per Round |
| `498` | Longest Putts |

#### Three-Putts

| Stat ID | Stat Name |
|---------|-----------|
| `426` | 3-Putt Avoidance |
| `427` | 3-Putt Avoidance - Round 1 |
| `428` | 3-Putt Avoidance - Round 2 |
| `429` | 3-Putt Avoidance - Round 3 |
| `430` | 3-Putt Avoidance - Round 4 |
| `440` | 3-Putt Avoidance - Round 5 |
| `068` | 3-Putt Avoidance - Inside 5' |
| `069` | 3-Putt Avoidance - 5-10' |
| `070` | 3-Putt Avoidance - 10-15' |
| `145` | 3-Putt Avoidance - 15-20' |
| `146` | 3-Putt Avoidance - 20-25' |
| `147` | 3-Putt Avoidance > 25' |
| `441` | Total 3 Putts - Inside 5' |
| `442` | Total 3 Putts - 5-10' |
| `443` | Total 3 Putts - 10-15' |
| `444` | Total 3 Putts - 15-20' |
| `445` | Total 3 Putts - 20-25' |
| `446` | Total 3 Putts - > 25' |
| `400` | 3-Putts per Round |
| `401` | 3+ Putts per Round |

#### All Putts Made by Dist.

| Stat ID | Stat Name |
|---------|-----------|
| `408` | Putting from - > 25' |
| `02429` | Putting from - > 20' |
| `02328` | Putting from 15-25' |
| `407` | Putting from - 20-25' |
| `406` | Putting from - 15-20' |
| `02327` | Putting from 5-15' |
| `405` | Putting from - 10-15' |
| `484` | Putting - Inside 10' |
| `404` | Putting from 5-10' |
| `02427` | Putting from 3-5' |
| `403` | Putting from Inside 5' |
| `348` | Putting from 10' |
| `347` | Putting from 9' |
| `346` | Putting from 8' |
| `345` | Putting from 7' |
| `344` | Putting from 6' |
| `343` | Putting from 5' |
| `356` | Putting from - > 10' |
| `485` | Putting from 4-8' |
| `342` | Putting from 4' |
| `341` | Putting from 3' |
| `434` | Putts Made Per Event Over 10' |
| `435` | Putts Made Per Event Over 20' |

#### Avg. Putting Dist.

| Stat ID | Stat Name |
|---------|-----------|
| `438` | Average Distance of Putts made |
| `02440` | Average Distance of Birdie putts made |
| `02442` | Average Distance of Eagle putts made |
| `135` | Putts made Distance |
| `349` | Approach Putt Performance |
| `409` | Average Putting Distance - All 1 putts |
| `410` | Average Putting Distance - All 2 putts |
| `411` | Average Putting Distance - All 3 putts |
| `412` | Average Putting Distance - All 3+ putts |
| `389` | Average Putting Distance - GIR 1 Putts |
| `390` | Average Putting Distance - GIR 2 Putts |
| `391` | Average Putting Distance - GIR 3 Putts |
| `392` | Average Putting Distance - GIR 3+ Putts |

#### GIR Putts Made by Dist.

| Stat ID | Stat Name |
|---------|-----------|
| `073` | GIR Putting Avg - > 35' |
| `072` | GIR Putting Avg - 30-35' |
| `071` | GIR Putting Avg - 25-30' |
| `388` | GIR Putting - > 25' |
| `387` | GIR Putting - 20-25' |
| `386` | GIR Putting - 15-20' |
| `385` | GIR Putting - 10-15' |
| `384` | GIR Putting - 5-10' |
| `383` | GIR Putting - Inside 5' |

### Scoring

#### Scoring Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `02675` | SG: Total |
| `120` | Scoring Average (Adjusted) |
| `156` | Birdie Average |
| `352` | Birdie or Better Percentage |
| `02414` | Bogey Avoidance |
| `142` | Par 3 Scoring Average |
| `143` | Par 4 Scoring Average |
| `144` | Par 5 Scoring Average |

#### Scoring Overall

| Stat ID | Stat Name |
|---------|-----------|
| `120` | Scoring Average (Adjusted) |
| `108` | Scoring Average (Actual) |
| `116` | Scoring Average Before Cut |
| `02417` | Stroke Differential Field Average |
| `299` | Lowest Round |
| `152` | Rounds in the 60s |
| `153` | Sub-Par Rounds |

#### Under Par Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `156` | Birdie Average |
| `107` | Total Birdies |
| `155` | Eagles (Holes per) |
| `106` | Total Eagles |
| `105` | Par Breakers |
| `160` | Bounce Back |
| `02415` | Birdie to Bogey Ratio |
| `112` | Par 3 Birdie or Better Leaders |
| `113` | Par 4 Birdie or Better Leaders |
| `114` | Par 5 Birdie or Better Leaders |
| `447` | Par 4 Eagle Leaders |
| `448` | Par 5 Eagle Leaders |
| `352` | Birdie or Better Percentage |
| `357` | Birdie or Better Percentage - 200+ yards |
| `358` | Birdie or Better Percentage - 175-200 yards |
| `359` | Birdie or Better Percentage - 150-175 yards |
| `360` | Birdie or Better Percentage - 125-150 yards |
| `361` | Birdie or Better Percentage - < 125 yards |
| `02333` | Birdie or Better Percentage - Fairway |
| `02334` | Birdie or Better Percentage - Left Rough |
| `02335` | Birdie or Better Percentage - Right Rough |
| `02336` | Birdie or Better Percentage - Rough |

#### Over Par Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `02414` | Bogey Avoidance |
| `02415` | Birdie to Bogey Ratio |
| `02416` | Reverse Bounce Back |
| `02419` | Bogey Average |

#### Scoring by Round

| Stat ID | Stat Name |
|---------|-----------|
| `118` | Final Round Scoring Average |
| `219` | Final Round Performance |
| `220` | Top 10 Final Round Performance |
| `309` | Top 5 Final Round Performance |
| `310` | 11-25 Final Round Performance |
| `311` | 25+ Final Round Performance |
| `453` | 6-10 Final Round Performance |
| `148` | Round 1 Scoring Average |
| `149` | Round 2 Scoring Average |
| `117` | Round 3 Scoring Average |
| `285` | Round 4 Scoring Average |
| `286` | Round 5 Scoring Average |
| `245` | Front 9 Round 1 Scoring Average |
| `246` | Back 9 Round 1 Scoring Average |
| `253` | Front 9 Round 2 Scoring Average |
| `254` | Back 9 Round 2 Scoring Average |
| `261` | Front 9 Round 3 Scoring Average |
| `269` | Front 9 Round 4 Scoring Average |
| `277` | Front 9 Round 5 Scoring Average |

#### Par 3,4,5 Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `171` | Par 3 Performance |
| `142` | Par 3 Scoring Average |
| `112` | Par 3 Birdie or Better Leaders |
| `172` | Par 4 Performance |
| `143` | Par 4 Scoring Average |
| `113` | Par 4 Birdie or Better Leaders |
| `173` | Par 5 Performance |
| `144` | Par 5 Scoring Average |
| `448` | Par 5 Eagle Leaders |
| `114` | Par 5 Birdie or Better Leaders |
| `223` | Early Par 3 Scoring Average |
| `231` | Early Par 4 Scoring Average |
| `239` | Early Par 5 Scoring Average |
| `224` | Late Par 3 Scoring Average |
| `232` | Late Par 4 Scoring Average |
| `240` | Late Par 5 Scoring Average |

#### Efficiency Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `02517` | Par 3 efficiency < 100 yards |
| `02518` | Par 3 efficiency 100-125 yards |
| `02519` | Par 3 efficiency 125-150 yards |
| `02520` | Par 3 efficiency 150-175 yards |
| `02521` | Par 3 efficiency 175-200 yards |
| `02522` | Par 3 efficiency 200-225 yards |
| `02523` | Par 3 efficiency 225-250 yards |
| `02524` | Par 3 efficiency >250 yards |
| `02525` | Par 4 efficiency < 250 Yards |
| `02526` | Par 4 efficiency 250-300 yards |
| `02527` | Par 4 Efficiency 300-350 yards |
| `02528` | Par 4 Efficiency 350-400 yards |
| `02529` | Par 4 Efficiency 400-450 yards |
| `02530` | Par 4 Efficiency 450-500 yards |
| `02531` | Par 4 Efficiency >500 yards |
| `02532` | Par 5 Efficiency <500 yards |
| `02533` | Par 5 Efficiency 500-550 Yards |
| `02534` | Par 5 Efficiency 550-600 Yards |
| `02535` | Par 5 Efficiency 600-650 Yards |
| `02536` | Par 5 Efficiency >650 Yards |

#### Front 9 Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `207` | Front 9 Scoring Average |
| `301` | Front 9 Lowest Round |
| `221` | Front 9 Par 3 Scoring Average |
| `229` | Front 9 Par 4 Scoring Average |
| `237` | Front 9 Par 5 Scoring Average |
| `245` | Front 9 Round 1 Scoring Average |
| `253` | Front 9 Round 2 Scoring Average |
| `261` | Front 9 Round 3 Scoring Average |
| `269` | Front 9 Round 4 Scoring Average |
| `277` | Front 9 Round 5 Scoring Average |

#### Back 9 Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `208` | Back 9 Scoring Average |
| `302` | Back 9 Lowest Round |
| `222` | Back 9 Par 3 Scoring Average |
| `230` | Back 9 Par 4 Scoring Average |
| `238` | Back 9 Par 5 Scoring Average |
| `246` | Back 9 Round 1 Scoring Average |
| `254` | Back 9 Round 2 Scoring Average |
| `262` | Back 9 Round 3 Scoring Average |
| `270` | Back 9 Round 4 Scoring Average |
| `278` | Back 9 Round 5 Scoring Average |

#### Early Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `292` | Early Scoring Average |
| `303` | Early Lowest Round |
| `209` | First Tee Early Scoring Average |
| `210` | Tenth Tee Early Scoring Average |
| `223` | Early Par 3 Scoring Average |
| `231` | Early Par 4 Scoring Average |
| `239` | Early Par 5 Scoring Average |
| `247` | Early Round 1 Scoring Average |
| `255` | Early Round 2 Scoring Average |
| `263` | Early Round 3 Scoring Average |
| `271` | Early Round 4 Scoring Average |
| `279` | Early Round 5 Scoring Average |
| `225` | First Tee Early Par 3 Scoring Average |
| `226` | Tenth Tee Early Par 3 Scoring Average |
| `233` | First Tee Early Par 4 Scoring Average |
| `234` | Tenth Tee Early Par 4 Scoring Average |
| `241` | First Tee Early Par 5 Scoring Average |
| `242` | Tenth Tee Early Par 5 Scoring Average |
| `249` | First Tee Early Round 1 Scoring Average |
| `250` | Tenth Tee Early Round 1 Scoring Average |
| `257` | First Tee Early Round 2 Scoring Average |
| `258` | Tenth Tee Early Round 2 Scoring Average |
| `265` | First Tee Early Round 3 Scoring Average |
| `266` | Tenth Tee Early Round 3 Scoring Average |
| `273` | First Tee Early Round 4 Scoring Average |
| `274` | Tenth Tee Early Round 4 Scoring Average |
| `281` | First Tee Early Round 5 Scoring Average |
| `282` | Tenth Tee Early Round 5 Scoring Average |
| `305` | First Tee Early Lowest Round |
| `306` | Tenth Tee Early Lowest Round |

#### Late Scoring

| Stat ID | Stat Name |
|---------|-----------|
| `293` | Late Scoring Average |
| `304` | Late Lowest Round |
| `224` | Late Par 3 Scoring Average |
| `232` | Late Par 4 Scoring Average |
| `240` | Late Par 5 Scoring Average |
| `248` | Late Round 1 Scoring Average |
| `256` | Late Round 2 Scoring Average |
| `264` | Late Round 3 Scoring Average |
| `272` | Late Round 4 Scoring Average |
| `280` | Late Round 5 Scoring Average |
| `211` | First Tee Late Scoring Average |
| `212` | Tenth Tee Late Scoring Average |
| `227` | First Tee Late Par 3 Scoring Average |
| `228` | Tenth Tee Late Par 3 Scoring Average |
| `235` | First Tee Late Par 4 Scoring Average |
| `236` | Tenth Tee Late Par 4 Scoring Average |
| `243` | First Tee Late Par 5 Scoring Average |
| `244` | Tenth Tee Late Par 5 Scoring Average |
| `251` | First Tee Late Round 1 Scoring Average |
| `252` | Tenth Tee Late Round 1 Scoring Average |
| `259` | First Tee Late Round 2 Scoring Average |
| `260` | Tenth Tee Late Round 2 Scoring Average |
| `267` | First Tee Late Round 3 Scoring Average |
| `268` | Tenth Tee Late Round 3 Scoring Average |
| `275` | First Tee Late Round 4 Scoring Average |
| `276` | Tenth Tee Late Round 4 Scoring Average |
| `283` | First Tee Late Round 5 Scoring Average |
| `284` | Tenth Tee Late Round 5 Scoring Average |
| `307` | First Tee Late Lowest Round |
| `308` | Tenth Tee Late Lowest Round |

#### Scoring Off the 1st Tee

| Stat ID | Stat Name |
|---------|-----------|
| `209` | First Tee Early Scoring Average |
| `211` | First Tee Late Scoring Average |
| `225` | First Tee Early Par 3 Scoring Average |
| `227` | First Tee Late Par 3 Scoring Average |
| `233` | First Tee Early Par 4 Scoring Average |
| `235` | First Tee Late Par 4 Scoring Average |
| `241` | First Tee Early Par 5 Scoring Average |
| `243` | First Tee Late Par 5 Scoring Average |
| `249` | First Tee Early Round 1 Scoring Average |
| `251` | First Tee Late Round 1 Scoring Average |
| `257` | First Tee Early Round 2 Scoring Average |
| `259` | First Tee Late Round 2 Scoring Average |
| `265` | First Tee Early Round 3 Scoring Average |
| `267` | First Tee Late Round 3 Scoring Average |
| `273` | First Tee Early Round 4 Scoring Average |
| `275` | First Tee Late Round 4 Scoring Average |
| `281` | First Tee Early Round 5 Scoring Average |
| `283` | First Tee Late Round 5 Scoring Average |
| `305` | First Tee Early Lowest Round |
| `307` | First Tee Late Lowest Round |

#### Scoring Off the 10th Tee

| Stat ID | Stat Name |
|---------|-----------|
| `210` | Tenth Tee Early Scoring Average |
| `212` | Tenth Tee Late Scoring Average |
| `226` | Tenth Tee Early Par 3 Scoring Average |
| `228` | Tenth Tee Late Par 3 Scoring Average |
| `234` | Tenth Tee Early Par 4 Scoring Average |
| `236` | Tenth Tee Late Par 4 Scoring Average |
| `242` | Tenth Tee Early Par 5 Scoring Average |
| `244` | Tenth Tee Late Par 5 Scoring Average |
| `250` | Tenth Tee Early Round 1 Scoring Average |
| `252` | Tenth Tee Late Round 1 Scoring Average |
| `258` | Tenth Tee Early Round 2 Scoring Average |
| `260` | Tenth Tee Late Round 2 Scoring Average |
| `266` | Tenth Tee Early Round 3 Scoring Average |
| `268` | Tenth Tee Late Round 3 Scoring Average |
| `274` | Tenth Tee Early Round 4 Scoring Average |
| `276` | Tenth Tee Late Round 4 Scoring Average |
| `282` | Tenth Tee Early Round 5 Scoring Average |
| `284` | Tenth Tee Late Round 5 Scoring Average |
| `306` | Tenth Tee Early Lowest Round |
| `308` | Tenth Tee Late Lowest Round |

### Streaks

#### Streaks Leaders

| Stat ID | Stat Name |
|---------|-----------|
| `122` | Consecutive Cuts |
| `297` | Consecutive Fairways Hit |
| `298` | Consecutive GIR  |
| `02672` | Consecutive Birdies Streak |
| `483` | Holes without 3-Putt |
| `475` | YTD Rounds in the 60s Streak |

#### Other Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `122` | Consecutive Cuts |
| `137` | YTD Consecutive Cuts |
| `483` | Current Streak without a 3-Putt |

#### Off the Tee Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `297` | Consecutive Fairways Hit |

#### Approach the Green Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `298` | Consecutive GIR |

#### Around the Green Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `296` | Consecutive Sand Saves |

#### Putting Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `295` | Best YTD 1-Putt or Better Streak |
| `483` | Current Streak without a 3-Putt |
| `294` | Best YTD Streak w/o a 3-Putt |

#### Scoring Streaks

| Stat ID | Stat Name |
|---------|-----------|
| `474` | Best Rounds in 60's Streak |
| `475` | YTD Rounds in 60's Streak |
| `476` | Best Sub-Par Rounds Streak |
| `477` | YTD Sub-Par Rounds Streak |
| `150` | Current Par or Better Streak |
| `482` | YTD Par or Better Streak |
| `449` | Consecutive Par 3 Birdies |
| `450` | Consecutive Par 4 Birdies |
| `451` | Consecutive Par 5 Birdies |
| `452` | Consecutive Holes Below Par |
| `02672` | Consecutive Birdies Streak |
| `02673` | Consecutive Birdies/Eagles streak |

### Money/Finishes

#### Money

| Stat ID | Stat Name |
|---------|-----------|
| `109` | Official Money |
| `110` | Career Money Leaders |
| `014` | Career Earnings |
| `139` | Non-member Earnings |
| `02677` | Non-Member Off+WGC Earnings |
| `02444` | Money Leaders - Fall Series |
| `02396` | FedExCup Bonus Money |
| `154` | Money per Event Leaders |
| `194` | Total Money (Official and Unofficial) |
| `02337` | Percentage of Available Purse Won |
| `02447` | Percentage of potential money won |

#### Finishes

| Stat ID | Stat Name |
|---------|-----------|
| `138` | Top 10 Finishes |
| `300` | Victory Leaders |

### Points/Rankings

#### Points

| Stat ID | Stat Name |
|---------|-----------|
| `02671` | FedExCup Standings |
| `02698` | FedExCup Fall Points |
| `02562` | FedExCup Points per Event Leaders |
| `02448` | % of Potential Pts won - FedExCup Regular Season |
| `02398` | FedExCup Season Points for Non-Members |
| `131` | Ryder Cup Points |
| `140` | Presidents Cup Points (United States) |
| `187` | Presidents Cup Points (International) |
| `02667` | Non-WGC FedExCup Season Points for Non-Members |
| `132` | PGA Championship Points |

#### Rankings

| Stat ID | Stat Name |
|---------|-----------|
| `127` | All-Around Ranking |
| `02685` | FedEx Air & Ground ® |
| `02689` | FedEx Ground Top Performer ® |
| `186` | Official World Golf Ranking |
| `085` | Power Rating |
| `086` | Accuracy Rating |
| `087` | Short Game Rating |
| `088` | Putting Rating |
| `02346` | Scoring Rating |
| `02347` | Last 5 Events - Power |
| `02348` | Last 5 Events - Accuracy |
| `02349` | Last 5 Events - Short Game |
| `02350` | Last 5 Events - Putting |
| `02351` | Last 5 Events - Scoring |
| `02352` | Last 15 Events - Power |
| `02353` | Last 15 Events - Accuracy |
| `02354` | Last 15 Events - Short Game |
| `02355` | Last 15 Events - Putting |
| `02356` | Last 15 Events - Scoring |

---

## Player List Schema

From `GET https://data-api.pgatour.com/player/list/R`

```json
{
  "id": "39971",
  "tourCode": "R",
  "isPrimary": true,
  "isActive": true,
  "firstName": "Sungjae",
  "lastName": "Im",
  "shortName": "S Im",
  "alphaSort": "I",
  "country": "South Korea",
  "countryFlag": "KOR",
  "playerBio": {
    "age": "27",
    "id": "39971"
  },
  "primaryTour": "R",
  "displayName": "Sungjae Im"
}
```

## Leaderboard Response Schema (Decompressed)

```json
{
  "__typename": "LeaderboardV3",
  "id": "R2026475",
  "timezone": "America/New_York",
  "tournamentId": "R2026475",
  "formatType": "STROKE_PLAY",
  "players": [
    {
      "__typename": "PlayerRowV3",
      "id": "39971",
      "player": {
        "id": "39971",
        "firstName": "Sungjae",
        "lastName": "Im",
        "displayName": "Sungjae Im",
        "country": "KOR"
      },
      "scoringData": {
        "position": "1",
        "total": "-7",
        "totalSort": -7,
        "thru": "F*",
        "score": "-7",
        "scoreSort": -7,
        "currentRound": 1,
        "rounds": [
          "64",
          "-",
          "-",
          "-"
        ],
        "playerState": "COMPLETE"
      }
    }
  ],
  "courses": [
    "..."
  ],
  "rounds": [
    "..."
  ]
}
```

## Shot Details Response Schema (Decompressed)

```json
{
  "__typename": "ShotDetailsV4",
  "tournamentId": "R2026475",
  "playerId": "39971",
  "round": 1,
  "holes": [
    {
      "holeNumber": 10,
      "par": 4,
      "yardage": 437,
      "status": "BIRDIE",
      "score": "3",
      "green": true,
      "rank": "14",
      "fairwayCenter": {
        "x": 0.555,
        "y": 0.503,
        "tourcastX": 10799.05,
        "tourcastY": 9541.43,
        "tourcastZ": 6.6
      },
      "shots": [
        "... per-shot coordinate data"
      ]
    }
  ]
}
```
