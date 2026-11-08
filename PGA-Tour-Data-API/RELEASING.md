# Releasing

This repository is currently distributed from GitHub and GitHub Pages. Before
publishing a package, confirm the checks below from a clean checkout:

1. Run `python scripts/verify_surface.py` and confirm the documented counts.
2. Run `pytest -q` and `mkdocs build --strict`.
3. Run `python -m build` and inspect the generated wheel and source archive.
4. Update `CHANGELOG.md`, `docs/changelog.md`, and the version in `pyproject.toml`.
5. Push the release commit and wait for the test, package and documentation workflows to pass.
6. The package code is released under MIT; preserve `NOTICE.md` and the
   bundled upstream MIT notice. The optional PyPI workflow is
   `.github/workflows/publish.yml`; it publishes only version tags (`v*.*.*`)
   after you configure the `pypi` trusted-publishing environment.

## One-time PyPI setup

PyPI is the public package index where people can install a package with
`pip install pga-tour-unofficial-api`. It is separate from GitHub: GitHub
stores the source code, while PyPI distributes built Python archives.

To enable publishing:

1. Create or sign in to a PyPI account at <https://pypi.org/>.
2. Open <https://pypi.org/manage/account/publishing/> and add a GitHub Actions
   trusted publisher for owner `rubenviolinha`, repository
   `pga-tour-unofficial-api`, workflow `publish.yml`, environment `pypi`.
3. Create a GitHub environment named `pypi` and require your approval for
   deployments.
4. When ready, create and push a tag such as `v0.3.7`; the workflow builds the
   wheel and source archive and uploads them without storing a PyPI password or
   long-lived API token.

The client remains unofficial and uses browser-facing PGA TOUR services. A
release must not be described as an official PGA TOUR API.
