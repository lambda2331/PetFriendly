"""Sync the embedded review registry from its canonical JSON; no browser/backend work."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'design/onboarding-unified-account-2026-10-14'
frames=json.loads((root/'workflow-additions.json').read_text())
assert len({f['id'] for f in frames})==len(frames)
js=root/'workflow-additions.js'
source=js.read_text();marker='\nlet additionCurrent;';assert marker in source
js.write_text('const workflowAdditionFrames='+json.dumps(frames,ensure_ascii=False)+';'+source[source.index(marker):])
print(f'Synced {len(frames)} review states; renderer behavior retained.')
