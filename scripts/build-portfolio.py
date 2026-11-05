#!/usr/bin/env python3
"""Generate browser entry points for the current Flutter layout adaptation."""
from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]


def render(assets: str, home: str) -> str:
    fragment = (ROOT / 'design/prototype.fragment.html').read_text()
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Explore an English browser adaptation of PetFriendly’s current Flutter screens. Fictional demo data; no backend connection.">
<meta name="theme-color" content="#f9f9f6">
<title>PetFriendly — Interactive Prototype</title>
<link rel="icon" href="{assets}/favicon.svg" type="image/svg+xml">
<style>
@font-face{{font-family:Manrope;src:url('{assets}/Manrope.ttf') format('truetype');font-weight:200 800;font-display:swap}}
@font-face{{font-family:'Golos Text';src:url('{assets}/GolosText.ttf') format('truetype');font-weight:400 900;font-display:swap}}
:root{{color-scheme:light;background:#f9f9f6;color:#20251e;font:14px/1.6 'Golos Text',sans-serif}}body{{margin:0}}a{{color:inherit;text-underline-offset:4px}}::selection{{background:#d6ed8a;color:#253314}}a:focus-visible,button:focus-visible{{outline:2px solid #587322;outline-offset:4px}}
.demo-toolbar{{display:flex;flex-wrap:wrap;align-items:center;gap:16px;justify-content:space-between;max-width:1000px;margin:auto;padding:24px}}.demo-toolbar button{{font:inherit;border:1px solid #d4dacb;border-radius:12px;background:transparent;padding:10px 16px;color:inherit;cursor:pointer}}.demo-heading{{max-width:620px;margin:12px auto 0;padding:0 24px;text-align:center}}.demo-heading h1{{font:600 32px/1.2 Manrope,sans-serif;letter-spacing:-.03em;margin:12px 0}}.demo-heading p{{color:#62695c;margin:12px 0}}.demo-heading details{{text-align:left;margin-top:20px}}.demo-heading summary{{cursor:pointer;min-height:44px;display:list-item;align-content:center}}.demo-heading li{{margin-bottom:8px}}.demo-heading ul{{padding-left:22px}}.demo-footer{{padding:0 24px 32px;text-align:center;color:#62695c;font-size:12px}}html.embed{{background:transparent}}.embed .demo-toolbar,.embed .demo-heading,.embed .demo-footer{{display:none}}
</style>
<link rel="stylesheet" href="{assets}/prototype.css">
<script>if(new URLSearchParams(location.search).get('embed')==='1')document.documentElement.classList.add('embed');</script>
<script src="{assets}/lucide.min.js" defer></script>
<script src="{assets}/prototype.js" defer></script>
</head>
<body>
<div class="demo-toolbar"><a href="{home}">← Back to the case study</a><button type="button" id="reset-demo">Reset demo</button></div>
<div class="demo-heading"><h1>Take a look around.</h1><p>An English browser adaptation of the current Flutter layouts. Fictional data, with no account or backend connection.</p><details><summary>What can I try?</summary><ul><li><strong>Nearby:</strong> open meetups, select a city or browse the separate places list.</li><li><strong>People:</strong> search people, switch to communities and start a conversation.</li><li><strong>Walking:</strong> inspect a request, offer help or create a demo request.</li><li><strong>Chats:</strong> use the compose action or start with the empty-state guidance.</li><li><strong>Profile:</strong> edit identity and pet details, view saved places and open settings.</li></ul><p>Theme, city, tab and saved places persist in this browser. Messages, edits and participation remain in memory. Messages are never sent to another person.</p><p>The native map requires Mapbox. This preview shows the app’s unavailable-map layout and places-list fallback. Native authentication, media, live services and all secondary screens are outside this adaptation.</p></details></div>
{fragment}
<p class="demo-footer">Current Flutter screen structure, adapted for the browser.<br><a href="https://github.com/lambda2331/PetFriendly">Explore the native implementation on GitHub</a></p>
</body>
</html>
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Fail if generated files are stale')
    args = parser.parse_args()
    outputs = {
        ROOT / 'portfolio/prototype.html': render('assets', './'),
        ROOT / 'design/prototype.html': render('../portfolio/assets', '../portfolio/'),
    }
    stale = []
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.write_text(content)
            print(f'Generated {path.relative_to(ROOT)}')
    if stale:
        print('Run python3 scripts/build-portfolio.py; stale files: ' + ', '.join(stale), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
