#!/usr/bin/env python3
"""Discover accessible PGA event documents and record provenance; optional authorized downloads."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen
from html.parser import HTMLParser

MAX_BYTES = 40 * 1024 * 1024
ALLOWED_HOSTS = {"pgatourmedia.pgatourhq.com", "tee-scripts.com"}
EXTENSIONS = (".pdf", ".csv", ".xlsx", ".xls", ".doc", ".docx", ".txt")

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.in_anchor = False
        self.href = ""
        self.label = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "a":
            self.in_anchor = True
            self.href = dict(attrs).get("href", "")
            self.label = []

    def handle_data(self, value):
        if self.in_anchor:
            self.label.append(value)

    def handle_endtag(self, tag):
        if tag.lower() == "a" and self.in_anchor:
            self.links.append((self.href, " ".join("".join(self.label).split())))
            self.in_anchor = False

def fetch(url: str, timeout: int = 20) -> tuple[bytes, str]:
    """Fetch with size ceiling, network timeout and unambiguous failure."""
    request = Request(url, headers={"User-Agent": "GolfDBPlusResearch/0.1 (+manual authorized collection)"})
    with urlopen(request, timeout=timeout) as response:
        final = response.geturl()
        if urlparse(final).hostname not in ALLOWED_HOSTS:
            raise ValueError(f"Unapproved redirect host: {final}")
        length = int(response.headers.get("Content-Length", "0"))
        if length > MAX_BYTES:
            raise ValueError("File exceeds maximum allowed bytes")
        content = response.read(MAX_BYTES + 1)
        if len(content) > MAX_BYTES:
            raise ValueError("Response exceeds maximum allowed bytes")
        return content, response.headers.get("Content-Type", "").split(";")[0]

def discover(html: str, base_url: str) -> list[dict]:
    parser = LinkParser()
    parser.feed(html)
    output = []
    seen = set()
    for href, title in parser.links:
        url = urljoin(base_url, href)
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname not in ALLOWED_HOSTS or url in seen:
            continue
        seen.add(url)
        output.append({"title": title or Path(parsed.path).name, "original_url": url,
                       "document_type": Path(parsed.path).suffix.lower().lstrip(".") or "html",
                       "is_attachment": parsed.path.lower().endswith(EXTENSIONS)})
    return output

def safe_file_name(url: str) -> str:
    """Use source path plus a stable URL hash to avoid collisions/traversal."""
    name = Path(urlparse(url).path).name
    name = re.sub(r"[^a-zA-Z0-9._-]", "_", name).strip(".") or "document"
    return f"{hashlib.sha256(url.encode()).hexdigest()[:12]}-{name}"

def collect(url: str, output: Path, download: bool, transcript_url: str | None) -> dict:
    if urlparse(url).scheme != "https" or urlparse(url).hostname not in ALLOWED_HOSTS:
        raise ValueError("Source must be an approved HTTPS host")
    html, _ = fetch(url)
    links = discover(html.decode("utf-8", errors="replace"), url)
    timestamp = datetime.now(timezone.utc).isoformat()
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for item in links:
        record = {**item, "source_system": "pgatourmedia", "discovered_at": timestamp,
                  "access_status": "discovered"}
        if download and item["is_attachment"]:
            # Confirm terms and permissions before setting --download.
            try:
                payload, content_type = fetch(item["original_url"])
                folder = output / "Documents" / "pgatourmedia"
                folder.mkdir(parents=True, exist_ok=True)
                target = folder / safe_file_name(item["original_url"])
                target.write_bytes(payload)
                record.update(access_status="downloaded", stored_path=str(target),
                              sha256=hashlib.sha256(payload).hexdigest(),
                              bytes=len(payload), mime_type=content_type, retrieved_at=timestamp)
            except Exception as exc:
                record.update(access_status="failed", error=str(exc))
        records.append(record)
        time.sleep(0.05)
    transcript_links = []
    if transcript_url:
        if urlparse(transcript_url).hostname not in ALLOWED_HOSTS:
            raise ValueError("Transcript host must be approved")
        try:
            text, _ = fetch(transcript_url)
            transcript_links = discover(text.decode("utf-8", errors="replace"), transcript_url)
        except Exception as exc:
            transcript_links = [{"error": str(exc), "original_url": transcript_url}]
    trans = output / "Transcripts"
    trans.mkdir(exist_ok=True)
    lines = ["# Event transcript URL inventory", "", f"Source event: {url}", f"Discovered: {timestamp}", ""]
    for entry in transcript_links:
        if entry.get("error"):
            lines.append(f"- Collection error: {entry['error']}")
        else:
            lines.append(f"- [{entry['title'].replace(']', '')}]({entry['original_url']})")
    (trans / "script_markdown.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    manifest = {"event_url": url, "discovered_at": timestamp,
                "documents": records, "transcript_links": transcript_links}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Official PGA TOUR Media event page")
    parser.add_argument("--out", required=True, type=Path, help="Local PRIVATE storage path")
    parser.add_argument("--transcript-url", help="Permitted transcript landing page")
    parser.add_argument("--download", action="store_true",
                        help="Download permitted linked attachments (default: discovery only)")
    args = parser.parse_args()
    try:
        result = collect(args.url, args.out, args.download, args.transcript_url)
        print(json.dumps({"discovered": len(result["documents"]),
                          "downloaded": sum(x["access_status"] == "downloaded" for x in result["documents"]) }))
    except (OSError, ValueError) as exc:
        parser.exit(1, f"Collector error: {exc}\n")

if __name__ == "__main__":
    main()
