import os, json, time, datetime as dt
from pathlib import Path
import httpx
from dotenv import load_dotenv

load_dotenv()
BASE = Path(__file__).resolve().parent
WAQI = "https://api.waqi.info"
TOKEN = os.environ["WAQI_TOKEN"]
AG_URL = "https://api.airgradient.com/public/api/v1/world/locations/measures/current"
MIN_LON, MIN_LAT, MAX_LON, MAX_LAT = 106.4, -6.6, 107.2, -6.0
run = dt.datetime.now(dt.timezone.utc)

def call(client, url, **params):
    """Satu panggilan API. Kegagalan dicatat, bukan menghentikan script."""
    t0 = time.monotonic()
    try:
        r = client.get(url, params=params)
        body = r.json() if r.headers.get("content-type", "").startswith("application/json") else None
        return {"status": r.status_code, "ms": round((time.monotonic() - t0) * 1000), "body": body}
    except httpx.HTTPError as e:
        return {"status": None, "ms": round((time.monotonic() - t0) * 1000), "error": repr(e)}

def di_kotak(x):
    lat, lon = x.get("latitude"), x.get("longitude")
    return lat is not None and lon is not None and MIN_LAT <= lat <= MAX_LAT and MIN_LON <= lon <= MAX_LON

snap = {"scheduled_for": run.replace(minute=7, second=0, microsecond=0).isoformat(),
        "fetched_at": run.isoformat(),
        "waqi_bounds": None, "waqi": {}, "airgradient": None}

with httpx.Client(timeout=30) as c:
    snap["waqi_bounds"] = call(c, f"{WAQI}/v2/map/bounds",
                               latlng=f"{MIN_LAT},{MIN_LON},{MAX_LAT},{MAX_LON}",
                               networks="all", token=TOKEN)
    for s in (snap["waqi_bounds"].get("body") or {}).get("data", []):
        snap["waqi"][s["uid"]] = call(c, f"{WAQI}/feed/@{s['uid']}/", token=TOKEN)
        time.sleep(1)

    ag = call(c, AG_URL)
    if isinstance(ag.get("body"), list):
        ag["body"] = [x for x in ag["body"] if di_kotak(x)]
    snap["airgradient"] = ag

out = BASE / "raw" / "collector"
out.mkdir(parents=True, exist_ok=True)
with open(out / f"{run:%Y%m%dT%H%M}.json", "w") as f:
    json.dump(snap, f)
print("waqi:", len(snap["waqi"]), "stasiun | airgradient:", len(snap["airgradient"].get("body") or []))