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

    await _storage.write(
      key: _keyStorage,
      value: jsonEncode({
        'salt': base64.encode(salt),
        'verifier': base64.encode(verifier),
      }),
    );

    // Session key is set immediately so vault is ready after setup
    _sessionKey = enc.Key(key);
  }

  // ─────────────────────────────
  // UNLOCK
  // ─────────────────────────────

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
  // LOCK / DELETE KEY
  // ─────────────────────────────

  static void lock() => _sessionKey = null;

  /// Clears the in-memory session key and removes the stored
  /// salt/verifier from secure storage. Required by VaultService.resetVault().
  static Future<void> deleteKey() async {
    _sessionKey = null;
    await _storage.delete(key: _keyStorage);
  }

  static bool get isUnlocked => _sessionKey != null;

  // ─────────────────────────────
  // ENCRYPT / DECRYPT
  // ─────────────────────────────

  static Future<Uint8List> encrypt(Uint8List data) async {
    if (_sessionKey == null) throw Exception('Vault locked');

    final iv = enc.IV.fromSecureRandom(12);
    final encrypter =
        enc.Encrypter(enc.AES(_sessionKey!, mode: enc.AESMode.gcm));

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Layout: [12-byte IV][ciphertext + 16-byte GCM tag]
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  static Future<Uint8List> decrypt(Uint8List data) async {
    if (_sessionKey == null) throw Exception('Vault locked');

    final iv = enc.IV(data.sublist(0, 12));
    final body = data.sublist(12);

    final encrypter =
        enc.Encrypter(enc.AES(_sessionKey!, mode: enc.AESMode.gcm));

    return Uint8List.fromList(
      encrypter.decryptBytes(enc.Encrypted(body), iv: iv),
    );
  }

  // ─────────────────────────────
  // FILE SYSTEM
  // ─────────────────────────────

  /// Base vault directory. Public so folder screens can delete category dirs.
  static Future<Directory> vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/vault_files');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Encrypts [data] and writes into [category] subfolder.
  ///
  /// Filename format: {timestamp}_{random}__{originalName}.vault
  /// The original name is embedded after `__` so we can recover it later
  /// for display and so the OS knows which app to open the file with.
  static Future<String> importRawFile({
    required Uint8List data,
    required String originalName,
    required String category,
  }) async {
    final dir = await vaultDir();
    final catDir = Directory('${dir.path}/$category');
    if (!await catDir.exists()) await catDir.create(recursive: true);

    final encBytes = await encrypt(data);

    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random.secure().nextInt(999999);
    // Sanitise so the name is safe on all platforms
    final safeName = originalName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = '${catDir.path}/${ts}_${rnd}__$safeName.vault';

    await File(path).writeAsBytes(encBytes, flush: true);
    return path;
  }

  /// Decrypts the file at [encPath] to a temp file and returns the temp path.
  /// The original filename (with its extension) is recovered from [encPath]
  /// so that the OS opens it with the right app.
  static Future<String> exportForViewing(String encPath) async {
    final bytes = await File(encPath).readAsBytes();
    final decrypted = await decrypt(bytes);

    final tmp = await getTemporaryDirectory();

    // Recover original filename: everything after the first `__`, minus `.vault`
    final storedName = encPath.split('/').last;
    final sepIdx = storedName.indexOf('__');
    final originalName = sepIdx != -1
        ? storedName.substring(sepIdx + 2).replaceAll('.vault', '')
        : storedName.replaceAll('.vault', '');

    // Prefix with timestamp so multiple opens don't collide
    final out =
        '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName';
    await File(out).writeAsBytes(decrypted, flush: true);
    return out;
  }

  /// Lists all .vault files in [category], newest first.
  static Future<List<VaultFile>> listFiles(String category) async {
    final dir = await vaultDir();
    final catDir = Directory('${dir.path}/$category');
    if (!await catDir.exists()) return [];

    final list = <VaultFile>[];
    await for (final entity in catDir.list()) {
      if (entity is File && entity.path.endsWith('.vault')) {
        final stat = await entity.stat();
        final storedName = entity.path.split('/').last;

        // Recover display name from embedded original name
        final sepIdx = storedName.indexOf('__');
        final displayName = sepIdx != -1
            ? storedName.substring(sepIdx + 2).replaceAll('.vault', '')
            : storedName.replaceAll('.vault', '');

        list.add(VaultFile(
          encPath: entity.path,
          displayName: displayName,
          sizeBytes: stat.size,
          modified: stat.modified,
        ));
      }
    }

    list.sort((a, b) => b.modified.compareTo(a.modified));
    return list;
  }

  /// Permanently deletes the encrypted file at [path].
  static Future<void> deleteFile(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}

// ─────────────────────────────
// MODEL
// ─────────────────────────────

class VaultFile {
  final String encPath;
  final String displayName;
  final int sizeBytes;
  final DateTime modified;

  const VaultFile({
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