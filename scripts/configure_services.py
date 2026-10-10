#!/usr/bin/env python3
"""Prepare/check client configuration without displaying credential values."""
import argparse
import base64
import json
import os
from pathlib import Path
import plistlib
import sys
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = 'com.petfriendly.petfriendly'
FIREBASE = ('FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID')
FLAGS = ('USE_DEMO_DATA', 'AUTH_GOOGLE_ENABLED', 'AUTH_APPLE_ENABLED', 'AUTH_TELEGRAM_ENABLED')

def read(path):
    with Path(path).open() as stream:
        return json.load(stream)

def write_new(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x') as stream:
        os.chmod(path, 0o600)
        json.dump(data, stream, indent=2)
        stream.write('\n')

def server_key(value):
    if value.startswith('sb_secret_'):
        return True
    try:
        payload = value.split('.')[1]
        return json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))['role'] == 'service_role'
    except (ValueError, KeyError, IndexError, UnicodeError):
        return False

def validate(data, platform, release=False):
    errors = []
    allowed = set(read(ROOT / 'config/app.example.json'))
    if set(data) - allowed:
        errors.append('Есть неизвестные поля: клиентский файл не должен содержать серверные секреты.')
    if not all(isinstance(v, str) for v in data.values()):
        errors.append('Значения dart-define должны быть строками.')
        return errors
    for flag in FLAGS:
        if data.get(flag, 'false') not in ('true', 'false'):
            errors.append(f'{flag}: допустимы только true/false.')
    key = data.get('SUPABASE_PUBLISHABLE_KEY', '')
    if server_key(key):
        errors.append('Server key запрещён в клиенте.')
    if data.get('USE_DEMO_DATA') == 'false':
        uri = urlparse(data.get('SUPABASE_URL', ''))
        local = uri.hostname in ('localhost', '127.0.0.1', '10.0.2.2')
        if not uri.hostname or uri.username or uri.password or uri.query or uri.fragment:
            errors.append('SUPABASE_URL должен быть URL проекта без credentials/query/fragment.')
        if uri.scheme != 'https' and not (local and not release and uri.scheme == 'http'):
            errors.append('Для релиза требуется HTTPS; локальный HTTP разрешён только debug.')
        if platform == 'android' and uri.hostname in ('localhost', '127.0.0.1'):
            errors.append('Android Emulator обращается к Mac через 10.0.2.2.')
        if not key:
            errors.append('Отсутствует publishable/anon ключ Supabase.')
    token = data.get('MAPBOX_ACCESS_TOKEN', '')
    if token and not token.startswith('pk.'):
        errors.append('Mapbox: клиенту нужен публичный pk. token, не секретный sk. token.')
    configured = [bool(data.get(k)) for k in FIREBASE]
    if any(configured) and not all(configured):
        errors.append('Firebase: заполните все четыре FIREBASE_* параметра.')
    app_id = data.get('FIREBASE_APP_ID', '')
    if app_id and f':{platform}:' not in app_id:
        errors.append('Firebase APP_ID не соответствует выбранной платформе.')
    if release and data.get('USE_DEMO_DATA') != 'false':
        errors.append('Проверка релиза требует USE_DEMO_DATA=false.')
    return errors

def init():
    source = read(ROOT / 'config/app.example.json')
    local = ROOT / 'config/supabase.local.json'
    if local.exists():
        values = read(local)
        for k in ('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'USE_DEMO_DATA'):
            source[k] = values.get(k, source[k])
    for platform in ('ios', 'android'):
        data = dict(source)
        if platform == 'android':
            data['SUPABASE_URL'] = data['SUPABASE_URL'].replace('127.0.0.1', '10.0.2.2').replace('localhost', '10.0.2.2')
        path = ROOT / f'config/app.{platform}.local.json'
        if path.exists():
            print(f'Сохранён без изменений: {path.name}')
        else:
            errors = validate(data, platform)
            if errors:
                raise ValueError('Исходная конфигурация некорректна.')
            write_new(path, data)
            print(f'Готово: {path.name}')

def firebase_import(args):
    path = args.config or ROOT / f'config/app.{args.platform}.local.json'
    data = read(path)
    if args.platform == 'android':
        document = read(args.source)
        matches = [c for c in document['client'] if c['client_info']['android_client_info']['package_name'] == BUNDLE]
        if len(matches) != 1:
            raise ValueError('Firebase должен содержать ровно один Android client с package приложения.')
        client = matches[0]
        values = (client['api_key'][0]['current_key'], client['client_info']['mobilesdk_app_id'], document['project_info']['project_number'], document['project_info']['project_id'])
    else:
        with Path(args.source).open('rb') as stream:
            document = plistlib.load(stream)
        if document['BUNDLE_ID'] != BUNDLE:
            raise ValueError('Firebase Bundle ID не соответствует приложению.')
        values = tuple(document[k] for k in ('API_KEY', 'GOOGLE_APP_ID', 'GCM_SENDER_ID', 'PROJECT_ID'))
    data.update(zip(FIREBASE, map(str, values)))
    errors = validate(data, args.platform)
    if errors:
        raise ValueError('Импортируемая конфигурация некорректна: ' + '; '.join(errors))
    temporary = path.with_name('.prepare.' + path.name)
    write_new(temporary, data)
    temporary.replace(path)
    print('Готово: клиентские параметры Firebase импортированы; значения не выводятся.')

def check(args):
    data = read(args.config)
    errors = validate(data, args.platform, args.release)
    for error in errors:
        print('ОШИБКА: ' + error)
    if errors:
        return 1
    print('Готово: формат и разделение клиентских/серверных параметров проверены.')
    print('Supabase: ' + ('локальный/облачный режим задан' if data.get('USE_DEMO_DATA') == 'false' else 'демо'))
    print('Mapbox: ' + ('token задан; квоту и аккаунт проверить отдельно' if data.get('MAPBOX_ACCESS_TOKEN') else 'ожидает token'))
    print('Firebase: ' + ('параметры заданы; APNs и доставка проверяются отдельно' if data.get('FIREBASE_APP_ID') else 'ожидает клиентские параметры'))
    for name in ('GOOGLE', 'APPLE', 'TELEGRAM'):
        print(name + ': ' + ('флаг включён; требуется проверка реального входа' if data.get('AUTH_' + name + '_ENABLED') == 'true' else 'не активирован'))
    return 0

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('init')
    for name in ('check', 'firebase'):
        item = commands.add_parser(name)
        item.add_argument('--platform', choices=('ios', 'android'), required=True)
        if name == 'check':
            item.add_argument('--config', type=Path, required=True)
            item.add_argument('--release', action='store_true')
        else:
            item.add_argument('--source', type=Path, required=True)
            item.add_argument('--config', type=Path, help='Target client config; default is the local platform config.')
    args = parser.parse_args()
    try:
        if args.command == 'init': init()
        elif args.command == 'firebase': firebase_import(args)
        else: sys.exit(check(args))
    except (OSError, ValueError, KeyError, TypeError):
        # Never echo source values/JSON parser fragments, which could contain secrets.
        print('Не удалось прочитать/подготовить конфигурацию. Проверьте файл и ожидаемый формат.', file=sys.stderr)
        sys.exit(1)
