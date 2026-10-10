#!/usr/bin/env python3
"""Verify inbox privacy and read cursors against the isolated local backend."""
import json
import secrets
import uuid
import urllib.error
import urllib.request
from pathlib import Path

cfg = json.loads(Path('config/backend-status.local.json').read_text())
base = cfg['API_URL'].rstrip('/')
pub = cfg.get('PUBLISHABLE_KEY') or cfg['ANON_KEY']
admin = cfg['SERVICE_ROLE_KEY']
if not base.startswith('http://127.0.0.1:'):
    raise SystemExit('Local endpoint required')
users = []
conversations = []
checks = 0


def call(path, method='GET', data=None, token=None, staff=False):
    key = admin if staff else pub
    request = urllib.request.Request(base + path, method=method, headers={
        'apikey': key, 'Authorization': 'Bearer ' + (key if staff else token or pub),
        'Content-Type': 'application/json',
    }, data=json.dumps(data).encode() if data is not None else None)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
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
    email = 'inbox-' + secrets.token_hex(6) + '@example.test'
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


def conversation(members):
    cid = str(uuid.uuid4())
    code, _ = call('/rest/v1/conversations', 'POST', {'id': cid, 'kind': 'direct'}, staff=True)
    check(code == 201, 'create synthetic conversation')
    conversations.append(cid)
    code, _ = call('/rest/v1/conversation_members', 'POST', [
        {'conversation_id': cid, 'user_id': uid} for uid in members
    ], staff=True)
    check(code == 201, 'add synthetic members')
    return cid


def send(cid, token, body):
    code, mid = call('/rest/v1/rpc/send_message', 'POST', {
        'conversation_in': cid, 'client_id': str(uuid.uuid4()), 'body_in': body,
    }, token)
    check(code == 200, 'send synthetic message')
    return mid


def inbox(token, ids):
    return call('/rest/v1/rpc/chat_inbox', 'POST', {'conversation_ids': ids}, token)


def read(token, cid, mid):
    return call('/rest/v1/rpc/mark_conversation_read', 'POST', {
        'conversation_in': cid, 'message_in': mid,
    }, token)


try:
    a, ta = fixture()
    b, tb = fixture()
    c, tc = fixture()
    cid = conversation([a, b])
    other = conversation([b, c])
    check(inbox(None, [cid])[0] >= 400, 'anonymous inbox denied')
    check(inbox(tc, [cid]) == (200, []), 'outsider sees no conversation metadata')
    check(inbox(ta, [cid])[1][0]['unread_count'] == 0, 'empty conversation is genuinely unread zero')
    first = send(cid, tb, 'Синтетическое входящее сообщение')
    reply = send(cid, ta, 'Синтетический ответ')
    row = inbox(ta, [cid])[1][0]
    check(row['body'] == 'Синтетический ответ' and row['sender_id'] == a,
          'latest preview is one actual latest message')
    check(row['unread_count'] == 1, 'own outgoing message does not increase unread count')
    check(read(tc, cid, first)[0] == 403, 'outsider cannot advance read cursor')
    wrong = send(other, tc, 'Другой разговор')
    check(read(ta, cid, wrong)[0] >= 400, 'cannot acknowledge a message in another conversation')
    check(read(ta, cid, reply)[0] in (200, 204), 'member marks loaded message read')
    check(inbox(ta, [cid])[1][0]['unread_count'] == 0, 'cursor clears earlier incoming messages')
    code, exported = call('/rest/v1/rpc/export_my_data', 'POST', {}, ta)
    check(code == 200 and len(exported['conversation_reads']) == 1 and
          exported['conversation_reads'][0]['user_id'] == a,
          'recent-auth export includes only own read cursor')
    code, exported = call('/rest/v1/rpc/export_my_data', 'POST', {}, tb)
    check(code == 200 and exported['conversation_reads'] == [],
          'export excludes other conversation members read cursors')
    latest = send(cid, tb, 'Новое после прочтения')
    check(inbox(ta, [cid])[1][0]['unread_count'] == 1, 'later incoming message remains unread')
    read(ta, cid, first)
    check(inbox(ta, [cid])[1][0]['unread_count'] == 1, 'older acknowledgement cannot move cursor backward')
    check(call('/rest/v1/conversation_reads', 'POST', {
        'conversation_id': cid, 'user_id': b, 'last_read_at': '2026-01-01T00:00:00Z',
        'last_read_id': latest,
    }, ta)[0] >= 400, 'client cannot write any read cursor directly')
    check(call('/rest/v1/conversation_reads', token=tb)[1] == [], 'other member cannot read own private cursor')
    check(inbox(ta, [cid] * 101)[0] >= 400, 'summary request is bounded to 100 conversations')
    call('/rest/v1/conversation_members?conversation_id=eq.' + cid + '&user_id=eq.' + a,
         'DELETE', staff=True)
    check(inbox(ta, [cid]) == (200, []), 'removed membership loses inbox visibility')
    check(read(ta, cid, latest)[0] == 403, 'removed membership loses acknowledgement access')
    check(call('/rest/v1/conversation_reads', token=ta)[1] == [],
          'membership removal deletes own read cursor through cascade')
    call('/rest/v1/rpc/revoke_my_sessions', 'POST', {}, tb)
    check(inbox(tb, [cid])[0] == 403, 'revoked existing JWT cannot read inbox RPC')
    check(read(tb, cid, latest)[0] == 403, 'revoked existing JWT cannot write read cursor')
    check(call('/rest/v1/conversation_reads', token=tb)[1] == [], 'revoked JWT sees no read-cursor rows through RLS')
finally:
    for cid in conversations:
        call('/rest/v1/conversations?id=eq.' + cid, 'DELETE', staff=True)
    for uid in users:
        call('/auth/v1/admin/users/' + uid, 'DELETE', staff=True)
print('All ' + str(checks) + ' inbox checks passed')
