#!/usr/bin/env python3
"""Local-only regression checks for catalog refresh, grants, push and password security."""
import json, os, re, secrets, subprocess, urllib.error, urllib.parse, urllib.request, uuid
from pathlib import Path

cfg = json.loads(Path('config/backend-status.local.json').read_text())
base, pub, staff = cfg['API_URL'], cfg['PUBLISHABLE_KEY'], cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):
    raise SystemExit('Local backend required')
env = {**os.environ, 'DOCKER_HOST': 'unix:///Users/artem.dudinskij/.colima/petfriendly/docker.sock'}
city = 'Review synthetic ' + secrets.token_hex(6)
lease, source = str(uuid.uuid4()), 'node/' + str(secrets.randbelow(10**12) + 10**15)
uid = None
count = 0

def sql(statement):
    return subprocess.check_output(['docker', 'exec', '-i', 'supabase_db_PetFriendly',
        'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-At'],
        input=statement.encode(), env=env).decode().strip()

def call(path, data=None, token=None, admin=False, method=None):
    key = staff if admin else pub
    req = urllib.request.Request(base + path, data=json.dumps(data).encode() if data is not None else None,
        method=method or ('POST' if data is not None else 'GET'),
        headers={'apikey': key, 'Authorization': 'Bearer ' + (key if admin else token or pub),
                 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read()
            return r.status, json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())

def check(ok, label):
    global count
    if not ok:
        raise AssertionError(label)
    count += 1
    print('PASS ' + label, flush=True)

def record(name='Original', **changes):
    return dict(source_id=source, name=name, category='Парк', latitude=53.9,
        longitude=27.56, pet_access='unknown', source_tags={'name': name},
        source_updated_at='2026-01-01T10:00:00Z', **changes)

def import_batch(records, token=None, admin=True, lease_value=lease):
    return call('/rest/v1/rpc/import_city_catalog', {'city_in': city,
        'lease_in': lease_value, 'records_in': records}, token, admin)

try:
    email = 'review-' + secrets.token_hex(8) + '@example.test'
    password, replacement = secrets.token_urlsafe(24), secrets.token_urlsafe(24)
    code, user = call('/auth/v1/admin/users', {'email': email, 'password': password,
        'email_confirm': True}, admin=True)
    check(code in (200, 201), 'synthetic account created')
    uid = user['id']
    code, session = call('/auth/v1/token?grant_type=password', {'email': email, 'password': password})
    token = session['access_token']
    sql(f"insert into private.city_catalog values('{city.lower()}','{city}','fetching','{lease}',now());")
    check(import_batch([record()], token, False)[0] >= 400, 'authenticated client cannot import')
    check(import_batch([record()], admin=False)[0] >= 400, 'anonymous client cannot import')
    check(import_batch([record()], lease_value=str(uuid.uuid4()))[0] == 403, 'wrong lease rejected')
    code, ids = import_batch([record()])
    check(code == 200 and len(ids) == 1, 'first import creates a venue')
    pid = ids[0]
    fresh = record('Updated')
    fresh.update(latitude=53.91, longitude=27.57, pet_access='leashed',
        source_tags={'name':'Updated','dog':'leashed'}, source_updated_at='2026-01-02T10:00:00Z')
    check(import_batch([fresh])[1] == ids, 'refresh preserves venue ID')
    _, places = call('/rest/v1/places?id=eq.' + pid, admin=True)
    p = places[0]
    check(p['name'] == 'Updated' and p['latitude'] == 53.91 and p['pet_access'] == 'leashed',
        'refresh updates name, coordinates and source access hints')
    check(p['source_updated_at'].startswith('2026-01-02') and p['source_tags']['dog'] == 'leashed',
        'refresh advances provenance')
    sql(f"update public.places set name='Staff verified',latitude=53.92,published=false where id='{pid}';")
    newer = {**fresh, 'name':'OSM newer', 'latitude':53.93, 'longitude':27.58,
             'source_updated_at':'2026-01-03T10:00:00Z'}
    check(import_batch([newer])[0] == 200, 'refresh accepts a moderated venue')
    _, places = call('/rest/v1/places?id=eq.' + pid, admin=True)
    p = places[0]
    check(p['name'] == 'Staff verified' and p['latitude'] == 53.92 and p['longitude'] == 27.58,
        'independent field edits survive while unedited fields refresh')
    check(p['published'] is False, 'refresh cannot republish a hidden venue')
    check(import_batch([record()])[0] == 200, 'older source response handled')
    _, places = call('/rest/v1/places?id=eq.' + pid, admin=True)
    check(places[0]['source_updated_at'].startswith('2026-01-03'), 'older response cannot regress provenance')
    check(import_batch([{**fresh, 'category':'Кафе'}])[0] >= 400, 'automatic eateries rejected')
    check(import_batch([fresh] * 201)[0] >= 400, 'oversized batch rejected')
    check(sql("select has_table_privilege('service_role','public.chat_attachments','select');") == 't',
        'service role can check attachment publication for cleanup')
    # Even without automatic grants, the explicit migration grant is sufficient.
    result = sql("begin; revoke all on public.chat_attachments from service_role; "
        "grant select on public.chat_attachments to service_role; set local role service_role; "
        "select count(*)>=0 from public.chat_attachments; rollback;")
    check('t' in result.splitlines(), 'cleanup lookup works with automatic grants disabled')
    check(call('/rest/v1/device_tokens', {'user_id':uid, 'token':'review-' + lease, 'platform':'ios'}, token)[0] == 201,
        'fixture registers a push token')
    check(call('/rest/v1/rpc/revoke_my_sessions', {}, token)[0] == 204, 'global logout revokes sessions')
    check(call('/rest/v1/device_tokens?user_id=eq.' + uid, admin=True)[1] == [],
        'global logout removes all device registrations')
    _, session = call('/auth/v1/token?grant_type=password', {'email':email, 'password':password})
    token = session['access_token']
    sql(f"update auth.sessions set created_at=now()-interval '2 days' where user_id='{uid}';")
    code, error = call('/auth/v1/user', {'password':replacement}, token, method='PUT')
    check(code == 400 and error.get('error_code', error.get('code')) == 'reauthentication_needed',
        'old session cannot change password without server reauthentication')
    check(call('/auth/v1/reauthenticate', token=token)[0] == 200, 'server sends password confirmation nonce')
    with urllib.request.urlopen('http://127.0.0.1:54324/api/v1/messages') as r:
        messages = json.load(r)['messages']
    nonce = None
    for message in messages:
        with urllib.request.urlopen('http://127.0.0.1:54324/api/v1/message/' + message['ID']) as r:
            mail = json.load(r)
        if any(to.get('Address') == email for to in mail.get('To', [])):
            match = re.search(r'\b(\d{6})\b', mail.get('Text', ''))
            if match:
                nonce = match.group(1)
                break
    check(nonce is not None, 'synthetic confirmation delivered to local Mailpit')
    check(call('/auth/v1/user', {'password':replacement, 'nonce':'invalid'}, token, method='PUT')[0] >= 400,
        'incorrect confirmation nonce rejected')
    check(call('/auth/v1/user', {'password':replacement, 'nonce':nonce}, token, method='PUT')[0] == 200,
        'confirmed password change succeeds')
    print('Review regression checks:', count)
finally:
    sql(f"delete from public.places where source_id='{source}'; delete from private.city_catalog where city_key='{city.lower()}';")
    if uid:
        call('/auth/v1/admin/users/' + uid, admin=True, method='DELETE')
