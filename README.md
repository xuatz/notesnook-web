# Notesnook web image

Unofficial packaging of the official Notesnook web client for GHCR.
Upstream source is pinned through the `upstream` Git submodule. Each build uses
the revision recorded in this repository.
No backend services are included.

## Image interface

This repository builds and publishes the web client image. Deployment, networking,
HTTPS termination and backend services are configured by whoever runs it.
The image serves HTTP on container port 80 and provides `/health` for health checks.

Set these environment variables when starting the container:

| Variable | Required value |
| --- | --- |
| `NN_API_HOST` | HTTPS URL of the sync server |
| `NN_AUTH_HOST` | HTTPS URL of the authentication server |
| `NN_SSE_HOST` | HTTPS URL of the events server |
| `NN_MONOGRAPH_HOST` | HTTPS URL of the Monograph server |

The runtime patch reads a JSON-encoded configuration file generated at startup,
so the same image can be used with different backends without rebuilding.
All four variables are required; missing values stop the container instead of
falling back to cloud services. Existing browser server settings override these
defaults; check those settings when switching an existing client to another instance.
Other upstream services (for example subscriptions and issue reporting) retain
upstream behavior. The config file is excluded from the service worker precache
and served with `Cache-Control: no-store`. Never put API secrets in these variables.

## Build locally

```sh
git submodule update --init --recursive
bash scripts/source-archive.sh
docker build --build-arg UPSTREAM_REVISION="$(git -C upstream rev-parse HEAD)" \
  --build-arg REVISION="$(git rev-parse HEAD)" -t notesnook-web:local .
bash scripts/smoke-test.sh notesnook-web:local
```

## GitHub publishing

Push these files and the submodule pointer to the default branch. GitHub Actions
builds and smoke-tests an amd64 image before publishing to
`ghcr.io/xuatz/notesnook-web:latest` and `:sha-<full-packaging-commit>`.
When the pinned upstream commit exactly matches the release tag for the web client's
package version, the same image is also published as `:vX.Y.Z` (or its prerelease tag).
Untagged commits do not receive a release tag. Rebuilding the same upstream release
with packaging changes updates its version tag; use an image digest to pin exact content.
Pull requests only build and test. Manual runs publish only from the default branch.
The workflow uses the built-in `GITHUB_TOKEN` with `packages: write`.
For anonymous image pulls, set the GHCR package visibility to public after its
first publication. Use a published image digest when you want a fixed version.

## Update upstream

```sh
git -C upstream fetch origin tag vX.Y.Z
git -C upstream checkout vX.Y.Z
git add upstream
```

Open a PR with the updated submodule revision. CI verifies the runtime patch still
applies and that the image starts. Review and merge to publish. Builds never run
`git submodule update --remote`. Action dependencies are pinned to commit hashes.
Base images are pinned by digest; Dependabot proposes base image and Action updates.
Upstream application updates are reviewed manually. Package downloads still depend
on the upstream registries; this is not a fully offline build.

## License and source

GPL-3.0-or-later, matching the pinned Notesnook web client. See `LICENSE` (copied
verbatim from upstream). Upstream copyright and license notices remain intact.
The packaging scripts and runtime modifications are also GPL-3.0-or-later.
Third-party components retain their own licenses.

Each image includes `/LICENSE` and `/source.tar.gz`, containing the pinned upstream
source, lockfiles, runtime patch and build scripts. Extract the archive (the upstream source is already included), regenerate it with
`bash scripts/source-archive.sh`, then run `docker build -t notesnook-web:local .`.
The archive excludes Git metadata and installed dependencies; dependencies are
retrieved using the upstream lockfiles during the build. The image labels record
both upstream and packaging revisions. Source: https://github.com/xuatz/notesnook-web.
