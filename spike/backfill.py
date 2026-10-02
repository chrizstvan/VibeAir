import os, json, time, datetime as dt
import httpx, pandas as pd
from dotenv import load_dotenv
from points import POINTS

load_dotenv()
OAQ = "https://api.openaq.org/v3"
OM = "https://air-quality-api.open-meteo.com/v1/air-quality"
HEADERS = {"X-API-Key": os.environ["OPENAQ_API_KEY"]}
DAYS = 30
end = dt.datetime.now(dt.timezone.utc).replace(minute=0, second=0, microsecond=0)
start = end - dt.timedelta(days=DAYS)

def save(folder, name, body):
    with open(f"raw/{folder}/{name}.json", "w") as f:
        json.dump(body, f)

# 1) OpenAQ: sensor PM2.5 active at lasr 24 hr
inv = pd.read_csv("data/sensor/inventory.csv")
active = inv[(inv.age_hours < 24) & inv.pm25_sensor_id.notna()]
with httpx.Client(headers=HEADERS, timeout=60) as c:
    for sid in active.pm25_sensor_id.astype(int):
        page = 1
        while True:
            r = c.get(f"{OAQ}/sensors/{sid}/hours", params={
                "datetime_from": start.isoformat(), "datetime_to": end.isoformat(),
                "limit": 1000, "page": page
            })

            r.raise_for_status()
            body = r.json()
            save("openaq", f"hours_{sid}_p{page}", body)
            if len(body) < 1000:
                break
            page += 1
        time.sleep(1.1)

# 2) Open-Meteo: evaluation point + active sensors location per request
targets = POINTS + [
    {"id": f"s_{row.location_id}", "lat": row.lat, "lon": row.lon, "group": "sensor"} for row in active.itertuples()
]
r = httpx.Client(OM, params={
    "latitude": ",".join(str(t["lat"]) for t in targets),
    "longitude": ",".join(str(t["lon"]) for t in targets),
    "hourly": "pm2_5,pm10,us_aqi",
    "domains": "cams_global",      # explisit, don't relay to auto
    "cell_selection":"nearest",
    "past_days": DAYS, "forecast_days": 1,
    "timezone": "GMT",
}, timeout=60)

r.raise_for_status()
save("openmeteo", f"backfill_{end:%Y%m%dT%H}", {"targets": targets, "response": r.json()})