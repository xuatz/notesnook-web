# SPDX-License-Identifier: GPL-3.0-or-later
FROM node:22.20.0-bookworm@sha256:915acd9e9b885ead0c620e27e37c81b74c226e0e1c8177f37a60217b6eabb0d7 AS builder
WORKDIR /src
ENV CI=true HUSKY=0 THREADS=4 NODE_OPTIONS=--max-old-space-size=6144
COPY upstream/ ./
RUN npm ci --ignore-scripts --no-audit --no-fund && npm run bootstrap -- --scope web
COPY patches/runtime-config.patch /tmp/runtime-config.patch
RUN git apply --check /tmp/runtime-config.patch && git apply /tmp/runtime-config.patch
ARG UPSTREAM_REVISION=unknown
ENV GIT_HASH=${UPSTREAM_REVISION}
RUN npm run build:web

FROM nginx:stable-alpine@sha256:985220252f3863977e468f611ef118ebd01421289dd86ee1ae99cb068c3bce2b AS runtime
RUN apk add --no-cache jq
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY scripts/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
RUN chmod +x /docker-entrypoint.d/40-runtime-config.sh
COPY --from=builder /src/apps/web/build/ /usr/share/nginx/html/
COPY LICENSE /usr/share/nginx/html/LICENSE
# Include the pinned application source and packaging files with every image.
COPY source.tar.gz /usr/share/nginx/html/source.tar.gz
ARG UPSTREAM_REVISION=unknown
ARG REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/xuatz/notesnook-web"       org.opencontainers.image.licenses="GPL-3.0-or-later"       org.opencontainers.image.revision="${REVISION}"       io.notesnook.upstream.revision="${UPSTREAM_REVISION}"
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1
