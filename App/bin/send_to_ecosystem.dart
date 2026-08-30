// App/bin/send_to_ecosystem.dart
// Standalone background sender for Windows Explorer context menu ("Send to Ecosystem").
// Executes silently in the background with native toast notifications and zero GUI popup.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

void showWindowsNotification(String title, String message, {bool isSuccess = false}) {
  try {
    final cleanTitle = title.replaceAll('"', '`"').replaceAll("'", "`'");
    final cleanMsg = message.replaceAll('"', '`"').replaceAll("'", "`'");
    final sound = isSuccess ? '[System.Media.SystemSounds]::Asterisk.Play();' : '';
    
    Process.run('powershell', [
      '-NoProfile',
      '-WindowStyle', 'Hidden',
      '-Command',
      '''
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms");
\$notify = New-Object System.Windows.Forms.NotifyIcon;
\$notify.Icon = [System.Drawing.SystemIcons]::Information;
\$notify.Visible = \$true;
\$notify.ShowBalloonTip(4000, "$cleanTitle", "$cleanMsg", [System.Windows.Forms.ToolTipIcon]::Info);
$sound
'''
    ]);
  } catch (_) {}
}

class PeerTarget {
  final String ip;
  final int port;
  final String name;
  final String deviceId;
  final String platform;

  PeerTarget({
    required this.ip,
    required this.port,
    required this.name,
    required this.deviceId,
    required this.platform,
  });
}

Future<List<PeerTarget>> discoverPeers() async {
  final peers = <String, PeerTarget>{};
  RawDatagramSocket? socket;

  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final pingMsg = jsonEncode({
      'type': 'PING',
      'sourceDeviceId': 'win-cli-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    socket.send(utf8.encode(pingMsg), InternetAddress('255.255.255.255'), 42421);

    final sub = socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket?.receive();
        if (dg != null) {
          try {
            final text = utf8.decode(dg.data);
            final data = jsonDecode(text) as Map<String, dynamic>;
            final ip = dg.address.address;
            final name = data['displayName'] as String? ?? 'Device ($ip)';
            final devId = data['deviceId'] as String? ?? 'dev-$ip';
            final plat = data['platform'] as String? ?? 'unknown';
            final port = data['port'] as int? ?? 8080;

            if (ip != '127.0.0.1') {
              peers[ip] = PeerTarget(
                ip: ip,
                port: port,
                name: name,
                deviceId: devId,
                platform: plat,
              );
            }
          } catch (_) {}
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 600));
    await sub.cancel();
  } catch (_) {
  } finally {
    socket?.close();
  }

  // Quick fallback check against common local subnet IPs if broadcast didn't pick up yet
  if (peers.isEmpty) {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
              // Check active known targets
              for (final last in [147, 100, 101, 102, 103, 104, 105]) {
                final targetIp = '$prefix.$last';
                if (targetIp != addr.address) {
                  try {
                    final res = await http.get(Uri.parse('http://$targetIp:8080/api/status')).timeout(const Duration(milliseconds: 150));
                    if (res.statusCode == 200) {
                      peers[targetIp] = PeerTarget(
                        ip: targetIp,
                        port: 8080,
                        name: 'Ecosystem Device ($targetIp)',
                        deviceId: 'peer-$targetIp',
                        platform: 'android',
                      );
                    }
                  } catch (_) {}
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  return peers.values.toList();
}

Future<bool> sendFileToPeer(File file, PeerTarget target) async {
  final filename = p.basename(file.path);
  final totalBytes = await file.length();
  final url = Uri.parse('http://${target.ip}:${target.port}/api/transfer_stream');

  try {
    final req = http.StreamedRequest('POST', url);
    req.headers['X-Filename'] = Uri.encodeComponent(filename);
    req.headers['X-Total-Bytes'] = totalBytes.toString();
    req.headers['X-Sender-Device-Name'] = Uri.encodeComponent('Windows PC');
    req.headers['X-Sender-Device-Id'] = 'windows-context-menu';
    req.contentLength = totalBytes;

    final fileStream = file.openRead();
    fileStream.listen(
      (chunk) => req.sink.add(chunk),
      onDone: () => req.sink.close(),
      onError: (err) => req.sink.addError(err),
      cancelOnError: true,
    );

    final res = await req.send().timeout(const Duration(minutes: 5));
    if (res.statusCode == 200) {
      return true;
    }
  } catch (_) {
    // If HTTP fails, try TCP fallback on 51413
    try {
      final s = await Socket.connect(target.ip, 51413, timeout: const Duration(seconds: 2));
      final transferId = 'trans-${DateTime.now().millisecondsSinceEpoch}';
      final offer = {
        'version': 1,
        'type': 'transfer_offer',
        'messageId': 'msg-${DateTime.now().millisecondsSinceEpoch}',
        'sourceDeviceId': 'windows-context-menu',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'payload': {
          'transferId': transferId,
          'filename': filename,
          'mimeType': 'application/octet-stream',
          'totalBytes': totalBytes,
          'sha256Hash': '',
        }
      };
      s.write('${jsonEncode(offer)}\n');
      await s.flush();

      final bytes = await file.readAsBytes();
      const chunkSize = 64 * 1024;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        final chunkMsg = {
          'version': 1,
          'type': 'transfer_chunk',
          'messageId': 'chunk-$i',
          'sourceDeviceId': 'windows-context-menu',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'payload': {
            'transferId': transferId,
            'offset': i,
            'length': chunk.length,
            'data': base64Encode(chunk),
          }
        };
        s.write('${jsonEncode(chunkMsg)}\n');
        await s.flush();
      }

      final comp = {
        'version': 1,
        'type': 'transfer_complete',
        'messageId': 'comp-${DateTime.now().millisecondsSinceEpoch}',
        'sourceDeviceId': 'windows-context-menu',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'payload': {
          'transferId': transferId,
          'sha256Hash': '',
        }
      };
      s.write('${jsonEncode(comp)}\n');
      await s.flush();
      await s.close();
      return true;
    } catch (_) {}
  }

  return false;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    showWindowsNotification('Local Ecosystem', 'No file specified to send.');
    return;
  }

  final filesToSend = <File>[];
  for (final rawPath in args) {
    final clean = rawPath.replaceAll('"', '').trim();
    if (clean.isEmpty) continue;
    final f = File(clean);
    final d = Directory(clean);
    if (f.existsSync()) {
      filesToSend.add(f);
    } else if (d.existsSync()) {
      try {
        final entries = d.listSync(recursive: true);
        for (final entry in entries) {
          if (entry is File) filesToSend.add(entry);
        }
      } catch (_) {}
    }
  }

  if (filesToSend.isEmpty) {
    showWindowsNotification('Local Ecosystem', 'Could not locate selected file(s).');
    return;
  }

  final firstName = p.basename(filesToSend.first.path);
  final countStr = filesToSend.length > 1 ? ' (${filesToSend.length} files)' : '';
  showWindowsNotification('Send to Ecosystem', '🔍 Searching for active ecosystem devices…');

  final peers = await discoverPeers();
  if (peers.isEmpty) {
    showWindowsNotification(
      'Local Ecosystem',
      '⚠️ No active devices found on Wi-Fi.\nEnsure your Phone or iPad is on the same network.',
    );
    return;
  }

  int successCount = 0;
  for (final target in peers) {
    showWindowsNotification('Sending to ${target.name}', '🚀 Streaming "$firstName"$countStr…');
    bool allSent = true;
    for (final file in filesToSend) {
      final ok = await sendFileToPeer(file, target);
      if (!ok) allSent = false;
    }
    if (allSent) {
      successCount++;
    }
  }

  if (successCount > 0) {
    showWindowsNotification(
      'Sent to Ecosystem',
      '✅ Successfully shared "$firstName"$countStr to $successCount device(s)!',
      isSuccess: true,
    );
  } else {
    showWindowsNotification(
      'Transfer Failed',
      '❌ Could not complete transfer to detected devices.',
    );
  }
}
