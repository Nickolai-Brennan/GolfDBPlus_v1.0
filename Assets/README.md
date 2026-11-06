# GolfDB+ Assets Layout

Keep pre-existing Assets intact. Use one **entity slug + permanent ID** per folder to avoid renamed events/players breaking paths. Store high-volume or licensed files in a private object store; `Assets` is a logical organization path and development staging convention.

```text
Assets/
  Events/<seasonID>/<event-slug>--<eventsID>/
    Documents/pgatourmedia/{tee-times,hole-locations,notes,field,scorecard,agronomy,shotlink,weather,other}/
    Documents/shotlink-reports/{round-summaries,tee-times,other}/
    Transcripts/script_markdown.md
    Transcripts/original/
    Logos/
    manifest.json
  Players/<player-slug>--<playerid>/{Headshots,Action-Shots,Equipment,Transcripts}/
  Courses/<course-slug>--<coursesID>/{Brand,Holes-2D,Greens,3D-Maps,Live,Documents}/
```

Production document paths may instead be object-store URIs. Each file belongs in a metadata manifest with original source URL, download timestamp, hash, size, permissions and classification. Avoid committing downloaded PGA TOUR PDFs/transcripts to this public repo without permission.
