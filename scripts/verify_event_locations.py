#!/usr/bin/env python3
"""Local-only event point authorization and atomicity checks, synthetic accounts."""
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
    if not ok: raise AssertionError(name)
    checks += 1
    print('PASS ' + name)

try:
    tokens = []
    for _ in range(2):
        email = 'event-point-' + secrets.token_hex(6) + '@example.test'
        password = secrets.token_urlsafe(24)
        code, user = call('/auth/v1/admin/users', 'POST', {
            'email': email, 'password': password, 'email_confirm': True}, staff=True)
        check(code in (200, 201), 'create synthetic account')
        users.append(user['id'])
        code, session = call('/auth/v1/token?grant_type=password', 'POST',
            {'email': email, 'password': password})
        check(code == 200, 'sign in synthetic account')
        tokens.append(session['access_token'])
    owner, viewer = tokens
    payload = {'title_in': 'Synthetic public meeting', 'city_in': 'Москва',
        'starts_in': (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
        'capacity_in': 8, 'timezone_in': 'Europe/Moscow',
        'latitude_in': 55.75, 'longitude_in': 37.61, 'location_label_in': 'Synthetic park entrance'}
    check(call('/rest/v1/rpc/create_event_at_location', 'POST', payload)[0] >= 400,
        'anonymous point creation denied')
    code, eid = call('/rest/v1/rpc/create_event_at_location', 'POST', payload, owner)
    check(code == 200, 'create meeting with public point')
    events.append(eid)
    row = call('/rest/v1/events?id=eq.' + eid, token=owner)[1][0]
    check(row['latitude'] == 55.75 and row['longitude'] == 37.61, 'coordinates persisted without inversion')
    check(row['location_label'] == payload['location_label_in'] and row['time_zone'] == 'Europe/Moscow',
        'public label and venue zone persisted')
    check(row['owner_id'] == users[0], 'owner derived from session')
    check(call('/rest/v1/events?id=eq.' + eid, 'PATCH', {'latitude': 1}, viewer)[0] >= 400,
        'another user cannot move meeting point')
    before = len(call('/rest/v1/events?owner_id=eq.' + users[0], token=owner)[1])
    for invalid in [{'latitude_in': None}, {'longitude_in': 181}, {'latitude_in': 91},
                    {'latitude_in': 'NaN'}, {'longitude_in': 'Infinity'},
                    {'location_label_in': 'x' * 161}, {'timezone_in': 'bad/zone'}]:
        code, possible_id = call('/rest/v1/rpc/create_event_at_location', 'POST', payload | invalid, owner)
        if code == 200: events.append(possible_id)
        check(code >= 400,
            'invalid point/label/timezone rejected')
    check(len(call('/rest/v1/events?owner_id=eq.' + users[0], token=owner)[1]) == before,
        'failed creations leave no orphan meeting')
    legacy = {k: v for k, v in payload.items() if k not in ('latitude_in','longitude_in','location_label_in')}
    code, legacy_id = call('/rest/v1/rpc/create_event_at_zone', 'POST', legacy, owner)
    check(code == 200, 'creation without map point remains compatible')
    events.append(legacy_id)
    check(call('/rest/v1/events?id=eq.' + legacy_id, token=owner)[1][0]['latitude'] is None,
        'no fabricated coordinates for legacy meeting')
    call('/rest/v1/blocks', 'POST', {'user_id': users[1], 'target_id': users[0]}, viewer)
    check(call('/rest/v1/events?id=eq.' + eid, token=viewer)[1] == [], 'block hides meeting and point')
    call('/rest/v1/rpc/revoke_my_sessions', 'POST', {}, owner)
    check(call('/rest/v1/rpc/create_event_at_location', 'POST', payload, owner)[0] == 403,
        'revoked existing JWT cannot create meeting point')
finally:
    for eid in events:
        call('/rest/v1/conversations?context_id=eq.' + eid, 'DELETE', staff=True)
        call('/rest/v1/events?id=eq.' + eid, 'DELETE', staff=True)
    for uid in users:
        call('/auth/v1/admin/users/' + uid, 'DELETE', staff=True)
print('All ' + str(checks) + ' event location checks passed')
