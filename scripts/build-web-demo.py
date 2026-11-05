#!/usr/bin/env python3
"""Compile the canonical Flutter screens with a complete English text catalog.

No maintained UI fork: only literal text is localized in an ignored build tree.
The native source and native default language remain unchanged. Unknown strings
fail the build rather than silently shipping an untranslated screen.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tooling/portfolio'))
from dart_strings import segments


def translate(source, catalog, internal, name):
    replacements = []
    for start, end, text, raw in segments(source):
        if text in internal:
            continue
        if text not in catalog:
            raise ValueError(f'Missing English translation in {name}: {text!r}')
        value = catalog[text]
        if raw:
            raise ValueError(f'Raw literal requires manual review: {name}')
        escaped = value.replace('\\', '\\\\').replace("'", "\\'").replace('"', '\\"').replace('$', '\\$').replace('\n', '\\n').replace('\r', '\\r')
        replacements.append((start, end, escaped))
    for start, end, value in reversed(replacements):
        source = source[:start] + value + source[end:]
    return source.replace('«', '“').replace('»', '”')


def prepare():
    catalog = json.loads((ROOT / 'tooling/portfolio/en.json').read_text())
    internal = set(json.loads((ROOT / 'tooling/portfolio/internal-literals.json').read_text()))
    output = ROOT / 'build/portfolio-source'
    output.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256()
    files = sorted((ROOT / 'lib').rglob('*.dart'))
    for path in files:
        relative = path.relative_to(ROOT)
        source = path.read_text()
        digest.update(str(relative).encode() + source.encode())
        translated = translate(source, catalog, internal, str(relative))
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(translated)
    for name in ('pubspec.yaml', 'pubspec.lock'):
        shutil.copy2(ROOT / name, output / name)
    for name in ('assets', 'web'):
        shutil.copytree(ROOT / name, output / name, dirs_exist_ok=True)
    # Production demo services are compile-time disabled; no local config is copied.
    fingerprint = hashlib.sha256(digest.digest() + (ROOT/'tooling/portfolio/en.json').read_bytes() + (ROOT/'pubspec.lock').read_bytes()).hexdigest()
    manifest = {'build_fingerprint': fingerprint, 'source_sha256': digest.hexdigest(), 'dart_files': len(files), 'english_entries': len(catalog), 'mode': 'PORTFOLIO_DEMO', 'map': 'offline-mock'}
    (output / 'source-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    return output, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--prepare-only', action='store_true')
    parser.add_argument('--base-href', default='/PetFriendly/app/')
    args = parser.parse_args()
    output, manifest = prepare()
    print(f"English coverage complete: {manifest['dart_files']} canonical Dart files, {manifest['english_entries']} reviewed entries.", flush=True)
    if args.check or args.prepare_only:
        return
    flutter = os.environ.get('PETFRIENDLY_FLUTTER_BIN') or shutil.which('flutter')
    if not flutter:
        raise SystemExit('Set PETFRIENDLY_FLUTTER_BIN or add Flutter to PATH.')
    subprocess.run([flutter, 'pub', 'get', '--enforce-lockfile'], cwd=output, check=True)
    subprocess.run([flutter, 'build', 'web', '--release', '--no-pub', '--no-wasm-dry-run', '--base-href', args.base_href,
                    '--dart-define=PORTFOLIO_DEMO=true', '--dart-define=USE_DEMO_DATA=true'], cwd=output, check=True)
    target = ROOT / 'portfolio/app'
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(output / 'build/web', target)
    shutil.copy2(output / 'source-manifest.json', target / 'source-manifest.json')
    bootstrap = target / 'flutter_bootstrap.js'
    bootstrap.write_text(bootstrap.read_text().replace('main.dart.js', 'main.dart.js?v=' + manifest['build_fingerprint'][:16]))
    print('Built portfolio/app from the canonical Flutter application.')


if __name__ == '__main__':
    try:
        main()
    except ValueError as error:
        raise SystemExit(str(error))
