#!/usr/bin/env python3
"""Check venue timezone persistence and authorization using local synthetic data."""
import json
import secrets
import urllib.request
import urllib.error
from datetime import datetime, timedelta, timezone
from pathlib import Path

cfg = json.loads(Path('config/backend-status.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
if not base.startswith(('http://127.0.0.1:', 'http://localhost:')):
    raise SystemExit('Local endpoint required')
pub = cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY']
admin = cfg['SERVICE_ROLE_KEY']
users, events = [], []
checks = 0

def call(path, method='GET', data=None, token=None, staff=False):
    key = admin if staff else pub
    req = urllib.request.Request(base + path, method=method, headers={
        'apikey': key, 'Authorization': 'Bearer ' + (key if staff else token or pub),
        'Content-Type': 'application/json', 'Prefer': 'return=representation',
    }, data=json.dumps(data).encode() if data is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raw = error.read()
        return error.code, json.loads(raw) if raw else None

def check(ok, name):
    global checks
    if not ok:
        raise AssertionError(name)
    checks += 1
    print('PASS ' + name)

try:
    email = 'venue-' + secrets.token_hex(6) + '@example.test'
    password = secrets.token_urlsafe(24)
    code, user = call('/auth/v1/admin/users', 'POST', {
        'email': email, 'password': password, 'email_confirm': True,
    }, staff=True)
    check(code in (200, 201), 'create synthetic owner')
    users.append(user['id'])
    code, session = call('/auth/v1/token?grant_type=password', 'POST', {'email': email, 'password': password})
    check(code == 200, 'sign in synthetic owner')
    token = session['access_token']
    future = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
    payload = {'title_in': 'Synthetic venue time', 'city_in': 'Гродно',
        'starts_in': future, 'capacity_in': 2, 'timezone_in': 'Europe/Minsk'}
    code, eid = call('/rest/v1/rpc/create_event_at_zone', 'POST', payload, token)
    check(code == 200, 'create event with venue timezone')
    events.append(eid)
    code, rows = call('/rest/v1/events?id=eq.' + eid, token=token)
    check(rows[0]['time_zone'] == 'Europe/Minsk', 'non-Minsk launch city has venue timezone')
    check(datetime.fromisoformat(rows[0]['starts_at']) == datetime.fromisoformat(future), 'venue metadata preserves instant')
    check(call('/rest/v1/rpc/create_event_at_zone', 'POST', payload | {'timezone_in': 'Europe/Warsaw'}, token)[0] >= 400, 'launch-city timezone mismatch rejected')
    check(call('/rest/v1/rpc/create_event_at_zone', 'POST', payload | {'timezone_in': 'bad/zone'}, token)[0] >= 400, 'invalid timezone rejected server-side')
    check(call('/rest/v1/rpc/create_event_at_zone', 'POST', payload | {'timezone_in': None}, token)[0] >= 400, 'missing timezone rejected on new API')
    code, foreign = call('/rest/v1/rpc/create_event_at_zone', 'POST', payload | {
        'city_in': 'Варшава', 'timezone_in': 'Europe/Warsaw'}, token)
    check(code == 200, 'explicit timezone supports another city')
    events.append(foreign)
    check(call('/rest/v1/events?id=eq.' + foreign, token=token)[1][0]['time_zone'] == 'Europe/Warsaw', 'other city retains chosen timezone')
    code, pets = call('/rest/v1/pets', 'POST', {'owner_id': user['id'], 'name': 'Synthetic pet'}, token)
    check(code == 201, 'create synthetic pet')
    walk = {'pet_in': pets[0]['id'], 'city_in': 'Варшава', 'starts_in': future,
        'duration_in': 45, 'timezone_in': 'Europe/Warsaw'}
    code, rid = call('/rest/v1/rpc/create_walk_at_zone', 'POST', walk, token)
    check(code == 200, 'create walking request with venue zone')
    check(call('/rest/v1/walk_requests?id=eq.' + rid, token=token)[1][0]['time_zone'] == 'Europe/Warsaw', 'walking request persists zone')
    check(call('/rest/v1/rpc/create_walk_at_zone', 'POST', walk)[0] >= 400, 'anonymous venue changes rejected')
    call('/rest/v1/rpc/revoke_my_sessions', 'POST', {}, token)
    check(call('/rest/v1/rpc/create_event_at_zone', 'POST', payload, token)[0] == 403, 'revoked existing JWT cannot create venue event')
    check(call('/rest/v1/rpc/create_walk_at_zone', 'POST', walk, token)[0] == 403, 'revoked existing JWT cannot create venue walk')
finally:
    for eid in events:
        call('/rest/v1/events?id=eq.' + eid, 'DELETE', staff=True)
    for uid in users:
        call('/auth/v1/admin/users/' + uid, 'DELETE', staff=True)
print('All ' + str(checks) + ' venue timezone checks passed')
