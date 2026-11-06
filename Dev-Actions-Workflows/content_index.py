#!/usr/bin/env python3
"""Offline keyword matching and PostgreSQL-compatible CSV staging from permitted content JSONL."""
import argparse
import csv
import hashlib
import json
import re
from pathlib import Path

def mentions(text: str, aliases: dict) -> list[dict]:
    """Case-insensitive whole phrase search. Ambiguous matches remain pending review."""
    matches = []
    for category in ("player", "event", "course"):
        for entity in aliases.get(category + "s", []):
            for alias in entity.get("aliases", []):
                if alias and re.search(r"(?<!\w)" + re.escape(alias) + r"(?!\w)", text, re.I):
                    matches.append({"entity_type": category, "entity_id": entity["id"],
                                    "matched_text": alias, "review_status": "pending"})
    return matches

def build(source: Path, alias_file: Path, output: Path) -> tuple[int, int]:
    aliases = json.loads(alias_file.read_text(encoding="utf-8"))
    output.parent.mkdir(parents=True, exist_ok=True)
    rows, matches, seen = [], [], set()
    with source.open(encoding="utf-8") as fp:
        for line_no, line in enumerate(fp, 1):
            if not line.strip():
                continue
            try:
                item = json.loads(line)
                url = item["url"]
                if not url.startswith("https://"):
                    raise ValueError("https URL required")
                if url in seen:
                    continue
                seen.add(url)
                title, body = item["title"], item.get("text", "")
                stable_id = hashlib.sha256(url.encode()).hexdigest()
                rows.append({"source_id": item.get("source_id", stable_id), "title": title,
                             "url": url, "published_at": item.get("published_at", ""),
                             "content_type": item.get("type", "article"), "text": body,
                             "sha256": hashlib.sha256((title + body).encode()).hexdigest()})
                matches.extend({"content_url": url, **m} for m in mentions(title + " " + body, aliases))
            except (KeyError, ValueError, TypeError) as exc:
                raise ValueError(f"Invalid JSONL item at line {line_no}: {exc}") from exc
    for path, entries, fields in [
        (output / "content_items.csv", rows,
         ["source_id", "title", "url", "published_at", "content_type", "text", "sha256"]),
        (output / "content_mentions.csv", matches,
         ["content_url", "entity_type", "entity_id", "matched_text", "review_status"])
    ]:
        with path.open("w", newline="", encoding="utf-8") as fp:
            writer = csv.DictWriter(fp, fieldnames=fields)
            writer.writeheader()
            writer.writerows(entries)
    return len(rows), len(matches)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--aliases", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        print("Items, mentions:", *build(args.input, args.aliases, args.out))
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        parser.exit(1, f"Index error: {exc}\n")

if __name__ == "__main__":
    main()
