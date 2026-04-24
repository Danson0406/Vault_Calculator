import 'package:vault_calculator/encryption_service.dart';

/// Thin session facade. The real session key lives inside [EncryptionService].
/// Use [VaultSession.isUnlocked] wherever you need to guard vault operations.
class VaultSession {
  VaultSession._();

  static bool get isUnlocked => EncryptionService.isUnlocked;

  /// Call after the user successfully logs out or the app goes to background.
  static void clear() => EncryptionService.lock();
}