import os
import httpx, pandas as pd
from dotenv import load_dotenv
from src_common import MIN_LAT, MIN_LON, MAX_LAT, MAX_LON, save_raw, write_inventory

load_dotenv()
r = httpx.get("https://api.purpleair.com/v1/sensors",
              headers={"X-API-Key": os.environ["PURPLEAIR_API_KEY"]},
              params={"fields": "name,latitude,longitude,last_seen,pm2.5_atm",
                      "location_type": 0,              # 0 = luar ruangan
                      "max_age": 0,                    # 0 = sertakan yang sudah lama mati
                      "nwlng": MIN_LON, "nwlat": MAX_LAT,   # sudut barat laut
                      "selng": MAX_LON, "selat": MIN_LAT},  # sudut tenggara
              timeout=60)
print("Status:", r.status_code)
body = r.json()
save_raw("purpleair", "sensors", body)
r.raise_for_status()

kolom = body["fields"]                                 # urutan kolom ada di respons
rows = []
for baris in body["data"]:
    x = dict(zip(kolom, baris))
    rows.append({"source": "purpleair", "sensor_id": x.get("sensor_index"),
                 "name": x.get("name"),
                 "lat": x.get("latitude"), "lon": x.get("longitude"),
                 "last_utc": pd.to_datetime(x.get("last_seen"), unit="s", utc=True),
                 "pm25": x.get("pm2.5_atm"), "unit": "ug/m3 mentah"})

df = write_inventory("purpleair", rows)
print(df.sort_values("age_hours").to_string())