#!/usr/bin/env python3
"""Read-only staging smoke checks; uses only the public SDK key, no test users."""
import json
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

cfg = json.loads(Path('config/staging-backend.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
if urlparse(base).hostname != 'cbkmxtplhcdomyeyrwyi.supabase.co':
    raise SystemExit('Expected petfriendly-staging')
key = cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY']


def status(path, data=None):
    req = urllib.request.Request(base + '/rest/v1/' + path,
        method='POST' if data is not None else 'GET',
        headers={'apikey': key, 'Content-Type': 'application/json'},
        data=json.dumps(data).encode() if data is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            return response.status
    except urllib.error.HTTPError as error:
        payload = json.loads(error.read())
        if error.code in (401, 403) and payload.get('code') != '42501':
            raise AssertionError('Unexpected auth failure for ' + path)
        return error.code


routes = [
    ('rpc/my_account_mode', {}), ('rpc/set_account_role', {'role_in': 'both'}),
    ('rpc/switch_account_mode', {'mode_in': 'helper'}), ('rpc/owner_stats', {}),
    ('rpc/my_walks', {}), ('rpc/search_walk_requests', {'city_in': 'Минск'}),
    ('rpc/walk_private_details', {'request_in': '00000000-0000-0000-0000-000000000000'}),
    ('rpc/review_walk_owner', {'request_in': '00000000-0000-0000-0000-000000000000', 'rating_in': 5}),
    ('walk_owner_reviews?limit=1', None), ('walking_helper_profiles?limit=1', None),
]
for path, data in routes:
    code = status(path, data)
    if code not in (401, 403):
        raise AssertionError('Expected anonymous access denied for ' + path + ', HTTP ' + str(code))
    print('PASS anonymous access denied: ' + path.split('?')[0])
if status('places?select=id&limit=1') != 200:
    raise AssertionError('Public place catalog unavailable')
print('PASS existing public place catalog remains available')
print('All 11 read-only staging checks passed')
