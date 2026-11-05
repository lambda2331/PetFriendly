#!/usr/bin/env python3
"""Check the Pages artifact for missing assets, broken local links and untranslated copy."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'portfolio'
errors = []


class Document(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
        self.lang = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'html':
            self.lang = attrs.get('lang')
        if attrs.get('id'):
            self.ids.add(attrs['id'])
        for attr in ('href', 'src'):
            if attrs.get(attr):
                self.links.append(attrs[attr])


docs = {}
for path in SITE.rglob('*.html'):
    source = path.read_text()
    doc = Document()
    doc.feed(source)
    docs[path.resolve()] = doc
    if doc.lang != 'en':
        errors.append(f'{path.relative_to(ROOT)}: expected lang=en')

for path in SITE.rglob('*'):
    if path.suffix in {'.html', '.css', '.js'} and re.search('[А-Яа-яЁё]', path.read_text()):
        errors.append(f'{path.relative_to(ROOT)}: untranslated Cyrillic content')

for path, doc in docs.items():
    for link in doc.links:
        url = urlsplit(link)
        if url.scheme or url.netloc:
            continue
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        if target.is_dir():
            target /= 'index.html'
        if not target.is_relative_to(SITE.resolve()):
            errors.append(f'{path.name}: link escapes deployment boundary: {link}')
        elif not target.is_file():
            errors.append(f'{path.name}: missing local resource: {link}')
        elif url.fragment and target in docs and unquote(url.fragment) not in docs[target].ids:
            errors.append(f'{path.name}: missing anchor: {link}')

for path in SITE.rglob('*.css'):
    for asset in re.findall(r'url\([\'\"]?([^\)\'\"]+)', path.read_text()):
        if not urlsplit(asset).scheme and not (path.parent / asset).is_file():
            errors.append(f'{path.name}: missing CSS asset: {asset}')

if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
print(f'Portfolio checks passed: {len(docs)} English pages, local links, anchors and assets.')
