#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
upstream=${1:-upstream}
version=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$upstream/apps/web/package.json")
tag="v$version"
# Only publish conventional release tags that are also valid container tags.
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9_.-]+)?$ ]] || (( ${#tag} > 128 )); then
  echo "Unsupported upstream version: $version" >&2
  exit 1
fi
# Fetch only the candidate release tag, without changing the pinned checkout.
if git -C "$upstream" ls-remote --exit-code --refs --tags origin "refs/tags/$tag" >/dev/null; then
  git -C "$upstream" fetch --depth=1 origin "refs/tags/$tag:refs/tags/$tag"
else
  status=$?
  if [ "$status" -eq 2 ]; then exit 0; fi
  exit "$status"
fi
# Dereference annotated tags; matching package metadata alone is insufficient.
if [ "$(git -C "$upstream" rev-parse "refs/tags/$tag^{commit}")" = "$(git -C "$upstream" rev-parse HEAD)" ]; then
  printf '%s\n' "$tag"
fi
