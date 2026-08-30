// lib/application/silent_sender_cli.dart
// Built-in headless background sender for "local_ecosystem.exe --send <path>".
// Executes silently in the background with native toast notifications and zero GUI popup.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

void _log(String msg) {
  try {
    final tempDir = Directory.systemTemp.path;
    final logFile = File(p.join(tempDir, 'ecosystem_silent_send.log'));
    logFile.writeAsStringSync('[${DateTime.now().toIso8601String()}] $msg\n', mode: FileMode.append);
  } catch (_) {}
}

Future<void> _showWindowsNotification(String title, String message, {bool isSuccess = false}) async {
  try {
    _log('Notification: $title - $message');
    final cleanTitle = title.replaceAll('"', '`"').replaceAll("'", "`'");
    final cleanMsg = message.replaceAll('"', '`"').replaceAll("'", "`'");
    final sound = isSuccess ? '[System.Media.SystemSounds]::Asterisk.Play();' : '';

    await Process.run('powershell', [
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
Start-Sleep -Milliseconds 500
'''
    ]);
  } catch (_) {}
}

class _PeerTarget {
  final String ip;
  final int httpPort;
  final int tcpPort;
  final String name;
  final String deviceId;
  final String platform;

  _PeerTarget({
    required this.ip,
    required this.httpPort,
    required this.tcpPort,
    required this.name,
    required this.deviceId,
    required this.platform,
  });
}

Future<List<_PeerTarget>> _discoverPeers() async {
  final peers = <String, _PeerTarget>{};
  final localIps = <String>{'127.0.0.1'};
  final subnets = <String>{};

  try {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          localIps.add(addr.address);
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            subnets.add('${parts[0]}.${parts[1]}.${parts[2]}.');
          }
        }
      }
    }
  } catch (_) {}

  // 1. UDP Broadcast Discovery
  RawDatagramSocket? socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final pingMsg = jsonEncode({
      'type': 'PING',
      'deviceId': 'win-silent-sender',
      'sourceDeviceId': 'win-silent-sender',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    final pingBytes = utf8.encode(pingMsg);

    socket.send(pingBytes, InternetAddress('255.255.255.255'), 42421);
    for (final sub in subnets) {
      try {
        socket.send(pingBytes, InternetAddress('${sub}255'), 42421);
      } catch (_) {}
    }

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket?.receive();
        if (dg != null) {
          try {
            final text = utf8.decode(dg.data);
            final data = jsonDecode(text) as Map<String, dynamic>;
            final ip = dg.address.address;
            if (!localIps.contains(ip)) {
              final name = data['displayName'] as String? ?? 'Device ($ip)';
              final devId = data['deviceId'] as String? ?? 'dev-$ip';
              final plat = data['platform'] as String? ?? 'unknown';
              final port = data['port'] as int? ?? 51413;

              peers[ip] = _PeerTarget(
                ip: ip,
                httpPort: 8080,
                tcpPort: port,
                name: name,
                deviceId: devId,
                platform: plat,
              );
            }
          } catch (_) {}
        }
      }
    });
  } catch (_) {}

  // 2. Active Subnet Probing (Parallel HTTP check on ports 8080 & 8081)
  final probeFutures = <Future>[];
  for (final sub in subnets) {
    for (int i = 1; i <= 254; i++) {
      final targetIp = '$sub$i';
      if (!localIps.contains(targetIp)) {
        probeFutures.add(() async {
          for (final p in [8080, 8081]) {
            try {
              final uri = Uri.parse('http://$targetIp:$p/api/status');
              final res = await http.get(uri).timeout(const Duration(milliseconds: 700));
              if (res.statusCode == 200) {
                final data = jsonDecode(res.body) as Map<String, dynamic>;
                final hostName = data['hostDeviceName'] as String? ?? 'Device';
                final devId = data['deviceId'] as String? ?? 'peer-$targetIp';
                final plat = data['platform'] as String? ?? 'android';
                final portalPort = (data['portalPort'] as num?)?.toInt() ?? p;

                peers[targetIp] = _PeerTarget(
                  ip: targetIp,
                  httpPort: portalPort,
                  tcpPort: 51413,
                  name: hostName,
                  deviceId: devId,
                  platform: plat,
                );
                return;
              }
            } catch (_) {}
          }
        }());
      }
    }
  }

  // Wait for UDP responses and HTTP subnet probes
  await Future.wait([
    Future.delayed(const Duration(milliseconds: 900)),
    Future.wait(probeFutures),
  ]);

  try {
    socket?.close();
  } catch (_) {}

  return peers.values.toList();
}

Future<bool> _sendFileToPeer(File file, _PeerTarget target) async {
  final filename = p.basename(file.path);
  final totalBytes = await file.length();

  _log('Sending "$filename" ($totalBytes bytes) to ${target.name} @ ${target.ip}');

  // Try HTTP Streamed Upload first
  for (final port in [target.httpPort, 8080, 8081, 8082]) {
    try {
      final url = Uri.parse('http://${target.ip}:$port/api/transfer_stream');
      final req = http.StreamedRequest('POST', url);
      req.headers['X-Filename'] = Uri.encodeComponent(filename);
      req.headers['X-Total-Bytes'] = totalBytes.toString();
      req.headers['X-Sender-Device-Name'] = Uri.encodeComponent('Windows PC');
      req.headers['X-Sender-Device-Id'] = 'windows-context-menu';
      req.contentLength = totalBytes;

      file.openRead().pipe(req.sink);

      final res = await req.send().timeout(const Duration(minutes: 5));
      if (res.statusCode == 200) {
        _log('HTTP transfer success on port $port');
        return true;
      }
    } catch (e) {
      _log('HTTP transfer failed on port $port: $e');
    }
  }

  // TCP Socket Fallback (Port 51413)
  try {
    _log('Attempting TCP socket transfer to ${target.ip}:${target.tcpPort}');
    final s = await Socket.connect(target.ip, target.tcpPort, timeout: const Duration(seconds: 4));
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
        'senderDeviceName': 'Windows PC',
      }
    };
    s.write('${jsonEncode(offer)}\n');
    await s.flush();

    // Stream chunks
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
    await Future.delayed(const Duration(milliseconds: 300));
    await s.close();
    _log('TCP transfer complete');
    return true;
  } catch (e) {
    _log('TCP transfer error: $e');
  }

  return false;
}

Future<void> executeSilentBackgroundSend(List<String> rawPaths) async {
  _log('executeSilentBackgroundSend started with paths: $rawPaths');
  if (rawPaths.isEmpty) {
    await _showWindowsNotification('Local Ecosystem', 'No file specified to send.');
    return;
  }

  final filesToSend = <File>[];
  for (final rawPath in rawPaths) {
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
    _log('No files found at specified paths');
    await _showWindowsNotification('Local Ecosystem', 'Could not locate selected file(s).');
    return;
  }

  final firstName = p.basename(filesToSend.first.path);
  final countStr = filesToSend.length > 1 ? ' (${filesToSend.length} files)' : '';
  await _showWindowsNotification('Send to Ecosystem', '🔍 Searching for active ecosystem devices…');

  final peers = await _discoverPeers();
  _log('Discovered peers count: ${peers.length}');
  if (peers.isEmpty) {
    await _showWindowsNotification(
      'Local Ecosystem',
      '⚠️ No active devices found on Wi-Fi.\nEnsure Local Ecosystem is open on your Phone or iPad.',
    );
    return;
  }

  int successCount = 0;
  for (final target in peers) {
    await _showWindowsNotification('Sending to ${target.name}', '🚀 Streaming "$firstName"$countStr…');
    bool allSent = true;
    for (final file in filesToSend) {
      final ok = await _sendFileToPeer(file, target);
      if (!ok) allSent = false;
    }
    if (allSent) {
      successCount++;
    }
  }

  if (successCount > 0) {
    _log('Silent send SUCCESS to $successCount device(s)');
    await _showWindowsNotification(
      'Sent to Ecosystem',
      '✅ Successfully shared "$firstName"$countStr to $successCount device(s)!',
      isSuccess: true,
    );
  } else {
    _log('Silent send FAILED to all devices');
    await _showWindowsNotification(
      'Transfer Failed',
      '❌ Could not complete transfer to detected devices.',
    );
  }
}
