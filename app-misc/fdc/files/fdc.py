#!/usr/bin/env python3
"""
Food Data Central (FDC) API CLI wrapper.

Reads API key from /etc/fdc/api_key (first line), or falls back to DEMO_KEY.
Supports all FDC REST endpoints.

Usage:
  fdc search <query> [--data-type ...] [--page-size N] [--page-number N] [--brand-owner ...]
  fdc get <fdc-id> [--format abridged|full] [--nutrients N,N,...]
  fdc get-multi <fdc-id> [<fdc-id> ...] [--format abridged|full] [--nutrients N,N,...]
  fdc list [--data-type ...] [--page-size N] [--page-number N] [--sort-by ...] [--sort-order asc|desc]
  fdc --help
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.parse
import urllib.error

CONFIG_PATH = "/etc/fdc/api_key"
BASE_URL = "https://api.nal.usda.gov/fdc/v1"


def read_api_key():
    """Read API key from config file, or return DEMO_KEY."""
    try:
        with open(CONFIG_PATH) as f:
            key = f.readline().strip()
            if key:
                return key
    except (FileNotFoundError, PermissionError, OSError):
        pass
    return "DEMO_KEY"


def api_get(path, params=None):
    """Make a GET request to the FDC API."""
    api_key = read_api_key()
    url = f"{BASE_URL}{path}"
    qs = {"api_key": api_key}
    if params:
        qs.update(params)
    # Handle array params: pass them as comma-separated or repeated
    encoded = urllib.parse.urlencode(qs, doseq=True)
    full_url = f"{url}?{encoded}"

    try:
        req = urllib.request.Request(full_url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Request failed: {e.reason}", file=sys.stderr)
        sys.exit(1)


def api_post(path, body):
    """Make a POST request to the FDC API."""
    api_key = read_api_key()
    url = f"{BASE_URL}{path}?api_key={api_key}"
    data = json.dumps(body).encode()

    try:
        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Request failed: {e.reason}", file=sys.stderr)
        sys.exit(1)


def cmd_search(args):
    """Search foods by keyword."""
    params = {"query": args.query}
    if args.data_type:
        params["dataType"] = args.data_type
    if args.page_size:
        params["pageSize"] = args.page_size
    if args.page_number:
        params["pageNumber"] = args.page_number
    if args.sort_by:
        params["sortBy"] = args.sort_by
    if args.sort_order:
        params["sortOrder"] = args.sort_order
    if args.brand_owner:
        params["brandOwner"] = args.brand_owner

    result = api_get("/foods/search", params)
    print(json.dumps(result, indent=2))


def cmd_get(args):
    """Get a single food item by FDC ID."""
    params = {}
    if args.format:
        params["format"] = args.format
    if args.nutrients:
        params["nutrients"] = args.nutrients

    result = api_get(f"/food/{args.fdc_id}", params)
    print(json.dumps(result, indent=2))


def cmd_get_multi(args):
    """Get multiple food items by FDC IDs."""
    params = {"fdcIds": args.fdc_ids}
    if args.format:
        params["format"] = args.format
    if args.nutrients:
        params["nutrients"] = args.nutrients

    result = api_get("/foods", params)
    print(json.dumps(result, indent=2))


def cmd_list(args):
    """List foods in abridged format."""
    params = {}
    if args.data_type:
        params["dataType"] = args.data_type
    if args.page_size:
        params["pageSize"] = args.page_size
    if args.page_number:
        params["pageNumber"] = args.page_number
    if args.sort_by:
        params["sortBy"] = args.sort_by
    if args.sort_order:
        params["sortOrder"] = args.sort_order

    result = api_get("/foods/list", params)
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Food Data Central (FDC) API CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  fdc search "cheddar cheese"
  fdc search "apple" --data-type Foundation --page-size 5
  fdc get 534358 --format full
  fdc get 534358 --nutrients 203,204,205
  fdc get-multi 534358 373052 616350
  fdc list --data-type "SR Legacy" Foundation --page-size 20
  fdc list --sort-by lowercaseDescription.keyword --sort-order asc
        """,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # search
    p = sub.add_parser("search", help="Search foods by keyword")
    p.add_argument("query", help="Search query (e.g. 'cheddar cheese')")
    p.add_argument("--data-type", nargs="+", choices=["Branded", "Foundation", "Survey (FNDDS)", "SR Legacy"],
                   help="Filter by data type(s)")
    p.add_argument("--page-size", type=int, default=None, help="Results per page (1-200)")
    p.add_argument("--page-number", type=int, default=None, help="Page number")
    p.add_argument("--sort-by", default=None,
                   choices=["dataType.keyword", "lowercaseDescription.keyword", "fdcId", "publishedDate"],
                   help="Sort field")
    p.add_argument("--sort-order", default=None, choices=["asc", "desc"], help="Sort direction")
    p.add_argument("--brand-owner", default=None, help="Filter by brand owner (Branded foods only)")
    p.set_defaults(func=cmd_search)

    # get
    p = sub.add_parser("get", help="Get a single food item by FDC ID")
    p.add_argument("fdc_id", help="FDC ID of the food item")
    p.add_argument("--format", choices=["abridged", "full"], default=None, help="Response format")
    p.add_argument("--nutrients", default=None, help="Comma-separated nutrient numbers (e.g. 203,204)")
    p.set_defaults(func=cmd_get)

    # get-multi
    p = sub.add_parser("get-multi", help="Get multiple food items by FDC IDs")
    p.add_argument("fdc_ids", nargs="+", help="FDC IDs (up to 20)")
    p.add_argument("--format", choices=["abridged", "full"], default=None, help="Response format")
    p.add_argument("--nutrients", default=None, help="Comma-separated nutrient numbers (e.g. 203,204)")
    p.set_defaults(func=cmd_get_multi)

    # list
    p = sub.add_parser("list", help="List foods in abridged format")
    p.add_argument("--data-type", nargs="+", choices=["Branded", "Foundation", "Survey (FNDDS)", "SR Legacy"],
                   help="Filter by data type(s)")
    p.add_argument("--page-size", type=int, default=None, help="Results per page (1-200)")
    p.add_argument("--page-number", type=int, default=None, help="Page number")
    p.add_argument("--sort-by", default=None,
                   choices=["dataType.keyword", "lowercaseDescription.keyword", "fdcId", "publishedDate"],
                   help="Sort field")
    p.add_argument("--sort-order", default=None, choices=["asc", "desc"], help="Sort direction")
    p.set_defaults(func=cmd_list)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
