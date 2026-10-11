import json, datetime as dt
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent
MIN_LON, MIN_LAT, MAX_LON, MAX_LAT = 106.4, -6.6, 107.2, -6.0   # sama dengan inventory.py
COLUMNS = ["source", "sensor_id", "name", "lat", "lon", "last_utc", "age_hours", "pm25", "unit"]

def in_bbox(lat, lon):
    return MIN_LAT <= lat <= MAX_LAT and MIN_LON <= lon <= MAX_LON

def save_raw(source, name, body):
    """Store raw response before processing"""
    out = BASE / "raw" / source
    out.mkdir(parents=True, exist_ok=True)
    ts = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    with open(out / f"{name}_{ts}.json", "w") as f:
        json.dump(body, f)

def write_inventory(source, rows):
    """rows: list of dict contains COLUMNS except age_hours."""
    df = pd.DataFrame(rows, columns=COLUMNS)
    df["last_utc"] = pd.to_datetime(df.last_utc, utc=True, errors="coerce")
    now = pd.Timestamp.now(tz="UTC")
    df["age_hours"] = (now - df.last_utc).dt.total_seconds() / 3600
    out = BASE / "data" / "sensor"
    out.mkdir(exist_ok=True)
    df.to_csv(out / f"{source}.csv", index=False)
    print(f"{source}: {len(df)} sensor PM2.5 in the box, {(df.age_hours < 24).sum()} active < 24 hours")
    return df