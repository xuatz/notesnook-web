#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu
# Require all four URLs to avoid accidentally mixing cloud and self-hosted services.
for key in NN_API_HOST NN_AUTH_HOST NN_SSE_HOST NN_MONOGRAPH_HOST; do
    value=$(printenv "$key" || true)
    case "$value" in
        https://?*) ;;
        *) echo "$key must be a nonempty HTTPS URL" >&2; exit 1 ;;
    esac
done
# jq safely encodes quotes and other JavaScript-sensitive characters.
config=$(jq -cn '{API_HOST:env.NN_API_HOST, AUTH_HOST:env.NN_AUTH_HOST, SSE_HOST:env.NN_SSE_HOST, MONOGRAPH_HOST:env.NN_MONOGRAPH_HOST}')
printf 'globalThis.__notesnook_hosts__ = %s;\n' "$config" > /usr/share/nginx/html/config.js
