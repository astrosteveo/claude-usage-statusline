#!/usr/bin/env python3
"""
Local server that receives usage data from browser and saves it.
Part of claude-usage-statusline.

Usage:
    python3 usage_server.py
    # Then click the bookmarklet in your browser while on claude.ai
"""

import json
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

PORT = int(os.environ.get('CLAUDE_USAGE_PORT', 9847))
CACHE_FILE = Path(os.environ.get('CLAUDE_USAGE_CACHE', Path.home() / '.claude' / 'usage_cache.json'))


class UsageHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', 'https://claude.ai')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        """Receive and save usage data."""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body)

            # Save to cache file
            CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(CACHE_FILE, 'w') as f:
                json.dump(data, f, indent=2)

            # Send success response
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', 'https://claude.ai')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'ok', 'saved_to': str(CACHE_FILE)}).encode())

            # Log update
            five_hour = data.get('five_hour', {}).get('utilization', 0)
            seven_day = data.get('seven_day', {}).get('utilization', 0)
            seven_day_sonnet = data.get('seven_day_sonnet', {}).get('utilization', 0)
            print(f"[{self.log_date_time_string()}] Updated: 5h={five_hour:.0f}% 7d={seven_day:.0f}% Son={seven_day_sonnet:.0f}%")

        except Exception as e:
            self.send_response(500)
            self.send_header('Access-Control-Allow-Origin', 'https://claude.ai')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
            print(f"Error: {e}")

    def log_message(self, format, *args):
        pass  # Suppress default logging


def main():
    print(f"Claude Usage Cache Server")
    print(f"=" * 40)
    print(f"Port: {PORT}")
    print(f"Cache: {CACHE_FILE}")
    print()
    print("Create a bookmarklet with your org ID:")
    print("javascript:(async()=>{const r=await fetch('/api/organizations/YOUR_ORG_ID/usage',{credentials:'include'});const d=await r.json();await fetch('http://localhost:9847/',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d)});alert('Updated!')})()")
    print()
    print("Waiting for updates... (Ctrl+C to stop)")
    print()

    server = HTTPServer(('127.0.0.1', PORT), UsageHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")


if __name__ == '__main__':
    main()
