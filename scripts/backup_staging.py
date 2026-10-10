#!/usr/bin/env python3
"""Encrypted staging DB + private Storage backup. Credentials stay in local config.

Run: python3 scripts/backup_staging.py --config config/backup.local.json
Restore into an isolated project, apply deletion records, then verify authorization.
This script does not invent a retention schedule or enable a cloud scheduler.
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import tarfile
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path

PROJECT = 'cbkmxtplhcdomyeyrwyi'


def validate_database_url(value):
    uri = urllib.parse.urlparse(value)
    if uri.scheme not in ('postgres', 'postgresql') or not uri.password:
        raise ValueError('Configure a PostgreSQL connection with a password')
    direct = uri.hostname == 'db.' + PROJECT + '.supabase.co' and uri.username == 'postgres'
    pooled = (uri.hostname or '').endswith('.pooler.supabase.com') and uri.username == 'postgres.' + PROJECT
    if not (direct or pooled):
        raise ValueError('Only the PetFriendly staging database is allowed')
    return uri


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', default='config/backup.local.json')
    args = parser.parse_args()
    cfg = json.loads(Path(args.config).read_text())
    base = cfg['API_URL'].rstrip('/')
    if base != 'https://' + PROJECT + '.supabase.co':
        raise ValueError('Only PetFriendly staging is allowed')
    uri = validate_database_url(cfg.get('DB_URL') or '')
    key = cfg['SERVICE_ROLE_KEY']
    recipient = Path('config/backup.recipient.txt').read_text().strip()
    if not recipient.startswith('age1'):
        raise ValueError('An age recipient is required')
    age = shutil.which('age') or '/opt/homebrew/bin/age'
    pg_dump = shutil.which('pg_dump') or '/opt/homebrew/opt/libpq/bin/pg_dump'

    def storage(path, data=None):
        raw = json.dumps(data).encode() if data is not None else None
        request = urllib.request.Request(base + '/storage/v1/' + path, data=raw,
            headers={'apikey': key, 'Authorization': 'Bearer ' + key,
                     'Content-Type': 'application/json'})
        return urllib.request.urlopen(request, timeout=120)

    def download_tree(bucket, root, prefix=''):
        offset = 0
        while True:
            with storage('object/list/' + bucket, {'prefix': prefix, 'limit': 100,
                'offset': offset, 'sortBy': {'column': 'name', 'order': 'asc'}}) as response:
                rows = json.load(response)
            for row in rows:
                name = row['name']
                if name in ('.', '..') or '/' in name or '\\' in name:
                    raise ValueError('Invalid storage object name')
                path = prefix + '/' + name if prefix else name
                target = root / bucket / path
                if row.get('id') is None:
                    download_tree(bucket, root, path)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with storage('object/' + bucket + '/' + urllib.parse.quote(path, safe='/')) as response:
                        with target.open('wb') as output:
                            shutil.copyfileobj(response, output)
            if len(rows) < 100:
                break
            offset += len(rows)

    os.umask(0o077)
    directory = Path('config/backups')
    directory.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    destination = directory / ('petfriendly-' + stamp + '.tar.age')
    partial = destination.with_suffix('.partial')
    env = os.environ.copy()
    env.update(PGHOST=uri.hostname, PGPORT=str(uri.port or 5432),
        PGUSER=urllib.parse.unquote(uri.username), PGPASSWORD=urllib.parse.unquote(uri.password),
        PGDATABASE=uri.path.lstrip('/') or 'postgres', PGSSLMODE='verify-full',
        PGSSLROOTCERT=cfg.get('SSL_ROOT_CERT') or 'system')
    try:
        with tempfile.TemporaryDirectory(prefix='petfriendly-backup-') as temporary:
            root = Path(temporary)
            # The temporary workspace is private and removed even when export fails.
            subprocess.run([pg_dump, '--format=custom', '--no-owner',
                '--file=' + str(root / 'database.dump')], env=env, check=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            for bucket in ('petfriendly-photos', 'petfriendly-chat'):
                download_tree(bucket, root / 'storage')
            (root / 'manifest.json').write_text(json.dumps({'project': PROJECT,
                'created_at_utc': stamp, 'contains_storage': True,
                'consistency': 'Quiesce writes before export; DB and Storage are not an atomic snapshot'}))
            with partial.open('xb') as output:
                process = subprocess.Popen([age, '-r', recipient], stdin=subprocess.PIPE,
                    stdout=output, stderr=subprocess.PIPE)
                try:
                    with tarfile.open(fileobj=process.stdin, mode='w|') as archive:
                        for item in root.iterdir():
                            archive.add(item, arcname=item.name)
                    process.stdin.close()
                    if process.wait() != 0:
                        raise RuntimeError('Backup encryption failed')
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
            partial.rename(destination)
        print('Encrypted staging backup saved:', destination)
    except Exception:
        partial.unlink(missing_ok=True)
        raise RuntimeError('Backup failed; no completed archive was published') from None


if __name__ == '__main__':
    main()
