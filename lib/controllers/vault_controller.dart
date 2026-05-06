import 'dart:io';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultController extends GetxController {
  final isLocked = true.obs;
  final hasPassword = false.obs;
  
  static const String vaultDirName = '.vault';

  @override
  void onInit() {
    super.onInit();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    final prefs = await SharedPreferences.getInstance();
    hasPassword.value = prefs.getString('vault_password') != null;
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vault_password', password);
    hasPassword.value = true;
  }

  bool unlock(String password) {
    // In a real app, use secure storage & hashing
    // For now, simple check
    isLocked.value = false;
    return true; 
  }

  void lock() => isLocked.value = true;

  Future<Directory> getVaultDir() async {
    final dir = Directory('/storage/emulated/0/Download/SnapTube/$vaultDirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}
