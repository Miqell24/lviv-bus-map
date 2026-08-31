#!/usr/bin/env bash
# Downloads input data: the Lviv GTFS, the OSM extract, MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# The city's feed is published at track.ua-gis.com and mirrored daily by the
# Mobility Database as mdb-2374 (the source Transitous uses for Lviv); the
# mirror is the primary here because it is reachable from anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== Lviv GTFS =="
  curl -fL --retry 3 --max-time 600 -o data/lviv-gtfs.zip \
    "https://files.mobilitydatabase.org/mdb-2374/latest.zip" \
    || curl -fL --retry 3 --max-time 600 -o data/lviv-gtfs.zip "https://track.ua-gis.com/gtfs/lviv/static.zip"
  unzip -o data/lviv-gtfs.zip -d data/gtfs
fi

# 2) OSM — from the Geofabrik extract, not Overpass.
#    2 x 2 road tiles plus the tram network, out of the Ukrainian Geofabrik
#    extract. If kyiv-bus-map already has it, hard-link it instead.
#    pipeline/pbf-tiles.py cuts the tiles out of the .pbf and writes exactly the
#    JSON shape Overpass would have returned (ways with tags, NODE IDS and
#    geometry — buildGraph silently drops ways without el.nodes).
if [ ! -f data/osm/tiles/t4.json ] || [ ! -f data/osm/lviv-rail.json ]; then
  need_osmium
  if [ ! -f data/ukraine-latest.osm.pbf ]; then
    echo "== Geofabrik ukraine-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/ukraine-latest.osm.pbf \
      "https://download.geofabrik.de/europe/ukraine-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm 2>/dev/null || true
