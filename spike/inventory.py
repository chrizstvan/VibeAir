import os, json, datetime as dt
import httpx, pandas as pd
from dotenv import load_dotenv

load_dotenv()
BASE = "https://api.openaq.org/v3"
HEADERS = {"X-API-Key": os.environ["OPENAQ_API_KEY"]}
BBOX = "106.4,-6.6,107.2,-6.0" # Jabodetabek

def stamp():
    return dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")

def fetch_location():
    results, page = [], 1
    with httpx.Client(headers=HEADERS, timeout=30) as c:
        r = c.get(f"{BASE}/locations",
                  params={"bbox": BBOX, "limit": 1000, "page": page})
        r.raise_for_status()
        body = r.json()

        with open(f"raw/openaq/locations_{stamp()}_p{page}.json", "w") as f:
            json.dump(body, f)

        results += body["results"]

        if len(body) < 1000:
            return results
        page += 1

rows = []
for loc in fetch_location():
    pm25 = [s for s in loc["sensors"] if "pm25" in s["parameter"]["name"]]
    rows.append({
        "location_id": loc["id"],
        "name": loc["name"],
        "lat": loc["coordinates"]["latitude"],
        "lon": loc["coordinates"]["longitude"],
        "provider": loc["provider"]["name"],
        "is_monitor": loc["isMonitor"],
        "is_mobile": loc["isMobile"],
        "pm25_sensor_id": pm25[0]["id"] if pm25 else None,
        "params": ",".join(s["parameter"]["name"] for s in loc["sensors"]),
        "last_utc": (loc.get("datetimeLast") or {}).get("utc"),
    })

inv = pd.DataFrame(rows)
now = pd.Timestamp.now(tz="UTC")
inv["age_hours"] = (now - pd.to_datetime(inv["last_utc"], utc=True)).dt.total_seconds() / 3600
inv.to_csv("data/sensor/inventory.csv", index=False)
print(inv.sort_values("age_hours")[["name", "provider", "is_monitor", "age_hours", "params"]])
