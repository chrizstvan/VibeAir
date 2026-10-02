# Air Alert

Privacy-first air quality alerts for Greater Jakarta.

Air Alert notifies you when the air around you changes, built on three rules:

1. **The server never knows where you are.** Your phone converts its location into a coarse H3 hexagonal cell on the device. Only the cell ID is sent.
2. **Every number says how sure it is.** Estimates come with a range and the distance to the nearest sensor, not a single confident value.
3. **It tries to explain why, not just how bad.** Regional source context from published research.

> **Status:** data feasibility study. There is no app or server yet.

## Repository structure

```
air-alert/
├── .github/workflows/
│   └── spike-collector.yml   # hourly snapshot collector
└── spike/                    # data feasibility study
    ├── points.py             # test points across Greater Jakarta
    ├── inventory.py          # lists OpenAQ locations and sensor freshness
    ├── inventory.csv         # frozen sensor list from day 1 (committed on purpose)
    ├── backfill.py           # 30 days of hourly history from both sources
    ├── collector.py          # hourly live snapshot, run by GitHub Actions
    ├── analysis.ipynb        # analysis and decision table
    ├── raw/                  # raw API responses, never edited
    └── data/                 # derived data, reproducible, not committed
```

## Data spike

### Run it locally

Requirements: Python 3.12, an [OpenAQ API key](https://explore.openaq.org/register).

```bash
cd spike
python3 -m venv .venv && source .venv/bin/activate
pip install httpx pandas numpy matplotlib jupyterlab python-dotenv ruff
echo "OPENAQ_API_KEY=your_key_here" > .env

python inventory.py     # 1. sensor inventory
python backfill.py      # 2. 30-day history from OpenAQ and Open-Meteo
python collector.py     # 3. one live snapshot (Actions runs this hourly)
jupyter lab             # 4. open analysis.ipynb
```

### Hourly collector

`.github/workflows/spike-collector.yml` runs `collector.py` every hour at minute 7 (UTC) for the duration of the spike and commits each snapshot to the `spike-data` branch, keeping `main` clean.

To pull the collected snapshots locally:

```bash
git fetch origin spike-data
git worktree add ../spike-data spike-data
cd ../spike-data && git pull
```

Each snapshot records both `scheduled_for` and `fetched_at`, so scheduler delay can be separated from API publication delay.


## Data sources and attribution

- **[OpenAQ](https://openaq.org)**: ground sensor data, free API with key. Source attribution is required by the OpenAQ terms of use.
- **[Open-Meteo](https://open-meteo.com)**: air quality model data from the Copernicus Atmosphere Monitoring Service (CAMS global, about 45 km resolution over Indonesia). Free for non-commercial use; attribution to CAMS and Open-Meteo is required.

## Privacy

The data spike collects no user data. It only queries public air quality APIs.

## License

To be decided.

## Changelog

- **2026-10-02**: Data spike started. Spike scripts and hourly collector added.