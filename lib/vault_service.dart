import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_service.dart';

class VaultService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _setupKey = 'vault_setup_complete';

  static Future<bool> isVaultSetup() async {
    return (await _storage.read(key: _setupKey)) == 'true';
  }

  static Future<void> setPin(String pin) async {
    await EncryptionService.initKey(pin);
    await _storage.write(key: _setupKey, value: 'true');
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      await EncryptionService.unlock(pin);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void lock() {
    EncryptionService.lock();
  }

  static Future<void> resetVault() async {
    await _storage.deleteAll();

    try {
      final dir = await EncryptionService.vaultDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}

    await EncryptionService.deleteKey();
  }
}