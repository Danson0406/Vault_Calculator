import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_service.dart';

class VaultService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _setupKey = 'vault_setup_complete';

  // ── Check setup ──────────────────────────────────────────────
  static Future<bool> isVaultSetup() async {
    return (await _storage.read(key: _setupKey)) == 'true';
  }

  // ── Create vault (first run) ─────────────────────────────────
  /// Derives the key from [pin], persists the verifier, and marks vault ready.
  /// initKey() also sets the session key so the vault is immediately unlocked.
  static Future<void> setPin(String pin) async {
    await EncryptionService.initKey(pin);
    await _storage.write(key: _setupKey, value: 'true');
  }

  // ── Verify PIN on login ──────────────────────────────────────
  /// Calls EncryptionService.unlock() which derives + verifies the key and
  /// stores it as the in-memory session key on success.
  static Future<bool> verifyPin(String pin) async {
    try {
      await EncryptionService.unlock(pin);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Lock session ─────────────────────────────────────────────
  static void lock() => EncryptionService.lock();

  // ── Reset everything ─────────────────────────────────────────
  static Future<void> resetVault() async {
    await _storage.deleteAll();

    try {
      final dir = await EncryptionService.vaultDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}

    // Wipes session key + removes the salt/verifier entry from secure storage
    await EncryptionService.deleteKey();
  }
}