"""Verify that the published API counts and bundled query surface agree."""
from __future__ import annotations

import json
from pathlib import Path

import pga_tour_api as pga


ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "endpoint_manifest.json").read_text())
graphql_files = sorted((ROOT / "graphql").glob("*.graphql"))
package_queries = sorted((ROOT / "src" / "pga_tour_api" / "queries").glob("*.graphql"))
manifest_graphql = [item for item in manifest["endpoints"] if item["transport"] == "graphql"]
functions = [name for name in pga.__all__ if name.startswith("pga_")]

checks = {
    "root query documents": len(graphql_files),
    "package query documents": len(package_queries),
    "manifest GraphQL operations": len(manifest_graphql),
    "exported convenience functions": len(functions),
}
expected = {
    "root query documents": 44,
    "package query documents": 44,
    "manifest GraphQL operations": 44,
    "exported convenience functions": 56,
}
for label, actual in checks.items():
    print(f"{label}: {actual}")
    if actual != expected[label]:
        raise SystemExit(f"{label} expected {expected[label]}, got {actual}")

root_names = {path.name for path in graphql_files}
package_names = {path.name for path in package_queries}
manifest_names = {Path(item["query_file"]).name for item in manifest_graphql}
if root_names != package_names or root_names != manifest_names:
    raise SystemExit("query filenames differ between root, package and manifest")
print("surface verification: OK")
