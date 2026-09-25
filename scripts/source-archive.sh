#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail
cd "$(dirname "$0")/.."
tar --exclude=.git --exclude=node_modules --exclude=build --exclude=source.tar.gz     --exclude='.env' --exclude='.env.*'     -czf source.tar.gz upstream patches scripts Dockerfile nginx.conf LICENSE README.md .github .gitmodules .dockerignore
