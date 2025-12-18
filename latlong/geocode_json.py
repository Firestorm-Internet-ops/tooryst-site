"""
Read venues.xlsx (Column A = attraction name, Column B = city name),
and write results to:
  Column C = Latitude
  Column D = Longitude
  Column E = Address
  Column F = Resolved Name

Resolution strategy:
1) Places Find Place From Text -> Place Details
2) If address looks city/area-level (no digits), retry Places Text Search biased to city center -> Place Details
3) Fallback to Geocoding API

Install:
  pip install requests pandas openpyxl

Set API key (recommended):
  export GOOGLE_API_KEY="YOUR_KEY"

Run (from the same folder as venues.xlsx):
  python3 geocode_venues_excel.py
"""

from __future__ import annotations

import os
import re
import time
from typing import Optional, Dict, Any, Tuple

import requests
import pandas as pd

# -------- CONFIG --------
INPUT_XLSX = "venues.xlsx"
OUTPUT_XLSX = "venues_geocoded.xlsx"  # change to INPUT_XLSX if you want overwrite
SHEET_NAME = 0                        # 0 for first sheet, or "Sheet1"
DELAY_SECONDS = 0.25                  # slow down to avoid rate limits
CITY_TEXTSEARCH_RADIUS_M = 50000      # bias search within 50km of city center
PLACES_TYPE = "tourist_attraction"    # can tweak: museum, point_of_interest, etc.

API_KEY = "AIzaSyD-tIDs1NRlDGJ_hXCEzgCWNPbiEtLhy-0"
# Or hardcode (not recommended):
# API_KEY = "YOUR_KEY"


# ----------------------------
# Helpers
# ----------------------------
def clean_cell(x) -> Optional[str]:
    if x is None:
        return None
    if pd.isna(x):
        return None
    s = str(x).strip()
    if not s or s.lower() == "nan":
        return None
    return s


def is_low_quality_address(addr: Optional[str]) -> bool:
    """Heuristic: city/area-level addresses often have no digits."""
    if not addr or not isinstance(addr, str):
        return True
    return re.search(r"\d", addr) is None


def http_get_json(url: str, params: Dict[str, Any], session: requests.Session, timeout: int = 20) -> Dict[str, Any]:
    r = session.get(url, params=params, timeout=timeout)
    return r.json()


# ----------------------------
# Google APIs
# ----------------------------
def place_details(place_id: str, api_key: str, session: requests.Session) -> Optional[Dict[str, Any]]:
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "name,formatted_address,geometry,types",
        "key": api_key,
    }
    data = http_get_json(url, params, session=session)
    if data.get("status") == "OK":
        res = data["result"]
        loc = res["geometry"]["location"]
        return {
            "latitude": loc.get("lat"),
            "longitude": loc.get("lng"),
            "formatted_address": res.get("formatted_address", ""),
            "resolved_name": res.get("name", ""),
            "status": "success",
            "source": "places_details",
            "place_id": place_id,
        }
    return None


def findplace_then_details(query: str, api_key: str, session: requests.Session) -> Dict[str, Any]:
    url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
    params = {
        "input": query,
        "inputtype": "textquery",
        "fields": "place_id",
        "key": api_key,
    }
    try:
        data = http_get_json(url, params, session=session)
        if data.get("status") == "OK" and data.get("candidates"):
            pid = data["candidates"][0]["place_id"]
            details = place_details(pid, api_key, session=session)
            if details and details["status"] == "success":
                details["source"] = "places_findplace"
                return details
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "resolved_name": None,
            "status": f"not_found_in_places:{data.get('status', 'UNKNOWN')}",
            "source": "places_findplace",
            "place_id": None,
        }
    except Exception as e:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "resolved_name": None,
            "status": f"Exception: {e}",
            "source": "places_findplace",
            "place_id": None,
        }


def places_text_search_place_id(
    query: str,
    api_key: str,
    session: requests.Session,
    location: Optional[str] = None,  # "lat,lng"
    radius: int = 50000,
    place_type: Optional[str] = None,
) -> Optional[str]:
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    params: Dict[str, Any] = {"query": query, "key": api_key}
    if location:
        params["location"] = location
        params["radius"] = radius
    if place_type:
        params["type"] = place_type

    data = http_get_json(url, params, session=session)
    if data.get("status") == "OK" and data.get("results"):
        return data["results"][0].get("place_id")
    return None


def geocode_fallback(query: str, api_key: str, session: requests.Session) -> Dict[str, Any]:
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": query, "key": api_key}
    try:
        data = http_get_json(url, params, session=session)
        if data.get("status") == "OK" and data.get("results"):
            loc = data["results"][0]["geometry"]["location"]
            addr = data["results"][0].get("formatted_address")
            return {
                "latitude": loc.get("lat"),
                "longitude": loc.get("lng"),
                "formatted_address": addr,
                "resolved_name": None,
                "status": "success",
                "source": "geocoding_api",
                "place_id": None,
            }
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "resolved_name": None,
            "status": f"Error: {data.get('status', 'UNKNOWN')}",
            "source": "geocoding_api",
            "place_id": None,
        }
    except Exception as e:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "resolved_name": None,
            "status": f"Exception: {e}",
            "source": "geocoding_api",
            "place_id": None,
        }


# ----------------------------
# Resolver (with city caching)
# ----------------------------
def get_city_latlng(city: str, api_key: str, session: requests.Session, city_cache: Dict[str, Tuple[float, float]]):
    if city in city_cache:
        return city_cache[city]

    r = geocode_fallback(city, api_key, session=session)
    if r.get("status") == "success" and r.get("latitude") is not None and r.get("longitude") is not None:
        city_cache[city] = (float(r["latitude"]), float(r["longitude"]))
        return city_cache[city]

    return None


def resolve_attraction(attraction_name: str, city_name: Optional[str], api_key: str, session: requests.Session,
                       city_cache: Dict[str, Tuple[float, float]]) -> Dict[str, Any]:
    name = clean_cell(attraction_name)
    city = clean_cell(city_name)

    if not name and not city:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "resolved_name": None,
            "status": "skipped-empty",
            "source": "none",
            "place_id": None,
        }

    query = ", ".join([v for v in [name, city] if v])

    # 1) Find Place
    r1 = findplace_then_details(query, api_key, session=session)
    if r1.get("status") == "success" and not is_low_quality_address(r1.get("formatted_address")):
        return r1

    # 2) Text Search biased to city center (only if we have a city)
    city_loc = None
    if city:
        latlng = get_city_latlng(city, api_key, session=session, city_cache=city_cache)
        if latlng:
            city_loc = f"{latlng[0]},{latlng[1]}"

    pid = places_text_search_place_id(
        query=query,
        api_key=api_key,
        session=session,
        location=city_loc,
        radius=CITY_TEXTSEARCH_RADIUS_M,
        place_type=PLACES_TYPE,
    )
    if pid:
        d = place_details(pid, api_key, session=session)
        if d and d.get("status") == "success":
            # Keep it even if low-quality; mark via source
            if is_low_quality_address(d.get("formatted_address")):
                d["source"] = "places_textsearch_low_quality"
            else:
                d["source"] = "places_textsearch"
            return d

    # 3) Geocoding fallback
    return geocode_fallback(query, api_key, session=session)


# ----------------------------
# Excel driver
# ----------------------------
def geocode_venues_excel(input_xlsx: str, output_xlsx: str, sheet_name=0, delay: float = 0.25) -> pd.DataFrame:
    if not API_KEY:
        raise ValueError("Missing API key. Set GOOGLE_API_KEY env var (recommended).")

    df = pd.read_excel(input_xlsx, sheet_name=sheet_name)

    if df.shape[1] < 2:
        raise ValueError("venues.xlsx must have at least 2 columns: Column A (attraction), Column B (city).")

    col_a = df.columns[0]  # attraction
    col_b = df.columns[1]  # city

    # Ensure columns C-F exist with exact names (these become output columns)
    df["Latitude"] = None
    df["Longitude"] = None
    df["Address"] = None
    df["Resolved Name"] = None

    session = requests.Session()
    city_cache: Dict[str, Tuple[float, float]] = {}

    total = len(df)
    print(f"Processing {total} rows from {input_xlsx} (sheet={sheet_name})...")

    for i, (idx, row) in enumerate(df.iterrows(), start=1):
        attraction = clean_cell(row[col_a])
        city = clean_cell(row[col_b])

        if not attraction and not city:
            print(f"[{i}/{total}] skip empty")
            continue

        result = resolve_attraction(attraction or "", city, API_KEY, session=session, city_cache=city_cache)

        df.at[idx, "Latitude"] = result.get("latitude")
        df.at[idx, "Longitude"] = result.get("longitude")
        df.at[idx, "Address"] = result.get("formatted_address")
        df.at[idx, "Resolved Name"] = result.get("resolved_name")

        print(f"[{i}/{total}] {attraction}, {city} -> {result.get('status')} ({result.get('source')})")

        time.sleep(delay)

    # Write output. Columns will be A,B plus the new columns (which end up after existing cols).
    # If you *must* force C-F positions strictly, keep your input sheet to only A and B.
    df.to_excel(output_xlsx, index=False)
    print(f"\nSaved: {output_xlsx}")
    return df


if __name__ == "__main__":
    geocode_venues_excel(
        input_xlsx=INPUT_XLSX,
        output_xlsx=OUTPUT_XLSX,
        sheet_name=SHEET_NAME,
        delay=DELAY_SECONDS,
    )
