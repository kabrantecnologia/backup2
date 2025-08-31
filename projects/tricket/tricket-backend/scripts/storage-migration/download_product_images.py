#!/usr/bin/env python3
"""
Download product images listed in a CSV, preserving the original storage path structure.

- Reads: /home/joaohenrique/workspaces/projects/tricket/storage-migration/marketplace_product_images_rows.csv
- Looks for URLs containing '/storage/v1/object/public/product-images/' in any column
- Downloads to: /home/joaohenrique/workspaces/projects/tricket/storage-migration/product-images/
  maintaining the path after 'product-images/' from the URL.

Example URL:
https://api.staging.tricket.com.br/storage/v1/object/public/product-images/78ecec56-30d7-4d1a-a9d5-e9522cd1a3e1/78ecec56-30d7-4d1a-a9d5-e9522cd1a3e1-1754330581243-0.png

Saved as:
product-images/78ecec56-30d7-4d1a-a9d5-e9522cd1a3e1/78ecec56-30d7-4d1a-a9d5-e9522cd1a3e1-1754330581243-0.png
"""

import csv
import os
import sys
import time
import urllib.parse
import urllib.request
from typing import Optional, Tuple

CSV_PATH = \
    "/home/joaohenrique/workspaces/projects/tricket/storage-migration/marketplace_product_images_rows.csv"
OUT_BASE_DIR = \
    "/home/joaohenrique/workspaces/projects/tricket/storage-migration/product-images"
BUCKET_MARKER = "/storage/v1/object/public/product-images/"


def extract_rel_path(url: str) -> Optional[str]:
    """Return the relative path inside the 'product-images' bucket or None if not match."""
    if not url:
        return None
    try:
        # Ensure it's a URL string
        url = url.strip()
        if not url:
            return None
        # Unquote to handle any encoded characters
        unquoted = urllib.parse.unquote(url)
        idx = unquoted.find(BUCKET_MARKER)
        if idx == -1:
            return None
        rel = unquoted[idx + len(BUCKET_MARKER):]
        # Basic sanitize: avoid directory traversal
        rel = rel.lstrip("/")
        if rel.startswith(".."):
            return None
        return rel
    except Exception:
        return None


def safe_download(url: str, dest_path: str, *, timeout: int = 30, retries: int = 3, backoff: float = 1.5) -> Tuple[bool, Optional[str]]:
    """Download a single URL to dest_path with retries. Returns (ok, error)."""
    # Skip if already present
    if os.path.exists(dest_path) and os.path.getsize(dest_path) > 0:
        return True, None

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    last_err = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers={
                "User-Agent": "tricket-storage-migration/1.0",
                "Accept": "*/*",
            })
            with urllib.request.urlopen(req, timeout=timeout) as resp, open(dest_path, "wb") as f:
                # Stream in chunks
                while True:
                    chunk = resp.read(1024 * 64)
                    if not chunk:
                        break
                    f.write(chunk)
            return True, None
        except Exception as e:
            last_err = str(e)
            # Small backoff before retry
            time.sleep(backoff ** attempt)
    # On failure, cleanup partial file
    try:
        if os.path.exists(dest_path) and os.path.getsize(dest_path) == 0:
            os.remove(dest_path)
    except Exception:
        pass
    return False, last_err


def find_url_in_row(row: dict) -> Optional[str]:
    """Try to locate a product image URL in any column of the row."""
    for k, v in row.items():
        if not v:
            continue
        s = str(v)
        if BUCKET_MARKER in s:
            return s.strip()
    return None


def main(csv_path: str = CSV_PATH, out_base: str = OUT_BASE_DIR) -> int:
    if not os.path.isfile(csv_path):
        print(f"[ERROR] CSV not found: {csv_path}", file=sys.stderr)
        return 1

    total = 0
    matched = 0
    downloaded = 0
    skipped = 0
    failed = 0

    # Ensure base dir exists
    os.makedirs(out_base, exist_ok=True)

    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            total += 1
            url = find_url_in_row(row)
            if not url:
                continue
            matched += 1
            rel = extract_rel_path(url)
            if not rel:
                print(f"[WARN] Could not extract rel path from URL: {url}")
                continue

            dest_path = os.path.join(out_base, rel)

            ok, err = safe_download(url, dest_path)
            if ok:
                if os.path.exists(dest_path) and os.path.getsize(dest_path) > 0:
                    # Count as downloaded or skipped depending on pre-existence
                    if os.path.getmtime(dest_path) < time.time() - 1:  # heuristic; treat as success
                        downloaded += 1
                    else:
                        downloaded += 1
                else:
                    downloaded += 1
                print(f"[OK] {url} -> {dest_path}")
            else:
                failed += 1
                print(f"[FAIL] {url} -> {dest_path} :: {err}")

    print("\n=== Summary ===")
    print(f"Rows read:       {total}")
    print(f"URLs matched:    {matched}")
    print(f"Downloaded:      {downloaded}")
    print(f"Failed:          {failed}")
    print(f"Output base dir: {out_base}")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
