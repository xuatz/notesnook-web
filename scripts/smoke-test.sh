#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
image=${1:?image name required}
container=""
scratch=$(mktemp -d)
cleanup() { if [ -n "$container" ]; then docker rm -f "$container" >/dev/null; fi; }
trap 'cleanup; rm -rf "$scratch"' EXIT
container=$(docker run -d -p 127.0.0.1::80 \
  -e NN_API_HOST=https://api.example.com \
  -e NN_AUTH_HOST=https://auth.example.com \
  -e NN_SSE_HOST=https://events.example.com \
  -e NN_MONOGRAPH_HOST=https://share.example.com "$image")
port=$(docker port "$container" 80/tcp | cut -d: -f2)
base="http://127.0.0.1:$port"
ready=false
for attempt in $(seq 1 30); do
  if curl -fsS "$base/health" >/dev/null; then ready=true; break; fi
  sleep 1
done
if [ "$ready" != true ]; then docker logs "$container"; exit 1; fi
curl -fsS "$base/" -o "$scratch/index.html"
grep -q '/config.js' "$scratch/index.html"
curl -fsS "$base/config.js" -o "$scratch/config.js"
grep -q '"API_HOST":"https://api.example.com"' "$scratch/config.js"
grep -q '"AUTH_HOST":"https://auth.example.com"' "$scratch/config.js"
grep -q '"SSE_HOST":"https://events.example.com"' "$scratch/config.js"
grep -q '"MONOGRAPH_HOST":"https://share.example.com"' "$scratch/config.js"
curl -fsSI "$base/config.js" -o "$scratch/headers"
grep -qi 'cache-control: no-store' "$scratch/headers"
curl -fsS "$base/LICENSE" -o "$scratch/LICENSE"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$scratch/LICENSE"
curl -fsS "$base/source.tar.gz" -o "$scratch/source.tar.gz"
tar -tzf "$scratch/source.tar.gz" > "$scratch/source.txt"
grep -q 'upstream/apps/web/src/common/db.ts' "$scratch/source.txt"
# Configuration must not be captured by the service worker's offline precache.
curl -fsS "$base/service-worker.js" -o "$scratch/service-worker.js"
if grep -q 'config.js' "$scratch/service-worker.js"; then
  echo 'Runtime config appears in service worker precache' >&2; exit 1
fi
cleanup
container=""
if docker run --rm --entrypoint /docker-entrypoint.d/40-runtime-config.sh "$image" >/dev/null 2>&1; then
  echo 'Container unexpectedly accepted missing URL variables' >&2; exit 1
fi
echo 'Smoke tests passed.'
