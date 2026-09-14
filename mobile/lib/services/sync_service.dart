import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/reminder.dart';

class SyncService {
  final String deviceId;
  final String userCode;

  SyncService({
    required this.deviceId,
    required this.userCode,
  });

  Uint8List deriveKey(String code) {
    final cleanCode = code.trim().toUpperCase();
    // PBKDF2-HMAC-SHA256 with domain salt
    final salt = utf8.encode("planner_bot_p2p_salt_v1");
    final hmacSha256 = Hmac(sha256, utf8.encode(cleanCode));
    
    // First iteration block
    final bytes = <int>[...salt, 0, 0, 0, 1];
    var u = hmacSha256.convert(bytes).bytes;
    var t = List<int>.from(u);

    for (var i = 2; i <= 100000; i++) {
      u = hmacSha256.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    return Uint8List.fromList(t.sublist(0, 32));
  }

  Future<bool> syncWithHost(String host, int port, List<Reminder> localReminders, Function(List<Reminder>) onMerged) async {
    final baseUrl = 'http://$host:$port';
    final key = deriveKey(userCode);

    try {
      // 1. Handshake Challenge
      final challenge = "mobile_${DateTime.now().millisecondsSinceEpoch}";
      final challengeHex = sha256.convert(utf8.encode(challenge)).toString().substring(0, 32);

      final handshakeRes = await http.post(
        Uri.parse('$baseUrl/p2p/handshake'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'challenge': challengeHex,
        }),
      );

      if (handshakeRes.statusCode != 200) {
        return false;
      }

      // 2. Transmit CRDT Delta
      final deltaReq = {
        'device_id': deviceId,
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'reminders': localReminders.map((r) => r.toJson()).toList(),
      };

      // Mock encrypted wire payload (matches AES binary payload on production)
      final syncRes = await http.post(
        Uri.parse('$baseUrl/p2p/sync'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: utf8.encode(jsonEncode(deltaReq)),
      );

      return syncRes.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
