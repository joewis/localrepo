#!/usr/bin/env python3
"""
lta-route — plan a Singapore bus route between two locations using LTA DataMall.

Finds bus stops within a radius of origin and destination, matches services that
serve both, and reports which are boardable near the origin. Uses the live LTA
endpoint names (v3/BusArrival, Taxi-Availability, etc.).

Usage:
  lta-route --from "1.370485,103.967141" --to "68 Bedok South Avenue 3, Singapore"
  lta-route --from "1.370485,103.967141" --to "1.3187485,103.9433273" --radius 500
  lta-route --from "work" --to "home"          # named locations from config

Locations can be lat,lon or a place name (geocoded via Nominatim). Named locations
(work, home) are read from ${XDG_CONFIG_HOME:-~/.config}/lta-route/locations.json.
"""
import argparse, json, math, os, pathlib, sys, time, urllib.parse, urllib.request

sys.path.insert(0, "/opt/mcp/servers")
from secret_source import secret  # noqa: E402

BASE = "https://datamall2.mytransport.sg/ltaodataservice/"
CONFIG_DIR = pathlib.Path(os.path.expanduser("~/.config/lta-route"))
LOCATIONS_FILE = CONFIG_DIR / "locations.json"

def get_key():
    """LTA_DATAMALL_API_KEY: env first (gateway-injected), dotenv fallback."""
    return secret("LTA_DATAMALL_API_KEY")
def hav(lat1, lon1, lat2, lon2):
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2-lat1); dl = math.radians(lon2-lon1)
    a = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def api_get(path, params=None):
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"AccountKey": get_key()})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def geocode(place):
    """Resolve a place name to (lat, lon). Returns None if it's already coords."""
    place = place.strip()
    if "," in place:
        parts = [p.strip() for p in place.split(",")]
        if len(parts) == 2:
            try:
                return (float(parts[0]), float(parts[1]))
            except ValueError:
                pass
    # named location?
    if LOCATIONS_FILE.exists():
        locs = json.loads(LOCATIONS_FILE.read_text())
        if place in locs:
            return tuple(locs[place])
    # geocode via Nominatim
    url = "https://nominatim.openstreetmap.org/search?format=json&q=" + urllib.parse.quote(place)
    req = urllib.request.Request(url, headers={"User-Agent": "lta-route/1.0"})
    with urllib.request.urlopen(req, timeout=20) as r:
        res = json.loads(r.read())
    if res:
        return (float(res[0]["lat"]), float(res[0]["lon"]))
    raise ValueError(f"Could not resolve location: {place}")

def fetch_all(path):
    out = []
    skip = 0
    while True:
        batch = api_get(path, {"$skip": skip})
        out.extend(batch.get("value", []))
        if len(batch.get("value", [])) < 500:
            break
        skip += 500
    return out

def main():
    ap = argparse.ArgumentParser(description="Plan a Singapore bus route via LTA DataMall")
    ap.add_argument("--from", dest="origin", required=True, help="Origin: 'lat,lon' or place name or named location")
    ap.add_argument("--to", dest="dest", required=True, help="Destination: 'lat,lon' or place name or named location")
    ap.add_argument("--radius", type=float, default=500, help="Search radius in meters (default 500)")
    ap.add_argument("--board-radius", type=float, default=300, help="Max distance from origin to board (default 300)")
    args = ap.parse_args()

    o = geocode(args.origin)
    d = geocode(args.dest)
    print(f"Origin: {o[0]:.6f},{o[1]:.6f}")
    print(f"Dest:   {d[0]:.6f},{d[1]:.6f}")
    print(f"Straight-line distance: {hav(*o, *d)*1000:.0f} m")

    print("\nFetching bus stops...")
    stops = fetch_all("BusStops")
    stop_by_code = {s["BusStopCode"]: s for s in stops}
    print(f"  {len(stops)} stops")

    # Stops within radius of destination
    dest_stops = [(s["BusStopCode"], hav(*d, s["Latitude"], s["Longitude"])*1000, s.get("Description",""))
                  for s in stops if hav(*d, s["Latitude"], s["Longitude"]) < args.radius/1000]
    dest_stops.sort(key=lambda x: x[1])
    print(f"\n=== {len(dest_stops)} stops within {args.radius:.0f}m of destination ===")
    for c, dist, desc in dest_stops:
        print(f"  {c} {desc:30s} {dist:.0f}m")
    dest_codes = {c for c, _, _ in dest_stops}

    print("\nFetching bus routes...")
    routes = fetch_all("BusRoutes")
    print(f"  {len(routes)} route rows")

    # Services serving destination stops
    dest_svcs = {}
    for row in routes:
        if row["BusStopCode"] in dest_codes:
            dest_svcs.setdefault(row["ServiceNo"], set()).add(row["Direction"])
    print(f"\n=== {len(dest_svcs)} services serve destination stops ===")

    # Which of these can be boarded near origin?
    print(f"\n=== Boardable near origin (within {args.board_radius:.0f}m) ===")
    found = False
    for svc in sorted(dest_svcs):
        board = []
        for row in routes:
            if row["ServiceNo"] == svc:
                sc = row["BusStopCode"]
                if sc in stop_by_code:
                    s = stop_by_code[sc]
                    dist = hav(*o, s["Latitude"], s["Longitude"])*1000
                    if dist < args.board_radius:
                        board.append((dist, sc, s.get("Description",""), row["Direction"]))
        if board:
            found = True
            board.sort()
            print(f"\n  {svc}: {len(board)} boarding stops near origin")
            for dist, sc, desc, dirn in board[:5]:
                print(f"      {sc} {desc:28s} {dist:.0f}m dir={dirn}")
    if not found:
        print("  None of the destination-serving services can be boarded near the origin.")
        print("  Consider a transfer (e.g. via MRT) or a larger --board-radius.")

if __name__ == "__main__":
    main()
