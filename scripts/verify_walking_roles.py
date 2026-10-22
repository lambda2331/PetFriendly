#!/usr/bin/env python3
"""Local Supabase contract/security checks. Synthetic users, no live personal data."""
import base64
import hashlib
import hmac
import json
import secrets
import struct
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path

cfg = json.loads(Path('config/backend-status.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
if not base.startswith(('http://127.0.0.1:', 'http://localhost:')):
    raise SystemExit('Local endpoint required')
pub = cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY']
admin = cfg['SERVICE_ROLE_KEY']
users, requests = [], []
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


def rpc(name, args, token=None):
    return call('/rest/v1/rpc/' + name, 'POST', args, token)


def check(ok, label):
    global checks
    if not ok:
        raise AssertionError(label)
    checks += 1
    print('PASS ' + label)


def success(result, label):
    check(result[0] in (200, 201, 204), label)
    return result[1]


def denied(result, label):
    check(result[0] >= 400, label)


try:
    tokens = []
    for _ in range(4):
        email = 'walking-role-' + secrets.token_hex(6) + '@example.test'
        password = secrets.token_urlsafe(24)
        user = success(call('/auth/v1/admin/users', 'POST', {
            'email': email, 'password': password, 'email_confirm': True}, staff=True), 'synthetic user created')
        users.append(user['id'])
        session = success(call('/auth/v1/token?grant_type=password', 'POST', {
            'email': email, 'password': password}), 'synthetic user signed in')
        tokens.append(session['access_token'])
    owner, helper, other_helper, viewer = tokens
    denied(rpc('my_account_mode', {}), 'anonymous role access denied')
    initial = success(rpc('my_account_mode', {}, owner), 'legacy-compatible role snapshot')
    check(initial['account_role'] == 'both' and initial['needs_role_selection'], 'new account requests explicit role selection')
    success(rpc('set_account_role', {'role_in': 'owner'}, owner), 'owner role selected')
    for token in [helper, other_helper]:
        result = success(rpc('set_account_role', {'role_in': 'helper'}, token), 'helper role selected')
        check(result['capabilities']['apply_walk'] and not result['capabilities']['create_walk'], 'helper capabilities restricted')
    denied(rpc('set_account_role', {'role_in': 'moderator'}, helper), 'product role cannot elevate to moderator')
    denied(rpc('switch_account_mode', {'mode_in': 'owner'}, helper), 'helper-only mode cannot switch to owner')
    success(call('/auth/v1/user', 'PUT', {'data': {'account_role': 'helper', 'moderator': True}}, owner), 'untrusted auth metadata changed')
    check(rpc('my_account_mode', {}, owner)[1]['account_role'] == 'owner', 'auth metadata does not grant capabilities')
    denied(rpc('moderation_queue', {}, owner), 'auth metadata does not grant moderation')
    denied(call('/rest/v1/product_roles', token=helper), 'private product-role table not exposed')
    both = success(rpc('set_account_role', {'role_in': 'both', 'mode_in': 'helper'}, helper), 'both roles selected')
    check(both['capabilities']['create_walk'] and both['capabilities']['apply_walk'], 'both roles retain both capabilities')
    check(rpc('switch_account_mode', {'mode_in': 'owner'}, helper)[1]['active_mode'] == 'owner', 'both roles switch visible mode')
    success(rpc('set_account_role', {'role_in': 'helper'}, helper), 'helper-only role restored')

    profile = {'city_in': 'Минск', 'time_zone_in': 'Europe/Minsk', 'district_in': 'Первомайский',
        'introduction_in': 'Synthetic helper', 'experience_in': 'Synthetic experience',
        'dog_sizes_in': ['small', 'medium'], 'service_districts_in': ['Первомайский'],
        'availability_in': [{'day': 0, 'start': 540, 'end': 1020}]}
    success(rpc('save_walking_helper_profile', profile, helper), 'helper onboarding works without a pet')
    denied(rpc('save_walking_helper_profile', profile, owner), 'owner-only cannot edit helper profile')
    denied(call('/rest/v1/walking_helper_profiles', 'PATCH', {'experience': 'Injected'}, helper), 'direct helper profile writes denied')
    for invalid in [{'time_zone_in': 'bad/zone'}, {'dog_sizes_in': ['giant']},
        {'dog_sizes_in': ['small', 'small']}, {'service_districts_in': ['x' * 101]},
        {'availability_in': {'latitude': 1}}, {'availability_in': [{'day': 7, 'start': 0, 'end': 60}]},
        {'availability_in': [{'day': '0', 'start': 0, 'end': 60}]},
        {'availability_in': [{'day': 0, 'start': 100, 'end': 99}]},
        {'availability_in': [{'day': 0, 'start': 0, 'end': 60}, {'day': 0, 'start': 30, 'end': 90}]}]:
        denied(rpc('save_walking_helper_profile', profile | invalid, helper), 'invalid helper preferences rejected')
    check(len(call('/rest/v1/walking_helper_profiles?user_id=eq.' + users[1], token=viewer)[1]) == 1,
        'authorized viewer sees public helper preferences')
    denied(call('/rest/v1/walking_helper_profiles'), 'anonymous helper-profile read denied')
    pet = success(call('/rest/v1/pets', 'POST', {'owner_id': users[0], 'name': 'Synthetic pet', 'size': 'small'}, owner), 'owner creates pet')[0]
    denied(call('/rest/v1/pets', 'POST', {'owner_id': users[1], 'name': 'Injected'}, helper), 'helper cannot create owner-only pet')
    payload = {'pet_in': pet['id'], 'city_in': 'Минск', 'district_in': 'Первомайский',
        'starts_in': (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(), 'duration_in': 30,
        'timezone_in': 'Europe/Minsk', 'description_in': 'Synthetic public request',
        'instructions_in': 'Synthetic private handover instructions'}
    rid = success(rpc('create_walk_request', payload, owner), 'owner creates district-aware request')
    requests.append(rid)
    denied(rpc('create_walk_request', payload, helper), 'helper cannot create owner request')
    legacy = {k: v for k, v in payload.items() if k not in ('district_in', 'timezone_in')}
    denied(rpc('create_walk', legacy, helper), 'legacy create_walk cannot bypass role')
    denied(rpc('create_event', {'title_in': 'Synthetic meeting', 'city_in': 'Минск',
        'starts_in': payload['starts_in'], 'capacity_in': 4}, helper), 'helper cannot create meeting through legacy RPC')
    denied(rpc('create_group', {'title_in': 'Synthetic community'}, helper), 'helper cannot create community through legacy RPC')
    denied(rpc('apply_walk', {'request_in': rid}, owner), 'owner-only cannot apply')
    denied(rpc('walk_private_details', {'request_in': rid}, helper), 'applicant cannot read private instructions')
    denied(rpc('review_walk_owner', {'request_in': rid, 'rating_in': 5}, helper), 'review before assignment denied')
    query = {'city_in': 'Минск', 'district_in': 'Первомайский', 'size_in': 'small', 'limit_in': 1}
    page = success(rpc('search_walk_requests', query, helper), 'filtered bounded discovery')
    check(any(row['id'] == rid for row in page['items']), 'matching city district and pet size returned')
    check('Synthetic private' not in json.dumps(page) and 'instructions' not in json.dumps(page), 'discovery excludes private details')
    check(not any(row['helper'] for row in page['items']), 'discovery does not publish assignment participants')
    denied(rpc('search_walk_requests', query | {'limit_in': 101}, helper), 'oversized page denied')
    check(not any(row['id'] == rid for row in rpc('search_walk_requests', query | {'size_in': 'large'}, helper)[1]['items']), 'unknown or other pet sizes do not match filter')
    denied(rpc('search_walk_requests', query, owner), 'owner-only cannot use helper discovery')
    for token in [helper, other_helper]:
        success(rpc('apply_walk', {'request_in': rid}, token), 'helper applies')
    success(rpc('apply_walk', {'request_in': rid}, helper), 'duplicate application is idempotent')
    notifications = call('/rest/v1/notifications?user_id=eq.' + users[0] + '&kind=eq.walk_application&context_id=eq.' + rid, token=owner)[1]
    check(len(notifications) == 2, 'duplicate application does not duplicate notification')
    mine = success(rpc('my_walks', {'role_in': 'helper', 'view_in': 'applications'}, helper), 'own application view')
    check(mine['items'][0]['conversation_id'] is None and mine['items'][0]['helper'] is None,
        'application does not imply assignment or chat access')
    check(not any(row['id'] == rid for row in rpc('my_walks', {'role_in': 'all'}, viewer)[1]['items']), 'outsider cannot retrieve another agreement')
    with ThreadPoolExecutor(max_workers=2) as pool:
        attempts = list(pool.map(lambda uid: rpc('assign_walk', {'request_in': rid, 'helper_in': uid}, owner), users[1:3]))
    check(sum(result[0] == 200 for result in attempts) == 1, 'concurrent assignment has exactly one winner')
    winner_index = 1 if attempts[0][0] == 200 else 2
    winner, loser = tokens[winner_index], tokens[3 - winner_index]
    winner_uid, loser_uid = users[winner_index], users[3 - winner_index]
    agreement = call('/rest/v1/walk_agreements?request_id=eq.' + rid, token=owner)[1]
    check(len(agreement) == 1 and agreement[0]['helper_id'] == winner_uid, 'one atomic agreement persisted')
    denied(rpc('walk_private_details', {'request_in': rid}, loser), 'unselected applicant cannot read details')
    details = success(rpc('walk_private_details', {'request_in': rid}, winner), 'assigned helper reads instructions')
    check(details['instructions'] == payload['instructions_in'], 'private instructions available only after assignment')
    dashboard = success(rpc('my_walks', {'role_in': 'helper'}, winner), 'assigned helper dashboard')
    walk = next(row for row in dashboard['items'] if row['id'] == rid)
    cid = walk['conversation_id']
    check(cid is not None and 'start' in walk['allowed_actions'], 'next action and agreement chat derived by server')
    check(call('/rest/v1/conversations?id=eq.' + cid, token=loser)[1] == [], 'unselected applicant cannot open agreement chat')
    denied(rpc('advance_walk', {'request_in': rid, 'next_status': 'completed'}, winner), 'status skipping denied')
    success(rpc('set_account_role', {'role_in': 'owner'}, winner), 'helper changes product role after assignment')
    success(rpc('advance_walk', {'request_in': rid, 'next_status': 'in_progress'}, winner), 'role change preserves ongoing agreement')
    success(rpc('advance_walk', {'request_in': rid, 'next_status': 'awaiting_confirmation'}, winner), 'helper finishes walk')
    denied(rpc('review_walk_owner', {'request_in': rid, 'rating_in': 5}, winner), 'review before owner confirmation denied')
    success(rpc('set_account_role', {'role_in': 'helper'}, owner), 'owner changes role after assignment')
    success(rpc('advance_walk', {'request_in': rid, 'next_status': 'completed'}, owner), 'original owner still confirms completion')
    for name, token in [('review_walk', owner), ('review_walk_owner', winner)]:
        for invalid in [{'rating_in': 0}, {'rating_in': 6}, {'rating_in': None},
                        {'body_in': 'x' * 1001}, {'body_in': None}]:
            denied(rpc(name, {'request_in': rid, 'rating_in': 5} | invalid, token), 'invalid directional review rejected')
    for name, token in [('review_walk', owner), ('review_walk_owner', winner)]:
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: rpc(name, {'request_in': rid, 'rating_in': 5, 'body_in': 'Synthetic review'}, token), range(2)))
        check(sum(result[0] in (200, 204) for result in results) == 1, 'one concurrent review per direction')
    denied(rpc('review_walk_owner', {'request_in': rid, 'rating_in': 1}, loser), 'unselected helper cannot review owner')
    denied(rpc('review_walk_owner', {'request_in': rid, 'rating_in': 1}, owner), 'owner self-review denied')
    denied(call('/rest/v1/walk_owner_reviews', 'POST', {'request_id': rid, 'author_id': loser_uid, 'owner_id': users[0], 'rating': 5}, loser), 'direct review insert denied')
    owner_review = call('/rest/v1/walk_owner_reviews?request_id=eq.' + rid, token=owner)[1][0]
    denied(call('/rest/v1/walk_owner_reviews?id=eq.' + owner_review['id'], 'PATCH', {'rating': 1}, owner), 'rating and publication cannot be changed directly')
    success(rpc('reply_walk_owner_review', {'review_in': owner_review['id'], 'body_in': 'Synthetic owner reply'}, owner), 'owner replies to received review')
    denied(rpc('reply_walk_owner_review', {'review_in': owner_review['id'], 'body_in': 'Injected'}, winner), 'review author cannot impersonate recipient reply')
    owner_stat = next(row for row in rpc('owner_stats', {}, viewer)[1] if row['id'] == users[0])
    helper_stat = next(row for row in rpc('helper_stats', {}, viewer)[1] if row['id'] == winner_uid)
    check(owner_stat['rating'] == 5 and owner_stat['review_count'] == 1 and owner_stat['completed'] == 1, 'server-derived owner reputation')
    check(helper_stat['rating'] == 5 and helper_stat['review_count'] == 1 and helper_stat['completed'] == 1, 'helper reputation remains separate and compatible')
    empty = next(row for row in rpc('owner_stats', {}, viewer)[1] if row['id'] == loser_uid)
    check(empty['rating'] is None and empty['review_count'] == 0, 'no invented zero-star rating')
    history = rpc('my_walks', {'role_in': 'helper', 'view_in': 'history'}, winner)[1]
    check(any(row['id'] == rid for row in history['items']), 'history survives role changes')
    export = success(rpc('export_my_data', {}, owner), 'reauthenticated export includes new personal data')
    check(export['product_role']['account_role'] == 'helper' and len(export['owner_reviews_received']) == 1,
        'role and received owner reviews exported')
    check('profile' in export and 'place_reviews' in export, 'legacy export fields preserved')
    success(call('/rest/v1/blocks', 'POST', {'user_id': users[3], 'target_id': users[0]}, viewer), 'synthetic block recorded')
    check(call('/rest/v1/walk_owner_reviews?id=eq.' + owner_review['id'], token=viewer)[1] == [], 'block hides owner review')
    check(not any(row['id'] == users[0] for row in rpc('owner_stats', {}, viewer)[1]), 'block hides owner reputation')
    success(call('/rest/v1/blocks', 'POST', {'user_id': winner_uid, 'target_id': users[0]}, winner), 'participant block recorded')
    denied(rpc('walk_private_details', {'request_in': rid}, winner), 'block revokes private instructions through RPC')
    check(call('/rest/v1/walk_details?request_id=eq.' + rid, token=winner)[1] == [], 'block revokes direct RLS instruction read')
    success(call('/rest/v1/blocks?user_id=eq.' + winner_uid, 'DELETE', token=winner), 'participant block cleared')
    success(call('/rest/v1/blocks', 'POST', {'user_id': users[3], 'target_id': users[1]}, viewer), 'helper profile block recorded')
    check(call('/rest/v1/walking_helper_profiles?user_id=eq.' + users[1], token=viewer)[1] == [], 'block hides helper preferences')
    success(call('/rest/v1/blocks?user_id=eq.' + users[3], 'DELETE', token=viewer), 'viewer blocks cleared')

    # A real TOTP challenge verifies MFA enforcement for new review moderation.
    enroll = success(call('/auth/v1/factors', 'POST', {'factor_type': 'totp', 'friendly_name': 'Synthetic TOTP'}, viewer), 'synthetic MFA factor enrolled')
    challenge = success(call('/auth/v1/factors/' + enroll['id'] + '/challenge', 'POST', {}, viewer), 'synthetic MFA challenge')
    digest = hmac.new(base64.b32decode(enroll['totp']['secret'].upper() + '=' * ((-len(enroll['totp']['secret'])) % 8)),
        struct.pack('>Q', int(time.time()) // 30), hashlib.sha1).digest()
    offset = digest[-1] & 15
    otp = str((struct.unpack('>I', digest[offset:offset + 4])[0] & 0x7fffffff) % 1000000).zfill(6)
    mfa = success(call('/auth/v1/factors/' + enroll['id'] + '/verify', 'POST', {'challenge_id': challenge['id'], 'code': otp}, viewer), 'synthetic MFA verified')
    denied(rpc('my_account_mode', {}, viewer), 'old aal1 token cannot read new role data after MFA')
    report = success(call('/rest/v1/reports', 'POST', {'author_id': users[0], 'target_kind': 'review',
        'target_id': owner_review['id'], 'reason': 'Synthetic report'}, owner), 'owner review report accepted')[0]
    import os
    import subprocess
    subprocess.run(['/opt/homebrew/opt/libpq/bin/psql', '-h', '127.0.0.1', '-p', '54322', '-U', 'postgres', '-d', 'postgres',
        '-c', "update private.accounts set moderator=true where id='" + users[3] + "'"],
        env=os.environ | {'PGPASSWORD': 'postgres'}, stdout=subprocess.DEVNULL, check=True)
    denied(rpc('resolve_report', {'report_in': report['id'], 'action_in': 'hide', 'note_in': 'Synthetic moderation'}, viewer), 'moderator without aal2 cannot hide owner review')
    success(rpc('resolve_report', {'report_in': report['id'], 'action_in': 'hide', 'note_in': 'Synthetic moderation'}, mfa['access_token']), 'MFA moderator hides owner review')
    hidden_stat = next(row for row in rpc('owner_stats', {}, owner)[1] if row['id'] == users[0])
    check(hidden_stat['review_count'] == 0 and hidden_stat['rating'] is None and hidden_stat['completed'] == 1,
        'hidden review leaves completion count but no rating')
    denied(rpc('reply_walk_owner_review', {'review_in': owner_review['id'], 'body_in': 'Hidden reply'}, owner), 'hidden review cannot receive reply')
    success(rpc('set_account_role', {'role_in': 'helper'}, winner), 'helper mode restored before deletion fixture')
    success(rpc('save_walking_helper_profile', profile, winner), 'deletion fixture helper profile saved')
    success(call('/auth/v1/admin/users/' + winner_uid, 'DELETE', staff=True), 'synthetic helper deleted')
    check(call('/rest/v1/walking_helper_profiles?user_id=eq.' + winner_uid, token=mfa['access_token'])[1] == [], 'helper preferences cascade on deletion')
    check(call('/rest/v1/walk_owner_reviews?author_id=eq.' + winner_uid, token=mfa['access_token'])[1] == [], 'authored owner reviews cascade on deletion')
    check(call('/rest/v1/walk_agreements?request_id=eq.' + rid, staff=True)[1][0]['helper_id'] is None, 'deleted helper is anonymized in historical agreement')
    success(rpc('revoke_my_sessions', {}, owner), 'synthetic sessions revoked')
    for name, args in [('my_account_mode', {}), ('owner_stats', {}), ('my_walks', {}),
        ('set_account_role', {'role_in': 'both'}), ('walk_private_details', {'request_in': rid})]:
        denied(rpc(name, args, owner), 'existing revoked JWT denied by ' + name)
finally:
    for rid in requests:
        call('/rest/v1/conversations?context_id=eq.' + rid, 'DELETE', staff=True)
        call('/rest/v1/walk_requests?id=eq.' + rid, 'DELETE', staff=True)
    for uid in users:
        call('/auth/v1/admin/users/' + uid, 'DELETE', staff=True)
print('All ' + str(checks) + ' walking role checks passed')
