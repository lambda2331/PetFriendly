#!/usr/bin/env python3
"""Generate reviewable SQL for a NEW empty staging database; never connect or deploy."""
from pathlib import Path
import hashlib, json, argparse
parser=argparse.ArgumentParser()
parser.add_argument("--from-version", help="Prepare an incremental upgrade from an already applied exact version")
args=parser.parse_args()
ROOT=Path(__file__).resolve().parents[1]
files=sorted((ROOT/'supabase/migrations').glob('*.sql'))
out=ROOT/'tooling/.logs/staging-bundle'/files[-1].stem.split('_',1)[0];out.mkdir(parents=True,exist_ok=True)
manifest={'target':'new-empty-petfriendly-staging-only','migrations':[],'catalogRows':0,'seedChunks':[]}
parts=["begin;\ndo $$ begin if to_regclass('public.profiles') is not null or to_regclass('private.accounts') is not null then raise exception 'Use this initial bundle only on a new empty staging database';end if;end $$;\n",
 "create schema if not exists supabase_migrations;\ncreate table if not exists supabase_migrations.schema_migrations(version text primary key,statements text[],name text);\nrevoke all on schema supabase_migrations from public,anon,authenticated;\n"]
for p in files:
 source=p.read_text();version,name=p.stem.split('_',1)
 delimiter='$petfriendly_migration$'
 if delimiter in source:raise SystemExit('SQL delimiter collision')
 parts += [f'\n-- {p.name}\n', source, f"\ninsert into supabase_migrations.schema_migrations(version,statements,name) values('{version}',array[{delimiter}{source}{delimiter}],'{name}');\n"]
 manifest['migrations'].append({'file':p.name,'sha256':hashlib.sha256(source.encode()).hexdigest()})
parts.append('commit;\n');(out/'01-schema.sql').write_text(''.join(parts))
# Source seed contains only public OSM venues, never auth/test fixtures.
rows=[line for line in (ROOT/'supabase/seed.sql').read_text().splitlines() if line.startswith('insert into public.places(')]
if not rows or any(not line.endswith(';') for line in rows):raise SystemExit('Unexpected seed format')
for index,start in enumerate(range(0,len(rows),200),2):
 name=f'{index:02d}-catalog.sql';body='begin;\n-- © OpenStreetMap contributors · ODbL\n'+'\n'.join(rows[start:start+200])+'\ncommit;\n'
 (out/name).write_text(body);manifest['seedChunks'].append({'file':name,'rows':len(rows[start:start+200]),'sha256':hashlib.sha256(body.encode()).hexdigest()})
# Separate incremental bundle for a staging database at the preceding version.
if len(files) > 1:
 previous=args.from_version or files[-2].stem.split('_',1)[0]
 versions=[p.stem.split('_',1)[0] for p in files]
 if previous not in versions or previous==versions[-1]:raise SystemExit('Unknown or already current source version')
 body="begin;\ndo $$ begin if (select max(version) from supabase_migrations.schema_migrations) is distinct from '"+previous+"' then raise exception 'Unexpected staging migration version';end if;end $$;\n"
 for migration in files[versions.index(previous)+1:]:
  latest,name=migration.stem.split('_',1);source=migration.read_text()
  body+=source+f"\ninsert into supabase_migrations.schema_migrations(version,statements,name) values('{latest}',array[$petfriendly_migration${source}$petfriendly_migration$],'{name}');\n"
 body+='commit;\n'
 upgrade=f'{len(manifest["seedChunks"])+2:02d}-upgrade-from-{previous[-3:]}.sql'
 (out/upgrade).write_text(body)
 manifest['incrementalUpgrade']={'file':upgrade,'requiresVersion':previous,'sha256':hashlib.sha256(body.encode()).hexdigest()}
manifest['catalogRows']=len(rows);(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Prepared {len(files)} migrations and {len(rows)} public catalog rows in {len(manifest["seedChunks"])} batches. No database connection or deployment performed.')
