#!/usr/bin/env python3
"""Preview the walking prototype without exposing private project configuration."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import mimetypes
import argparse

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {
    '/': ROOT / 'design/walking-profile.html',
    '/walking-profile.html': ROOT / 'design/walking-profile.html',
    '/walking-profile.css': ROOT / 'design/walking-profile.css',
    '/walking-profile.js': ROOT / 'design/walking-profile.js',
    '/walking-profile-design.md': ROOT / 'docs/walking-profile-design.md',
    '/assets/fonts/Manrope.ttf': ROOT / 'assets/fonts/Manrope.ttf',
    '/assets/fonts/GolosText.ttf': ROOT / 'assets/fonts/GolosText.ttf',
    **{'/walking-assets/' + name: ROOT / 'design/walking-assets' / name
       for name in ('owner.jpg', 'helper.jpg', 'pet.jpg', 'lucide.min.js')},
}
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = ALLOWED.get(self.path.split('?', 1)[0])
        if path is None or not path.is_file():
            self.send_error(404)
            return
        content = path.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', mimetypes.guess_type(path.name)[0] or 'application/octet-stream')
        self.send_header('Content-Length', str(len(content)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(content)
    def log_message(self, *_):
        pass
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8768)
    args = parser.parse_args()
    print(f'Walking design: http://127.0.0.1:{args.port}/', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
