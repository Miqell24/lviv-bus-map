# Lviv Public Transport — interactive map

Interactive, poster-grade map of the public transport network of **Lviv**:
55 bus lines run by seven private operators, the nine trolleybus lines of ЛКП
Львівелектротранс and its eight tram lines — 1 051 stops, 2 090 km, weighted
mean matching error 0.86 m.

## Live

Local build on port 8175 (`npm run serve`).

Everything comes from ONE feed published at track.ua-gis.com and mirrored daily
by the **Mobility Database** as mdb-2374 (the source Transitous uses for Lviv);
the mirror is the primary here because it is reachable from anywhere.

| mode | route_type | graph |
|---|---|---|
| buses | 3 (А…) | OSM roadways |
| trolleybuses | 3 (Тр…) | the same roadways, in green |
| trams | 0 (Т…) | `railway=tram` + `light_rail` |

**The feed marks the MODE inside the line name rather than in `route_type`.**
А01…А99 are buses, Т01…Т09 trams, and Тр22…Тр38 are TROLLEYBUSES filed as
`route_type` 3 — the Mexico City trap, where the feed calls a trolleybus a bus.
Here the giveaway is doubled: the Тр prefix and the operator, ЛКП
Львівелектротранс, which runs nothing else on the road.

**Line keys.** Those prefixes are the feed's bookkeeping, not the street's: Lviv
signs its vehicles "1", "22", "37" and says the mode in words. So the keys keep
А/Т/Тр — they have to, since tram 7 and bus 7 both exist — and `LBL` prints the
bare number.

## Pipeline

`npm run download` fetches the feed and cuts the OSM extract. **The OSM
data comes from Geofabrik, not Overpass** — the public mirrors were answering
504 to every request on the day this map was built, even for a single small
city box — so `pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`)
clips the tiles out of `ukraine-latest.osm.pbf`, writing exactly the JSON shape Overpass would
have returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graph) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view.
`npm run serve` hosts the map at <http://localhost:8175>.

Data: Львівавтодор ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
