import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class VaultFile {
  final String displayName;
  final String encPath;
  final int size;

  const VaultFile({
    required this.displayName,
    required this.encPath,
    required this.size,
  });

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EncryptionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _saltKey = 'vault_salt';
  static const String _verifierKey = 'vault_verifier';

  static enc.Key? _sessionKey;

  static bool get isUnlocked => _sessionKey != null;

  static Future<Directory> vaultDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/vault_files');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _deriveKey(String pin, List<int> salt) {
    var data = utf8.encode(pin) + salt;

    for (int i = 0; i < 10000; i++) {
      data = sha256.convert(data).bytes;
    }

    return data;
  }

  static String _verifier(List<int> keyBytes) {
    return base64Encode(sha256.convert(keyBytes).bytes);
  }

  static Future<void> initKey(String pin) async {
    final salt = _randomBytes(16);
    final keyBytes = _deriveKey(pin, salt);

    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _verifierKey, value: _verifier(keyBytes));

    _sessionKey = enc.Key(Uint8List.fromList(keyBytes));
  }

  static Future<void> unlock(String pin) async {
    final saltText = await _storage.read(key: _saltKey);
    final verifierText = await _storage.read(key: _verifierKey);

    if (saltText == null || verifierText == null) {
      throw Exception('Vault is not set up.');
    }

    final salt = base64Decode(saltText);
    final keyBytes = _deriveKey(pin, salt);
    final check = _verifier(keyBytes);

    if (check != verifierText) {
      throw Exception('Wrong PIN.');
    }

    _sessionKey = enc.Key(Uint8List.fromList(keyBytes));
  }

  static void lock() {
    _sessionKey = null;
  }

  static Future<void> deleteKey() async {
    _sessionKey = null;
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _verifierKey);
  }

  static String _safeName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<void> importFile({
    required File sourceFile,
    required String originalName,
    required String category,
  }) async {
    final key = _sessionKey;

    if (key == null) {
      throw Exception('Vault is locked.');
    }

    final bytes = await sourceFile.readAsBytes();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final root = await vaultDir();
    final categoryDir = Directory('${root.path}/$category');

    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeOriginal = _safeName(originalName);
    final encryptedPath = '${categoryDir.path}/${timestamp}_$safeOriginal.vault';
    final metaPath = '$encryptedPath.meta';

    await File(encryptedPath).writeAsBytes([
      ...iv.bytes,
      ...encrypted.bytes,
    ]);

    await File(metaPath).writeAsString(
      jsonEncode({
        'originalName': originalName,
        'size': bytes.length,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  static Future<List<VaultFile>> listFiles(String category) async {
    final root = await vaultDir();
    final categoryDir = Directory('${root.path}/$category');

    if (!await categoryDir.exists()) {
      return [];
    }

    final items = categoryDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.vault'))
        .toList();

    final files = <VaultFile>[];

    for (final file in items) {
      String name = file.uri.pathSegments.last.replaceAll('.vault', '');
      int size = await file.length();

      final meta = File('${file.path}.meta');

      if (await meta.exists()) {
        try {
          final data = jsonDecode(await meta.readAsString());
          name = data['originalName'] ?? name;
          size = data['size'] ?? size;
        } catch (_) {}
      }

      files.add(
        VaultFile(
          displayName: name,
          encPath: file.path,
          size: size,
        ),
      );
    }

    files.sort((a, b) => b.encPath.compareTo(a.encPath));
    return files;
  }

  static Future<String> exportForViewing(String encPath) async {
    final key = _sessionKey;

    if (key == null) {
      throw Exception('Vault is locked.');
    }

    final file = File(encPath);
    final allBytes = await file.readAsBytes();

    if (allBytes.length <= 16) {
      throw Exception('Invalid encrypted file.');
    }

    final ivBytes = allBytes.sublist(0, 16);
    final encryptedBytes = allBytes.sublist(16);

    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key));

    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(encryptedBytes)),
      iv: iv,
    );

    String originalName = 'vault_file';

    final meta = File('$encPath.meta');

    if (await meta.exists()) {
      try {
        final data = jsonDecode(await meta.readAsString());
        originalName = data['originalName'] ?? originalName;
      } catch (_) {}
    }

    final temp = await getTemporaryDirectory();
    final safeOriginal = _safeName(originalName);
    final outPath =
        '${temp.path}/${DateTime.now().millisecondsSinceEpoch}_$safeOriginal';

    await File(outPath).writeAsBytes(decrypted);
    return outPath;
  }

  static Future<void> deleteFile(String encPath) async {
    final file = File(encPath);
    final meta = File('$encPath.meta');

    if (await file.exists()) {
      await file.delete();
    }

    if (await meta.exists()) {
      await meta.delete();
    }
  }
}