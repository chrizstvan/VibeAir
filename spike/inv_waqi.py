import os, time
import httpx
from dotenv import load_dotenv
from src_common import MIN_LAT, MIN_LON, MAX_LAT, MAX_LON, save_raw, write_inventory

load_dotenv()
TOKEN = os.environ["WAQI_TOKEN"]
API = "https://api.waqi.info"

# 1. All station / sensor in the boundary box
r = httpx.get(f"{API}/v2/map/bounds", params={
    "latlng": f"{MIN_LAT},{MIN_LON},{MAX_LAT},{MAX_LON}",
    "networks": "all", "token": TOKEN
}, timeout=60)

r.raise_for_status()
body = r.json()
save_raw("waqi", "map_bounds", body)

if body.get("status") != "ok":
    raise SystemExit(body)

print(len(body["data"]), "stasiun. Contoh:", body["data"][0])

# 2. Detail each station: is PM2.5 exist or not, last time active, who's the owner
rows = []
for s in body["data"]:
    d = httpx.get(f"{API}/feed/@{s['uid']}/", params={"token": TOKEN}, timeout=60).json()
    save_raw("waqi", f"feed_{s['uid']}", d)
    data = d.get("data") if d.get("status") == "ok" else {}
    pm = (data.get("iaqi") or {}).get("pm25", {}).get("v")
    if pm is None: continue

    owner = "; ".join(a.get("name", "") for a in data.get("attributions", []))
    rows.append({"source": "waqi", "sensor_id": s["uid"],
                 "name": f"{s.get('station', {}).get('name')} [{owner}]",
                 "lat": s.get("lat"), "lon": s.get("lon"),
                 "last_utc": (data.get("time") or {}).get("iso"),
                 "pm25": pm, "unit": "AQI, bukan konsentrasi"})
    time.sleep(1)

df = write_inventory("waqi", rows)
print(df.sort_values("age_hours")[["name", "age_hours", "pm25"]].to_string())