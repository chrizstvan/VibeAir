import httpx
from src_common import MIN_LAT, MIN_LON, MAX_LAT, MAX_LON, save_raw, write_inventory

API = "https://data.sensor.community/airrohr/v1/filter"
HEADERS = {"User-Agent": "air-data-check/0.1"}  

def get_data(filter):
    r = httpx.get(f"{API}/{filter}", headers=HEADERS, timeout=60)
    r.raise_for_status()
    return r.json()

box = get_data(f"box={MIN_LAT}, {MIN_LON}, {MAX_LAT}, {MAX_LON}")
save_raw("sensorcommunity", "box", body=box)

country = get_data("country=ID")
save_raw("sensorcommunity", "country_id", country)
print("Seluruh Indonesia:", len({x["sensor"]["id"] for x in country}), "sensor, semua jenis")

latest = {}
for x in box:
    pm = next((v["value"] for v in x["sensordatavalue"] if v["value_type"] == "P2"), None)
    if pm is None: continue

    sid = x["sensoe"]["id"]
    if sid in latest and x["timestamp"] <= latest[sid]["last_utc"]: continue
    latest[sid] = {"source": "sensorcommunity", "sensor_id": sid,
                   "name": x["sensor"].get("sensor_type", {}).get("name"),
                   "lat": float(x["loacation"]["latitude"]),
                   "lon": float(x["loacation"]["longitude"]),
                   "last_utc": x["timestamp"], "pm25": float(pm),
                   "unit": "ug/m3 mentah"
                   }

df = write_inventory("sensorcommunity", list(latest.values()))
print(df.to_string())