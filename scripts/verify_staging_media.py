#!/usr/bin/env python3
"""Bounded staging deployment/auth smoke checks; no real-user data or chats.

Full member upload/read and membership race scenarios remain in the local
verify_chat_media.py suite and the two-device acceptance test.
"""
import json
import secrets
import struct
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

cfg = json.loads(Path('config/staging-backend.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
if base != 'https://cbkmxtplhcdomyeyrwyi.supabase.co':
    raise SystemExit('Only petfriendly-staging is allowed')
pub, staff = cfg['PUBLISHABLE_KEY'], cfg['SERVICE_ROLE_KEY']
users = []
count = 0


def call(path, data=None, token=None, admin=False, method=None):
    key = staff if admin else pub
    binary = isinstance(data, bytes)
    raw = data if binary else json.dumps(data).encode() if data is not None else None
    request = urllib.request.Request(base + path, data=raw,
        method=method or ('POST' if raw is not None else 'GET'),
        headers={'apikey': key, 'Authorization': 'Bearer ' + (key if admin else token or pub),
                 'Content-Type': 'application/octet-stream' if binary else 'application/json'})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read()
            return response.status, json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        return error.code, None


def check(ok, label):
    global count
    if not ok:
        raise AssertionError(label)
    count += 1
    print('PASS ' + label, flush=True)


def fixture():
    email = 'media-smoke-' + secrets.token_hex(8) + '@example.test'
    password = secrets.token_urlsafe(24)
    status, user = call('/auth/v1/admin/users',
        {'email': email, 'password': password, 'email_confirm': True}, admin=True)
    check(status in (200, 201), 'disposable synthetic staging account created')
    users.append(user['id'])
    status, session = call('/auth/v1/token?grant_type=password',
        {'email': email, 'password': password})
    check(status == 200, 'synthetic account signs in')
    return user['id'], session['access_token']


try:
    status, bucket = call('/storage/v1/bucket/petfriendly-chat', admin=True)
    check(status == 200 and bucket['public'] is False and bucket['file_size_limit'] == 1048576,
          'chat bucket is private and bounded to 1 MiB')
    check(call('/rest/v1/chat_attachments?select=message_id&limit=0', admin=True)[0] == 200,
          'service attachment lookup grant is available')
    check(call('/rest/v1/chat_attachments?select=message_id&limit=0')[0] in (401, 403),
          'anonymous cannot enumerate attachment metadata')
    uid, token = fixture()
    query = urllib.parse.urlencode({'conversation': str(uuid.uuid4()),
        'client_id': str(uuid.uuid4()), 'kind': 'image'})
    endpoint = '/functions/v1/chat-media?' + query
    metadata = json.dumps({'caption': '', 'mime': 'image/png'}).encode()
    payload = struct.pack('>I', len(metadata)) + metadata + b'synthetic-invalid-image'
    status, capabilities = call('/rest/v1/rpc/chat_media_capabilities', {}, token)
    check(status == 200 and capabilities.get('image') is True and capabilities.get('video') is False,
          'deployed schema advertises attachment capability')
    video_endpoint = endpoint.replace('kind=image', 'kind=video')
    check(call(video_endpoint, payload, token)[0] == 400, 'deployed function rejects video before upload')
    check(call(endpoint, payload)[0] == 401, 'anonymous upload rejected by deployed function')
    check(call(endpoint, payload, 'invalid-jwt')[0] == 401,
          'invalid JWT rejected by internal authentication')
    check(call(endpoint, payload, token)[0] == 403,
          'valid new account JWT reaches membership check and is rejected outside a chat')
    read_endpoint = '/functions/v1/chat-media?mode=read&message=' + str(uuid.uuid4())
    check(call(read_endpoint, b'', token)[0] == 404,
          'unavailable attachment does not disclose metadata')
    publish_args = dict.fromkeys(('claims_in', 'conversation_in', 'client_id', 'body_in',
        'path_in', 'kind_in', 'mime_in', 'size_in', 'duration_in'))
    check(call('/rest/v1/rpc/publish_chat_media', publish_args, token)[0] in (401, 403),
          'ordinary user cannot call privileged publish RPC')
    check(call('/storage/v1/object/petfriendly-chat/' + uid + '/forged.jpg', payload, token)[0] >= 400,
          'ordinary user cannot write directly to private chat storage')
    check(call('/functions/v1/city-catalog', {'city': ''}, token)[0] == 400,
          'updated city-catalog accepts current JWT and validates city')
    check(call('/rest/v1/rpc/revoke_my_sessions', {}, token)[0] == 204,
          'staging session revocation succeeds')
    check(call(endpoint, payload, token)[0] == 403,
          'revoked existing JWT cannot upload')
    check(call('/functions/v1/city-catalog', {'city': 'Минск'}, token)[0] == 403,
          'revoked existing JWT cannot import places')
    _, deletion_token = fixture()
    check(call('/functions/v1/delete-account', {}, deletion_token)[0] == 200,
          'updated delete-account removes its disposable account')
finally:
    for uid in users:
        status, _ = call('/auth/v1/admin/users/' + uid, admin=True, method='DELETE')
        if status not in (200, 204, 404):
            raise RuntimeError('Disposable staging account cleanup failed')
print('Staging media smoke checks:', count)
