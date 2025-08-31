#!/usr/bin/env python3
"""
Upload previously downloaded product images to Supabase Storage, preserving paths.

- Reads from: storage-migration/product-images/
- Uploads to bucket: product-images
- Uses Supabase Storage HTTP API with service role key (no extra deps)

Auth/env required:
  SUPABASE_URL = e.g. https://xyzcompany.supabase.co
  SUPABASE_SERVICE_ROLE_KEY = service role key with storage write access

Usage:
  python3 storage-migration/upload_product_images_to_storage.py \
    --base-dir storage-migration/product-images \
    --bucket product-images \
    --concurrency 8

Notes:
- Idempotent: sets X-Upsert: true, so re-runs won't error.
- Determines content-type by file extension (png, jpg/jpeg, webp, gif; default image/jpeg).
- Skips empty (size=0) files.
"""

import argparse
import concurrent.futures
import mimetypes
import os
import sys
import urllib.request
import urllib.parse
from typing import Optional, Tuple

DEFAULT_BASE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'storage-migration', 'product-images')


def load_env_file(path: str) -> None:
    """Minimal .env parser: KEY=VALUE pairs, ignores comments and empty lines."""
    try:
        if not os.path.isfile(path):
            return
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' not in line:
                    continue
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                # Do not override if already set in environment
                if key and key not in os.environ:
                    os.environ[key] = val
    except Exception:
        # Best-effort; ignore env file errors
        pass


def guess_content_type(path: str) -> str:
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.png',):
        return 'image/png'
    if ext in ('.gif',):
        return 'image/gif'
    if ext in ('.webp',):
        return 'image/webp'
    if ext in ('.jpg', '.jpeg', '.jpe'):
        return 'image/jpeg'
    # Fallback to mimetypes
    guess, _ = mimetypes.guess_type(path)
    return guess or 'application/octet-stream'


def build_public_url(base_url: str, bucket: str, rel_path: str) -> str:
    # Public URL follows /storage/v1/object/public/<bucket>/<rel_path>
    rel = rel_path.replace('\\', '/')
    return f"{base_url.rstrip('/')}/storage/v1/object/public/{bucket}/{urllib.parse.quote(rel)}"


def upload_one(base_url: str, key: str, bucket: str, abs_path: str, rel_path: str) -> Tuple[str, bool, Optional[str]]:
    try:
        if not os.path.isfile(abs_path):
            return rel_path, False, 'not a file'
        size = os.path.getsize(abs_path)
        if size <= 0:
            return rel_path, False, 'empty file'

        with open(abs_path, 'rb') as f:
            data = f.read()
        content_type = guess_content_type(abs_path)

        # PUT /storage/v1/object/<bucket>/<path>
        url = f"{base_url.rstrip('/')}/storage/v1/object/{bucket}/{urllib.parse.quote(rel_path)}"
        req = urllib.request.Request(url=url, data=data, method='POST')
        # Supabase Storage supports POST for upload (and PUT in some envs); using POST here.
        # Add upsert header to be idempotent
        req.add_header('x-upsert', 'true')
        req.add_header('Content-Type', content_type)
        req.add_header('Authorization', f"Bearer {key}")
        req.add_header('apikey', key)
        with urllib.request.urlopen(req, timeout=60) as resp:
            if 200 <= resp.status < 300:
                return rel_path, True, None
            return rel_path, False, f"status {resp.status}"
    except Exception as e:
        return rel_path, False, str(e)


def gather_files(base_dir: str):
    for root, _, files in os.walk(base_dir):
        for name in files:
            abs_path = os.path.join(root, name)
            # rel_path relative to base_dir
            rel_path = os.path.relpath(abs_path, base_dir)
            rel_path = rel_path.replace('\\', '/')
            yield abs_path, rel_path


def main():
    parser = argparse.ArgumentParser(description='Upload product images to Supabase Storage')
    parser.add_argument('--base-dir', default=DEFAULT_BASE_DIR, help='Local base dir containing product-images')
    parser.add_argument('--bucket', default='product-images', help='Supabase Storage bucket name')
    parser.add_argument('--concurrency', type=int, default=8, help='Parallel uploads')
    parser.add_argument('--env-file', default=os.path.join(os.path.dirname(__file__), '.env'), help='Path to .env file with SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY')
    parser.add_argument('--dry-run', action='store_true', help='List files without uploading')
    args = parser.parse_args()

    base_dir = args.base_dir
    bucket = args.bucket

    # Load env file before reading variables
    if args.env_file:
        load_env_file(args.env_file)

    SUPABASE_URL = os.environ.get('SUPABASE_URL')
    SERVICE_ROLE_KEY = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

    if not os.path.isdir(base_dir):
        print(f"[ERROR] Base dir not found: {base_dir}", file=sys.stderr)
        return 2

    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("[ERROR] SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in environment.", file=sys.stderr)
        return 2

    files = list(gather_files(base_dir))
    total = len(files)
    if total == 0:
        print("[INFO] No files to upload.")
        return 0

    print(f"Uploading {total} files from {base_dir} to bucket '{bucket}' @ {SUPABASE_URL}")

    if args.dry_run:
        for _, rel in files[:20]:
            print(f"[DRY] {rel}")
        if total > 20:
            print(f"[DRY] ... and {total-20} more")
        return 0

    ok = 0
    fail = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
        futures = [
            ex.submit(upload_one, SUPABASE_URL, SERVICE_ROLE_KEY, bucket, abs_path, rel)
            for abs_path, rel in files
        ]
        for fut in concurrent.futures.as_completed(futures):
            rel, success, err = fut.result()
            if success:
                ok += 1
                print(f"[OK] {rel}")
            else:
                fail += 1
                print(f"[FAIL] {rel} :: {err}")

    print("\n=== Summary ===")
    print(f"Uploaded: {ok}")
    print(f"Failed:   {fail}")
    print(f"Bucket:   {bucket}")
    print(f"Public base: {SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{bucket}/<path>")

    return 0 if fail == 0 else 2


if __name__ == '__main__':
    sys.exit(main())
