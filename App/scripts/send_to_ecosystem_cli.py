#!/usr/bin/env python3
# scripts/send_to_ecosystem_cli.py
# Right-click context menu & CLI tool to send files/links directly to Local Ecosystem.

import os
import sys
import json
import socket
import base64
import hashlib
import time
import subprocess

def notify(title, message):
    try:
        subprocess.run(["notify-send", "-a", "Local Ecosystem", title, message])
    except Exception:
        pass

def discover_peers():
    peers = set()
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        s.settimeout(0.6)
        ping = json.dumps({"type": "PING", "deviceId": "linux-cli"}).encode('utf-8')
        s.sendto(ping, ('255.255.255.255', 42421))
        
        start = time.time()
        while time.time() - start < 0.6:
            try:
                data, addr = s.recvfrom(2048)
                ip = addr[0]
                if ip and ip != '127.0.0.1':
                    peers.add(ip)
            except Exception:
                break
        s.close()
    except Exception:
        pass
    return list(peers)

def send_link(url, peers):
    payload = json.dumps({
        "type": "LINK_SHARE",
        "url": url,
        "deviceName": "Linux Laptop",
        "deviceId": "linux-cli",
        "timestamp": int(time.time() * 1000)
    }).encode('utf-8')

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.sendto(payload, ('255.255.255.255', 42421))
    for p in peers:
        try:
            s.sendto(payload, (p, 42421))
        except Exception:
            pass
    s.close()
    notify("Link Shared to Ecosystem", f"Opening on devices: {url}")

def send_file(file_path, peers):
    if not os.path.exists(file_path):
        notify("Send Failed", f"File not found: {file_path}")
        return

    filename = os.path.basename(file_path)
    file_size = os.path.getsize(file_path)
    transfer_id = f"cli-{int(time.time())}"

    with open(file_path, "rb") as f:
        content = f.read()

    sha = hashlib.sha256(content).hexdigest()

    success_count = 0
    for peer_ip in peers:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(10)
            s.connect((peer_ip, 51413))

            # 1. Offer
            offer = {
                "version": 1,
                "type": "transfer_offer",
                "messageId": f"msg-offer-{transfer_id}",
                "sourceDeviceId": "linux-cli",
                "timestamp": int(time.time() * 1000),
                "payload": {
                    "transferId": transfer_id,
                    "filename": filename,
                    "mimeType": "application/octet-stream",
                    "totalBytes": file_size,
                    "sha256Hash": sha
                }
            }
            s.sendall((json.dumps(offer) + '\n').encode('utf-8'))

            # Wait for accept
            resp = s.recv(4096).decode('utf-8', errors='ignore')

            # 2. Chunk streaming
            chunk_size = 64 * 1024
            offset = 0
            while offset < len(content):
                chunk_data = content[offset:offset + chunk_size]
                chunk = {
                    "version": 1,
                    "type": "transfer_chunk",
                    "messageId": f"msg-chunk-{offset}",
                    "sourceDeviceId": "linux-cli",
                    "timestamp": int(time.time() * 1000),
                    "payload": {
                        "transferId": transfer_id,
                        "offset": offset,
                        "length": len(chunk_data),
                        "data": base64.b64encode(chunk_data).decode('ascii')
                    }
                }
                s.sendall((json.dumps(chunk) + '\n').encode('utf-8'))
                offset += len(chunk_data)
                time.sleep(0.01)

            # 3. Complete
            complete = {
                "version": 1,
                "type": "transfer_complete",
                "messageId": f"msg-complete-{transfer_id}",
                "sourceDeviceId": "linux-cli",
                "timestamp": int(time.time() * 1000),
                "payload": {
                    "transferId": transfer_id,
                    "sha256Hash": sha
                }
            }
            s.sendall((json.dumps(complete) + '\n').encode('utf-8'))
            time.sleep(0.5)
            s.close()
            success_count += 1
        except Exception as e:
            print(f"Failed to send to {peer_ip}: {e}")

    if success_count > 0:
        notify("Sent to Ecosystem", f"Successfully shared '{filename}' to {success_count} device(s)!")
    else:
        notify("Send to Ecosystem", f"Could not connect to ecosystem devices for '{filename}'.")

def main():
    items = sys.argv[1:]
    if not items:
        # Check if clipboard has a link or file
        try:
            cb = subprocess.check_output(["xclip", "-selection", "clipboard", "-o"]).decode('utf-8').strip()
            if cb.startswith("http://") or cb.startswith("https://"):
                items = [cb]
        except Exception:
            pass

    if not items:
        notify("Local Ecosystem", "No files or links provided to send.")
        return

    peers = discover_peers()
    if not peers:
        peers = ['192.168.1.147'] # Fallback to known Android IP

    for item in items:
        if item.startswith("http://") or item.startswith("https://"):
            send_link(item, peers)
        else:
            send_file(item, peers)

if __name__ == "__main__":
    main()
