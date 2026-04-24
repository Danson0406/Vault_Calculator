import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vault_calculator/encryption_service.dart';

class VaultService {
  static const _storage = FlutterSecureStorage();
  static const _setupKey = 'vault_setup_complete';

  // ─────────────────────────────
  // CHECK SETUP
  // ─────────────────────────────

  static Future<bool> isVaultSetup() async {
    return (await _storage.read(key: _setupKey)) == 'true';
  }

  // ─────────────────────────────
  // CREATE VAULT
  // ─────────────────────────────

  /// Derives and stores the key for [pin], then marks the vault as set up.
  /// Also unlocks the session immediately so the vault is ready after setup.
  static Future<void> setPin(String pin) async {
    await EncryptionService.initKey(pin); // derives key + stores salt/verifier
    await _storage.write(key: _setupKey, value: 'true');
    // initKey already sets _sessionKey, so the vault is unlocked right away.
  }

  // ─────────────────────────────
  // VERIFY PIN
  // ─────────────────────────────

  /// Attempts to unlock the vault with [pin].
  /// Returns `true` and keeps the session key set on success.
  /// Returns `false` and leaves the session key unchanged on failure.
  static Future<bool> verifyPin(String pin) async {
    try {
      await EncryptionService.unlock(pin);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────
  // LOCK
  // ─────────────────────────────

  static void lock() {
    EncryptionService.lock();
  }

  // ─────────────────────────────
  // RESET VAULT
  // ─────────────────────────────

  static Future<void> resetVault() async {
    await _storage.deleteAll();
    await EncryptionService.deleteKey(); // clears session key + secure storage entry

    try {
      final dir = await EncryptionService.vaultDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}