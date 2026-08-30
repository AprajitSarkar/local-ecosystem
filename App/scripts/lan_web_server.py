#!/usr/bin/env python3
"""
scripts/lan_web_server.py
Lightweight, high-performance LAN web server for Local Ecosystem PWA.
Serves the Flutter Web bundle with proper MIME types, CORS, and caching headers.
"""

import http.server
import socketserver
import os
import sys

WEB_DIR = "/home/aprajit/Cozmo/ipad/build_artifacts/web"
PORT = 8080

class EcosystemHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Enable CORS and service-worker / PWA friendly headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.end_headers()

def main():
    os.chdir(WEB_DIR)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), EcosystemHTTPHandler) as httpd:
        print(f"🚀 Local Ecosystem Web App running at:")
        print(f"   📱 iPad / Mobile Safari : http://192.168.1.153:{PORT}")
        print(f"   💻 Local PC             : http://localhost:{PORT}")
        sys.stdout.flush()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")

if __name__ == '__main__':
    main()
