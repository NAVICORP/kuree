# Kuree on SkiFi's own server (kuree.skifi.co), on the shared SkiFi app base:
# the database API, sign-in through SkAuth and the server functions in
# supabase/functions. The same image runs twice (deploy/docker-compose.yml):
# as the API, and as the site in front of it (server/site.mjs).
FROM ghcr.io/navicorp/skifi-app:latest
USER root
# python3 + openpyxl make the downloadable spreadsheets.
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-openpyxl \
 && rm -rf /var/lib/apt/lists/*
COPY supabase/migrations /srv/app/migrations
COPY supabase/functions /srv/app/functions
COPY server /srv/site/server
COPY tools /srv/site/tools
COPY web /srv/site/web
ENV SITE_ROOT=/srv/site/web TOOLS_DIR=/srv/site/tools
USER node
