"""
Python Geocoding using Google Places API + Geocoding API
- Tries Places Find Place first
- If address looks "city-level" (no street/number), retries with Places Text Search biased to the city
- Falls back to Geocoding API
- Batch: reads Excel (Name col A, City col B) and writes Lat/Lng/Address/Source/Status

Install:
  pip install requests pandas openpyxl
"""

from __future__ import annotations

import os
import re
import time
from typing import Optional, Dict, Any

import requests
import pandas as pd

# Replace with your Google API key (needs both Places API and Geocoding API enabled)
API_KEY = "AIzaSyD-tIDs1NRlDGJ_hXCEzgCWNPbiEtLhy-0"


# ----------------------------
# Helpers
# ----------------------------
def clean_cell(x) -> Optional[str]:
    """Return a clean string or None if empty/NaN."""
    if pd.isna(x):
        return None
    s = str(x).strip()
    if not s or s.lower() == "nan":
        return None
    return s


def is_low_quality_address(addr: Optional[str]) -> bool:
    """
    Heuristic: if formatted_address has no digits, it's often just city/region/country.
    Not perfect, but very effective for catching 'Amsterdam, Netherlands' style results.
    """
    if not addr or not isinstance(addr, str):
        return True
    return re.search(r"\d", addr) is None


def http_get_json(url: str, params: Dict[str, Any], session: Optional[requests.Session] = None, timeout: int = 20):
    sess = session or requests.Session()
    r = sess.get(url, params=params, timeout=timeout)
    return r.json()


# ----------------------------
# Google APIs
# ----------------------------
def find_venue_with_places_findplace(query: str, api_key: str, session: Optional[requests.Session] = None) -> Dict[str, Any]:
    """
    Places API: Find Place From Text -> then Place Details
    """
    search_url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
    search_params = {
        "input": query,
        "inputtype": "textquery",
        "fields": "place_id,name,formatted_address,geometry",
        "key": api_key,
    }

    try:
        data = http_get_json(search_url, search_params, session=session)
        if data.get("status") == "OK" and data.get("candidates"):
            place_id = data["candidates"][0]["place_id"]
            details = place_details(place_id, api_key, session=session)
            if details and details["status"] == "success":
                details["source"] = "places_findplace"
                return details

        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "venue_name": None,
            "status": f"not_found_in_places:{data.get('status', 'UNKNOWN')}",
            "source": "places_findplace",
        }
    except Exception as e:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "venue_name": None,
            "status": f"Exception: {e}",
            "source": "places_findplace",
        }


def place_details(place_id: str, api_key: str, session: Optional[requests.Session] = None) -> Optional[Dict[str, Any]]:
    """
    Places API: Place Details
    """
    url = "https://maps.googleapis.com/maps/api/place/details/json"
    params = {
        "place_id": place_id,
        "fields": "name,formatted_address,address_components,geometry,types",
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
            "venue_name": res.get("name", ""),
            "status": "success",
            "source": "places_details",
        }
    return None


def places_text_search_place_id(
    query: str,
    api_key: str,
    session: Optional[requests.Session] = None,
    location: Optional[str] = None,   # "lat,lng"
    radius: int = 50000,
    place_type: Optional[str] = "tourist_attraction",
) -> Optional[str]:
    """
    Places API: Text Search (optionally biased to a city's lat/lng)
    """
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


def geocode_venue(query: str, api_key: str, session: Optional[requests.Session] = None) -> Dict[str, Any]:
    """
    Geocoding API fallback
    """
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": query, "key": api_key}

    try:
        data = http_get_json(url, params, session=session)
        if data.get("status") == "OK" and data.get("results"):
            loc = data["results"][0]["geometry"]["location"]
            formatted_address = data["results"][0].get("formatted_address")
            return {
                "latitude": loc.get("lat"),
                "longitude": loc.get("lng"),
                "formatted_address": formatted_address,
                "venue_name": None,
                "status": "success",
                "source": "geocoding_api",
            }
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "venue_name": None,
            "status": f"Error: {data.get('status', 'UNKNOWN')}",
            "source": "geocoding_api",
        }
    except Exception as e:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "venue_name": None,
            "status": f"Exception: {e}",
            "source": "geocoding_api",
        }


def get_venue_location(venue_name: str, city: Optional[str] = None, api_key: str = API_KEY,
                       session: Optional[requests.Session] = None) -> Dict[str, Any]:
    """
    Combined:
    1) Places Find Place -> Details
    2) If address is low-quality, retry with Places Text Search biased to city lat/lng
    3) Fallback to Geocoding API
    """
    venue_name_clean = clean_cell(venue_name)
    city_clean = clean_cell(city)

    if not venue_name_clean and not city_clean:
        return {
            "latitude": None,
            "longitude": None,
            "formatted_address": None,
            "venue_name": None,
            "status": "skipped-empty",
            "source": "none",
        }

    # Query string
    query = ", ".join([v for v in [venue_name_clean, city_clean] if v])

    # 1) Find Place
    result = find_venue_with_places_findplace(query, api_key, session=session)
    if result.get("status") == "success" and not is_low_quality_address(result.get("formatted_address")):
        return result

    # 2) If low-quality or not found: use Text Search biased to city location
    city_location = None
    if city_clean:
        c = geocode_venue(city_clean, api_key, session=session)
        if c.get("status") == "success" and c.get("latitude") is not None and c.get("longitude") is not None:
            city_location = f'{c["latitude"]},{c["longitude"]}'

    place_id = places_text_search_place_id(
        query=query,
        api_key=api_key,
        session=session,
        location=city_location,
        radius=50000,
        place_type="tourist_attraction",
    )
    if place_id:
        details = place_details(place_id, api_key, session=session)
        if details and details.get("status") == "success" and not is_low_quality_address(details.get("formatted_address")):
            details["source"] = "places_textsearch"
            return details
        # If details exist but still low-quality, keep it (better than nothing)
        if details and details.get("status") == "success":
            details["source"] = "places_textsearch_low_quality"
            return details

    # 3) Fallback to Geocoding
    return geocode_venue(query, api_key, session=session)


# ----------------------------
# Excel batch
# ----------------------------
def geocode_excel(
    input_file: str,
    output_file: Optional[str] = None,
    api_key: str = API_KEY,
    delay: float = 0.2,
    sheet_name: int | str = 0,
) -> pd.DataFrame:
    if not api_key:
        raise ValueError("API_KEY is empty. Set GOOGLE_API_KEY env var or fill API_KEY in the script.")

    df = pd.read_excel(input_file, sheet_name=sheet_name)

    if df.shape[1] < 2:
        raise ValueError("Excel file must have at least 2 columns (Name and City)")

    name_col = df.columns[0]
    city_col = df.columns[1]

    # Output columns
    df["Latitude"] = None
    df["Longitude"] = None
    df["Address"] = None
    df["API Source"] = None
    df["Status"] = None

    sess = requests.Session()

    print(f"Processing {len(df)} rows...")

    for i, (idx, row) in enumerate(df.iterrows(), start=1):
        name = clean_cell(row[name_col])
        city = clean_cell(row[city_col])

        # Skip if both empty
        if not name and not city:
            df.at[idx, "Status"] = "skipped-empty"
            df.at[idx, "API Source"] = "none"
            print(f"Skipping row {i}/{len(df)}: empty name+city")
            continue

        print(f"Row {i}/{len(df)}: {', '.join([v for v in [name, city] if v])}")

        result = get_venue_location(name or "", city, api_key=api_key, session=sess)

        df.at[idx, "Latitude"] = result.get("latitude")
        df.at[idx, "Longitude"] = result.get("longitude")
        df.at[idx, "Address"] = result.get("formatted_address")
        df.at[idx, "API Source"] = result.get("source")
        df.at[idx, "Status"] = result.get("status")

        time.sleep(delay)

    out = output_file if output_file else input_file
    df.to_excel(out, index=False)
    print(f"\nSaved: {out}")

    # Summary
    success = (df["Status"] == "success").sum()
    skipped = (df["Status"] == "skipped-empty").sum()
    lowq = df["API Source"].isin(["places_textsearch_low_quality"]).sum()
    print("\nSummary:")
    print(f"Rows: {len(df)}")
    print(f"Success: {success}")
    print(f"Low-quality kept: {lowq}")
    print(f"Skipped empty: {skipped}")
    print(f"Other/failed: {len(df) - success - skipped}")

    return df


def inspect_excel(file_path: str):
    xl = pd.ExcelFile(file_path)
    print(f"\n{'='*60}")
    print(f"Excel File: {file_path}")
    print(f"Sheets: {xl.sheet_names}")
    for s in xl.sheet_names:
        df = pd.read_excel(file_path, sheet_name=s)
        print(f"\n--- Sheet: {s} ---")
        print(f"Dimensions: {len(df)} rows × {len(df.columns)} cols")
        print(f"Columns: {list(df.columns)}")
        print("First 3 rows:")
        print(df.head(3))
        print(f"Non-empty rows (all-cols): {df.dropna(how='all').shape[0]}")
    print(f"{'='*60}\n")


# ----------------------------
# Main
# ----------------------------
if __name__ == "__main__":
    # If you're running from inside the latlong/ folder:
    #   python3 find.py
    # then files should be "venues.xlsx" etc.

    # 1) Inspect
    inspect_excel("venues.xlsx")

    # 2) Batch geocode
    geocode_excel(
        input_file="venues.xlsx",
        output_file="venues_geocoded.xlsx",
        delay=0.25,
        sheet_name=0,
    )

    # 3) Optional single test
    # res = get_venue_location("Amaze Amsterdam", "Amsterdam", api_key=API_KEY)
    # print(res)
