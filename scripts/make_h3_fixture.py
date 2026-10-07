import json
from pathlib import Path
import h3

OUT = Path(__file__).resolve().parent.parent / "AirCore/Tests/AirCoreTests/Fixtures/h3_cells.json"

POINTS = [
    ("monas",     -6.1754, 106.8272),
    ("bekasi",    -6.2380, 106.9760),
    ("depok",     -6.4020, 106.7940),
    ("tangerang", -6.1780, 106.6320),
    ("bogor",     -6.5950, 106.8160),
]

cells = []
for name, lat, lon in POINTS:
    for res in (6, 7, 8):
        cell = h3.latlng_to_cell(lat, lon, res)
        center_lat, center_lon = h3.cell_to_latlng(cell)

        cells.append({
            "name": name, "lat": lat, "lon": lon, "res": res,
            "cell_hex": cell,
            "cell_uint64": str(h3.str_to_int(cell)),    # string, not number
            "center_lat": center_lat, "center_lon": center_lon,
            "disk1": sorted(h3.grid_disk(cell, 1)),
        })

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps({"h3_versions": h3.versions(), "cells": cells}, indent=2))
print(f"{len(cells)} cell has written to {OUT}")