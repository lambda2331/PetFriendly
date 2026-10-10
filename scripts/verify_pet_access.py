#!/usr/bin/env python3
"""Synthetic pet-access evidence authorization checks; LOCAL backend only."""
import base64
import hashlib
import hmac
import json
import os
import secrets
import struct
import subprocess
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

cfg = json.loads(Path('config/backend-status.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
pub = cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY']
admin = cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):
    raise SystemExit('Local endpoint required')
users = []
places = []
checks = 0


def call(path, method='GET', data=None, token=None, staff=False):
    key = admin if staff else pub
    req = urllib.request.Request(base + path, method=method, headers={
        'apikey': key, 'Authorization': 'Bearer ' + (key if staff else token or pub),
        'Content-Type': 'application/json',
    }, data=json.dumps(data).encode() if data is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raw = error.read()
        return error.code, json.loads(raw) if raw else None


def check(ok, label):
    global checks
    if not ok:
        raise AssertionError(label)
    checks += 1
    print('PASS ' + label)


def fixture():
    email = 'pet-rules-' + secrets.token_hex(6) + '@example.test'
    password = secrets.token_urlsafe(24)
    code, user = call('/auth/v1/admin/users', 'POST', {
        'email': email, 'password': password, 'email_confirm': True,
    }, staff=True)
    check(code in (200, 201), 'create synthetic account')
    users.append(user['id'])
    code, session = call('/auth/v1/token?grant_type=password', 'POST', {
        'email': email, 'password': password,
    })
    check(code == 200, 'sign in synthetic account')
    return user['id'], session['access_token']


def evidence(pid, token=None):
    return call('/rest/v1/place_pet_access_evidence?place_id=eq.' + pid, token=token)


def publish(pid, token=None, **changes):
    body = {'place_in': pid, 'confirmation_in': 'community', 'policy_in': 'on_leash',
            'observed_in': '2026-01-01T12:00:00Z',
            'basis_in': 'Синтетическое подтверждение правил публичного места',
            'conditions_in': 'Синтетическое условие: поводок', 'reference_in': ''}
    body.update(changes)
    return call('/rest/v1/rpc/publish_place_pet_access', 'POST', body, token)


def search(pid, token, access):
    return call('/rest/v1/rpc/search_places', 'POST', {
        'city_in': 'Минск', 'favorites_in': [pid], 'access_in': access,
    }, token)


def mfa(token):
    code, factor = call('/auth/v1/factors', 'POST', {
        'factor_type': 'totp', 'friendly_name': 'Synthetic pet access test',
    }, token)
    check(code == 200, 'enroll synthetic moderator MFA')
    fid = factor['id']
    secret = factor['totp']['secret']
    code, challenge = call('/auth/v1/factors/' + fid + '/challenge', 'POST', {}, token)
    check(code == 200, 'challenge synthetic moderator MFA')
    key = base64.b32decode(secret + '=' * ((-len(secret)) % 8))
    digest = hmac.new(key, struct.pack('>Q', int(time.time()) // 30), hashlib.sha1).digest()
    offset = digest[-1] & 15
    otp = str((struct.unpack('>I', digest[offset:offset + 4])[0] & 0x7fffffff) % 1000000).zfill(6)
    code, verified = call('/auth/v1/factors/' + fid + '/verify', 'POST', {
        'challenge_id': challenge['id'], 'code': otp,
    }, token)
    check(code == 200, 'verify synthetic moderator MFA')
    return verified['access_token']


try:
    user, token = fixture()
    mod, mod_token = fixture()
    pid = str(uuid.uuid4())
    code, _ = call('/rest/v1/places', 'POST', {
        'id': pid, 'source': 'community', 'source_id': 'pet-rules-fixture:' + pid,
        'name': 'Синтетическое место', 'category': 'Парк', 'city': 'Минск',
        'latitude': 53.9, 'longitude': 27.56, 'pet_access': 'yes',
    }, staff=True)
    check(code == 201, 'create synthetic public place with a catalog allow tag')
    places.append(pid)
    check(evidence(pid) == (200, []), 'catalog allow tag does not fabricate confirmation')
    check(search(pid, token, 'unknown')[1]['total'] == 1,
          'unconfirmed filter includes places with mere catalog tags')
    check(publish(pid)[0] >= 400, 'anonymous cannot publish rules')
    check(publish(pid, token)[0] == 403, 'ordinary account cannot publish confirmation')
    check(call('/rest/v1/place_pet_access_evidence', 'POST', {
        'place_id': pid, 'confirmation': 'venue', 'policy': 'allowed',
        'observed_at': '2026-01-01T00:00:00Z', 'basis': 'Synthetic spoof',
        'reference_url': 'https://example.test/rules',
    }, token)[0] >= 400, 'ordinary client cannot insert confirmation directly')
    env = {**os.environ, 'DOCKER_HOST': 'unix:///Users/artem.dudinskij/.colima/petfriendly/docker.sock'}
    subprocess.run(['docker', 'exec', 'supabase_db_PetFriendly', 'psql', '-U', 'postgres',
                    '-d', 'postgres', '-c', "update private.accounts set moderator=true where id='" + str(uuid.UUID(mod)) + "'"],
                   env=env, check=True, stdout=subprocess.DEVNULL)
    check(publish(pid, mod_token)[0] == 403, 'moderator without MFA cannot confirm rules')
    verified = mfa(mod_token)
    check(publish(pid, verified, observed_in='2999-01-01T00:00:00Z')[0] >= 400,
          'future observation cannot be fabricated')
    check(publish(pid, verified, basis_in=' ')[0] >= 400, 'confirmation requires a real documented basis')
    check(publish(pid, verified, confirmation_in='osm')[0] >= 400, 'OSM cannot masquerade as verified evidence source')
    check(publish(pid, verified, confirmation_in='venue')[0] >= 400, 'venue confirmation requires public reference')
    check(publish(pid, verified, confirmation_in='venue', reference_in='http://example.test/rules')[0] >= 400,
          'venue reference requires HTTPS')
    check(publish(pid, verified)[0] in (200, 204), 'MFA moderator publishes real synthetic community evidence')
    code, rows = evidence(pid)
    check(code == 200 and rows[0]['confirmation'] == 'community' and rows[0]['policy'] == 'on_leash',
          'public row shows confirmed source and precise policy')
    check(rows[0]['conditions'] == 'Синтетическое условие: поводок' and rows[0]['observed_at'] is not None,
          'actual conditions and observation date are retained')
    check(not any(k in rows[0] for k in ['author_id', 'moderator_id', 'user_id']),
          'public evidence never exposes person identities')
    check(search(pid, token, 'unknown')[1]['total'] == 0,
          'unconfirmed filter excludes genuinely confirmed rules')
    check(search(pid, token, 'all')[1]['items'][0]['pet_access_evidence']['confirmation'] == 'community',
          'bounded catalog page includes separately verified evidence')
    linked_city = 'evidence-city-' + secrets.token_hex(6)
    code, _ = call('/rest/v1/city_catalog_places', 'POST', {
        'city_key': linked_city, 'place_id': pid,
    }, staff=True)
    check(code == 201, 'link synthetic place into a different selected city catalog')
    code, linked = call('/rest/v1/rpc/city_place_pet_access', 'POST', {
        'city_in': linked_city.upper(),
    }, token)
    check(code == 200 and len(linked) == 1 and linked[0]['place_id'] == pid,
          'city evidence includes linked venues regardless of original city spelling')
    check(call('/rest/v1/rpc/city_place_pet_access', 'POST', {
        'city_in': linked_city,
    })[0] >= 400, 'anonymous cannot call authenticated city evidence RPC')
    check(publish(pid, verified, confirmation_in='venue', policy_in='forbidden',
                  reference_in='https://example.test/rules')[0] in (200, 204),
          'MFA moderator can replace community evidence with venue prohibition')
    check(evidence(pid)[1][0]['policy'] == 'forbidden', 'confirmation never implies permission')
    check(search(pid, token, 'taggedAllowed')[1]['total'] == 0,
          'confirmed prohibition overrides an old catalog allowance')
    check(call('/rest/v1/place_pet_access_evidence?place_id=eq.' + pid, 'PATCH', {
        'policy': 'allowed'}, verified)[0] >= 400, 'even moderator cannot bypass publication RPC')
    call('/rest/v1/places?id=eq.' + pid, 'PATCH', {'published': False}, staff=True)
    check(evidence(pid) == (200, []), 'hidden place evidence is not public')
    check(call('/rest/v1/rpc/city_place_pet_access', 'POST', {
        'city_in': linked_city,
    }, token) == (200, []), 'city evidence excludes hidden linked venues')
    check(publish(pid, verified)[0] >= 400, 'hidden place cannot receive public confirmation')
    call('/rest/v1/places?id=eq.' + pid, 'PATCH', {'published': True}, staff=True)
    check(call('/rest/v1/rpc/withdraw_place_pet_access', 'POST', {'place_in': pid}, token)[0] == 403,
          'ordinary account cannot withdraw evidence')
    check(call('/rest/v1/rpc/withdraw_place_pet_access', 'POST', {'place_in': pid}, verified)[0] in (200, 204),
          'MFA moderator can withdraw inaccurate evidence')
    check(evidence(pid) == (200, []), 'withdrawal restores genuinely unconfirmed state')
    publish(pid, verified)
    call('/rest/v1/rpc/revoke_my_sessions', 'POST', {}, verified)
    check(publish(pid, verified)[0] == 403, 'revoked moderator JWT cannot publish evidence')
    check(evidence(pid, verified) == (200, []), 'revoked authenticated JWT sees no evidence through RLS')
    check(call('/rest/v1/rpc/city_place_pet_access', 'POST', {
        'city_in': linked_city,
    }, verified)[0] == 403, 'revoked existing JWT cannot call city evidence RPC')
    check(evidence(pid, token)[0] == 200 and len(evidence(pid, token)[1]) == 1,
          'active ordinary account can read public evidence')
    call('/rest/v1/places?id=eq.' + pid, 'DELETE', staff=True)
    check(evidence(pid) == (200, []), 'venue deletion cascades to public evidence')
finally:
    for pid in places:
        call('/rest/v1/places?id=eq.' + pid, 'DELETE', staff=True)
    for uid in users:
        call('/auth/v1/admin/users/' + uid, 'DELETE', staff=True)
print('All ' + str(checks) + ' pet-access checks passed')
