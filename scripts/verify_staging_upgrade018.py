#!/usr/bin/env python3
"""Bounded staging API smoke checks; never read real chats or modify real places.

Positive member/message and moderator publication flows are covered by the
local integration suites. This script checks cloud deployment and denials using
one disposable synthetic account, nonexistent object IDs and catalog reads.
"""
import json
import secrets
import urllib.error
import urllib.request
import uuid
from pathlib import Path

cfg = json.loads(Path('config/staging-backend.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
if base != 'https://cbkmxtplhcdomyeyrwyi.supabase.co':
    raise SystemExit('Wrong staging project')
public_key, admin_key = cfg['PUBLISHABLE_KEY'], cfg['SERVICE_ROLE_KEY']
checks = 0
user_id = None


def call(path, data=None, token=None, admin=False, method=None):
    headers = {'apikey': admin_key if admin else public_key,
               'Content-Type': 'application/json'}
    if token or admin:
        headers['Authorization'] = 'Bearer ' + (admin_key if admin else token)
    request = urllib.request.Request(
        base + path, headers=headers,
        method=method or ('POST' if data is not None else 'GET'),
        data=json.dumps(data).encode() if data is not None else None)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        # Never print auth payloads, tokens, identifiers or response bodies.
        return error.code, None


def check(ok, label):
    global checks
    if not ok:
        raise AssertionError(label)
    checks += 1
    print('PASS ' + label, flush=True)


def rpc(name, data, token=None):
    return call('/rest/v1/rpc/' + name, data, token)


try:
    email = 'stage-upgrade018-' + secrets.token_hex(8) + '@example.test'
    password = secrets.token_urlsafe(24)
    code, user = call('/auth/v1/admin/users', {
        'email': email, 'password': password, 'email_confirm': True}, admin=True)
    check(code in (200, 201), 'create disposable staging account')
    user_id = user['id']
    code, session = call('/auth/v1/token?grant_type=password', {
        'email': email, 'password': password})
    check(code == 200, 'synthetic account signs in')
    token = session['access_token']
    absent = str(uuid.uuid4())

    check(rpc('chat_inbox', {'conversation_ids': []}, token) == (200, []),
          'deployed inbox returns own genuinely empty list')
    check(rpc('chat_inbox', {'conversation_ids': [absent]}, token) == (200, []),
          'inbox does not invent inaccessible conversations')
    check(rpc('chat_inbox', {'conversation_ids': []})[0] == 401,
          'anonymous inbox invocation denied')
    check(rpc('chat_inbox', {'conversation_ids': [absent] * 101}, token)[0] == 400,
          'cloud inbox summary bound enforced')
    check(rpc('mark_conversation_read', {
        'conversation_in': absent, 'message_in': absent}, token)[0] == 403,
          'read acknowledgement requires membership')
    check(call('/rest/v1/conversation_reads', token=token) == (200, []),
          'new account has no private read cursors')
    check(call('/rest/v1/conversation_reads', {
        'conversation_id': absent, 'user_id': user_id,
        'last_read_at': '2026-01-01T00:00:00Z', 'last_read_id': absent}, token)[0] == 403,
          'direct read-cursor writes denied')
    code, exported = rpc('export_my_data', {}, token)
    check(code == 200 and exported.get('conversation_reads') == [],
          'recent-auth export preserves contract and includes own cursors')

    check(call('/rest/v1/walk_reviews?select=id,helper_reply,replied_at&limit=0',
               token=token)[0] == 200, 'reply columns are exposed in cloud schema')
    check(rpc('reply_walk_review', {'review_in': absent, 'body_in': 'Synthetic'},
              token)[0] == 403, 'ineligible helper reply denied')
    check(rpc('reply_walk_review', {'review_in': absent, 'body_in': ' '},
              token)[0] == 400, 'empty helper reply rejected')
    check(rpc('reply_walk_review', {'review_in': absent, 'body_in': 'x' * 1001},
              token)[0] == 400, 'oversized helper reply rejected')

    check(call('/rest/v1/events?select=time_zone&limit=0', token=token)[0] == 200,
          'event timezone column deployed')
    check(call('/rest/v1/walk_requests?select=time_zone&limit=0', token=token)[0] == 200,
          'walk timezone column deployed')
    event = {'title_in': 'Synthetic invalid venue', 'city_in': 'Гродно',
             'starts_in': '2999-01-01T12:00:00Z', 'capacity_in': 2,
             'timezone_in': 'Europe/Warsaw'}
    check(rpc('create_event_at_zone', event, token)[0] == 400,
          'cloud rejects Belarus venue timezone mismatch before write')
    check(rpc('create_event_at_zone', event | {'timezone_in': 'invalid/zone'},
              token)[0] == 400, 'cloud rejects invalid IANA zone')
    check(rpc('create_event_at_zone', event | {'timezone_in': None}, token)[0] == 400,
          'new event API requires explicit zone')
    check(rpc('create_walk_at_zone', {
        'pet_in': absent, 'city_in': 'Минск', 'starts_in': '2999-01-01T12:00:00Z',
        'duration_in': 45, 'timezone_in': 'invalid/zone'}, token)[0] == 400,
          'new walk API validates zone before write')

    code, page = rpc('search_places', {'city_in': 'Минск'}, token)
    check(code == 200 and page['total'] == 130 and len(page['items']) == 40,
          'catalog total and bounded pagination preserved')
    check(all('pet_access_evidence' in place for place in page['items']),
          'cloud catalog includes separate evidence field')
    check(all(place['pet_access_evidence'] is None for place in page['items']),
          'migration does not fabricate pet-access confirmations')
    check(call('/rest/v1/place_pet_access_evidence?limit=1')[0] == 200,
          'public evidence endpoint available without personal identities')
    check(rpc('city_place_pet_access', {'city_in': 'Минск'}, token) == (200, []),
          'city evidence returns genuinely unconfirmed state')
    check(rpc('city_place_pet_access', {'city_in': 'Минск'})[0] == 401,
          'anonymous city evidence RPC denied')
    check(rpc('city_place_pet_access', {'city_in': ' '}, token)[0] == 400,
          'city evidence validates city')
    publish = {'place_in': absent, 'confirmation_in': 'community',
               'policy_in': 'allowed', 'observed_in': '2026-01-01T00:00:00Z',
               'basis_in': 'Synthetic unauthorized publication'}
    check(rpc('publish_place_pet_access', publish, token)[0] == 403,
          'ordinary user cannot publish pet-access evidence')
    check(rpc('withdraw_place_pet_access', {'place_in': absent}, token)[0] == 403,
          'ordinary user cannot withdraw pet-access evidence')
    check(call('/rest/v1/place_pet_access_evidence', {
        'place_id': absent, 'confirmation': 'community', 'policy': 'allowed',
        'observed_at': '2026-01-01T00:00:00Z', 'basis': 'Synthetic'}, token)[0] == 403,
          'direct evidence writes denied')

    check(rpc('revoke_my_sessions', {}, token)[0] == 204, 'revoke synthetic session')
    for name, payload in [('chat_inbox', {'conversation_ids': []}),
                          ('city_place_pet_access', {'city_in': 'Минск'}),
                          ('search_places', {'city_in': 'Минск'}),
                          ('create_event_at_zone', event),
                          ('reply_walk_review', {'review_in': absent, 'body_in': 'Synthetic'}),
                          ('publish_place_pet_access', publish)]:
        check(rpc(name, payload, token)[0] == 403,
              'revoked existing JWT denied by ' + name)
finally:
    if user_id:
        code, _ = call('/auth/v1/admin/users/' + user_id, admin=True, method='DELETE')
        check(code == 200, 'synthetic staging account cleaned up')
print('All ' + str(checks) + ' staging upgrade API checks passed')
