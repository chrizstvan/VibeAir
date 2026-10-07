import os, json, time, datetime as dt
import httpx, pandas as pd
from dotenv import load_dotenv
from points import POINTS

load_dotenv()
OAQ = "https://api.openaq.org/v3"
OM = "https://air-quality-api.open-meteo.com/v1/air-quality"
HEADERS = {"X-API-Key": os.environ["OPENAQ_API_KEY"]}
run = dt.datetime.now(dt.timezone.utc)

def call(client, url, **params):
    t0 = time.monotonic()
    try:
        r = client.get(url, params=params)
        body = r.json() if r.headers.get("content-type", "").startswith("application/json") else None
        return {"status": r.status_code, "ms": round((time.monotonic() - t0) * 1000), "body": body}
    except httpx.HTTPError as e:
        return {"status": None, "ms": round((time.monotonic() - t0) * 1000), "error": repr(e)}

inv = pd.read_csv("data/sensor/inventory.csv")
location = inv[inv.pm25_sensor_id.notna()].location_id.astype(int).tolist()
scheduled = run.replace(minute=7, second=0, microsecond=0)
snap = {"scheduled_for": scheduled.isoformat(),
        "fetched_at": run.isoformat(),
        "openaq": {}, "openmeteo": None}

with httpx.Client(headers=HEADERS, timeout=30) as c:
    snap["openmeteo"] = call(c, OM, 
        latitude=",".join(str(p["lat"]) for p in POINTS),
        longitude=",".join(str(p["lon"]) for p in POINTS),
        current="pm2_5,us_aqi", domains="cams_global",
        cell_selection="nearest", timezone="GMT")

with open(f"raw/collector/{run:%Y%m%dT%H%M}.json", "w") as f:
    json.dump(snap, f)