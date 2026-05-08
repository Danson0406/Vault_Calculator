import 'encryption_service.dart';

class VaultSession {
  static bool get isUnlocked => EncryptionService.isUnlocked;

  static void clear() {
    EncryptionService.lock();
  }
}