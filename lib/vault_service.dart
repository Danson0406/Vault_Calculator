import 'package:shared_preferences/shared_preferences.dart';

class VaultService {
  static const String _pinKey = 'vault_pin';
  static const String _isSetupKey = 'vault_setup_complete';

  static Future<bool> isVaultSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSetupKey) ?? false;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_isSetupKey, true);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    return storedPin == pin;
  }

  static Future<void> resetVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_isSetupKey);
  }
}