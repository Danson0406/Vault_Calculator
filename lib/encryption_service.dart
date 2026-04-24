import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyStorage = 'vault_meta';

  static enc.Key? _sessionKey;

  // ─────────────────────────────
  // KEY DERIVATION
  // ─────────────────────────────

  static Uint8List _deriveKey(String pin, Uint8List salt) {
    final d = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    d.init(Pbkdf2Parameters(salt, 100000, 32));
    return d.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static Uint8List _hmac(Uint8List key, List<int> data) {
    final h = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    return h.process(Uint8List.fromList(data));
  }

  static bool _constantEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int r = 0;
    for (int i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }

  static Uint8List _random(int len) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(len, (_) => r.nextInt(256)));
  }

  // ─────────────────────────────
  // INIT VAULT
  // ─────────────────────────────

  static Future<void> initKey(String pin) async {
    final salt = _random(16);
    final key = _deriveKey(pin, salt);
    final verifier = _hmac(key, utf8.encode('vault-check'));

    final payload = {
      'salt': base64.encode(salt),
      'verifier': base64.encode(verifier),
    };

    await _storage.write(key: _keyStorage, value: jsonEncode(payload));

    // Set session key immediately after init so the vault is ready to use
    _sessionKey = enc.Key(key);
  }

  // ─────────────────────────────
  // UNLOCK VAULT
  // ─────────────────────────────

  /// Derives the key from [pin], verifies it against the stored HMAC verifier,
  /// and — on success — stores it as the in-memory session key.
  /// Throws an [Exception] if the vault is not initialised or the PIN is wrong.
  static Future<void> unlock(String pin) async {
    final raw = await _storage.read(key: _keyStorage);
    if (raw == null) throw Exception('Vault not initialized');

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final salt = base64.decode(data['salt'] as String);
    final storedVerifier = base64.decode(data['verifier'] as String);

    final keyBytes = _deriveKey(pin, Uint8List.fromList(salt));
    final check = _hmac(keyBytes, utf8.encode('vault-check'));

    if (!_constantEquals(storedVerifier, check)) {
      throw Exception('Invalid PIN');
    }

    _sessionKey = enc.Key(keyBytes);
  }

  // ─────────────────────────────
  // LOCK
  // ─────────────────────────────

  static void lock() {
    _sessionKey = null;
  }

  // ─────────────────────────────
  // DELETE KEY (for vault reset)
  // ─────────────────────────────

  static Future<void> deleteKey() async {
    _sessionKey = null;
    await _storage.delete(key: _keyStorage);
  }

  // ─────────────────────────────
  // ENCRYPT  (uses session key)
  // ─────────────────────────────

  static Future<Uint8List> encrypt(Uint8List data) async {
    if (_sessionKey == null) throw Exception('Vault locked');

    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(
      enc.AES(_sessionKey!, mode: enc.AESMode.gcm),
    );

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    // Layout: [12-byte IV] [ciphertext + 16-byte GCM tag]
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  // ─────────────────────────────
  // DECRYPT  (uses session key)
  // ─────────────────────────────

  static Future<Uint8List> decrypt(Uint8List data) async {
    if (_sessionKey == null) throw Exception('Vault locked');

    final iv = enc.IV(data.sublist(0, 12));
    final body = data.sublist(12);

    final encrypter = enc.Encrypter(
      enc.AES(_sessionKey!, mode: enc.AESMode.gcm),
    );

    final decrypted = encrypter.decryptBytes(enc.Encrypted(body), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  // ─────────────────────────────
  // FILE SYSTEM
  // ─────────────────────────────

  static Future<Directory> vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/vault_files');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> importFile({
    required File sourceFile,
    required String originalName,
    required String category,
  }) async {
    final dir = await vaultDir();
    final catDir = Directory('${dir.path}/$category');
    if (!await catDir.exists()) await catDir.create();

    final bytes = await sourceFile.readAsBytes();
    final encBytes = await encrypt(bytes);

    final safe = originalName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path =
        '${catDir.path}/${DateTime.now().millisecondsSinceEpoch}__$safe.venc';

    await File(path).writeAsBytes(encBytes);
    return path;
  }

  static Future<String> exportForViewing(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final decrypted = await decrypt(bytes);

    final tmp = await getTemporaryDirectory();
    final name =
        path.split('/').last.split('__').last.replaceAll('.venc', '');
    final out = '${tmp.path}/$name';

    await File(out).writeAsBytes(decrypted);
    return out;
  }

  static Future<List<VaultFile>> listFiles(String category) async {
    final dir = await vaultDir();
    final cat = Directory('${dir.path}/$category');

    if (!await cat.exists()) return [];

    final files = await cat.list().toList();
    final list = <VaultFile>[];

    for (final f in files) {
      if (f is File && f.path.endsWith('.venc')) {
        final stat = await f.stat();
        final name = f.path.split('/').last;
        list.add(VaultFile(
          encPath: f.path,
          displayName: name.split('__').last.replaceAll('.venc', ''),
          sizeBytes: stat.size,
          modified: stat.modified,
        ));
      }
    }

    return list;
  }

  static Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────

  static bool get isUnlocked => _sessionKey != null;
}

// ─────────────────────────────
// MODEL
// ─────────────────────────────

class VaultFile {
  final String encPath;
  final String displayName;
  final int sizeBytes;
  final DateTime modified;

  VaultFile({
    required this.encPath,
    required this.displayName,
    required this.sizeBytes,
    required this.modified,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}