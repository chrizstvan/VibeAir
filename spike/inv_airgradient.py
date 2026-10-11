import httpx
import src_common as common

URL = "https://api.airgradient.com/public/api/v1/world/locations/measures/current"

r = httpx.get(URL, timeout=60)
r.raise_for_status()
body = r.json()
common.save_raw("airgradient", "world_current", body)
print("Total public location around the world:", len(body))

rows = []
for x in body:
    lat, lon = x.get("latitude"), x.get("longitude")
    if lat is None or lon is None or not common.in_bbox(lat, lon):
        continue
    rows.append({
        "source": "airgradient",
        "sensor_id": x["locationId"],
        "name": x.get("publicLocationName") or x.get("locationName"),
        "lat": lat, "lon": lon,
        "last_utc": x.get("timestamp"),
        "pm25": x.get("pm02"),
        "unit": "ug/m3 raw"
    })

df = common.write_inventory("airgradient", rows)
print(df.sort_values("age_hours")[["name", "lat", "lon", "age_hours", "pm25"]].to_string())