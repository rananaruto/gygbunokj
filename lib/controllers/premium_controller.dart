import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumController extends GetxController {
  final isPro = false.obs;
  final dailyDownloadCount = 0.obs;
  
  static const int freeLimit = 5;

  @override
  void onInit() {
    super.onInit();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isPro.value = prefs.getBool('is_pro') ?? false;
    
    // Simple daily reset logic (could be more robust with timestamps)
    final lastDate = prefs.getString('last_download_date') ?? '';
    final today = DateTime.now().toIso8601String().split('T').first;
    
    if (lastDate != today) {
      dailyDownloadCount.value = 0;
      await prefs.setString('last_download_date', today);
      await prefs.setInt('download_count', 0);
    } else {
      dailyDownloadCount.value = prefs.getInt('download_count') ?? 0;
    }
  }

  bool canDownload() {
    if (isPro.value) return true;
    return dailyDownloadCount.value < freeLimit;
  }

  Future<void> incrementDownload() async {
    if (isPro.value) return;
    dailyDownloadCount.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('download_count', dailyDownloadCount.value);
  }

  Future<void> activatePro() async {
    isPro.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);
  }
}
