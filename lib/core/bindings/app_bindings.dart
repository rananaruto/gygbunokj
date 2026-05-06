import 'package:get/get.dart';
import 'package:snaptube/controllers/download_controller.dart';
import 'package:snaptube/controllers/history_controller.dart';
import 'package:snaptube/controllers/home_controller.dart';

/// Registers all GetX controllers at app startup.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(DownloadController(), permanent: true);
    Get.lazyPut(() => HistoryController());
    Get.lazyPut(() => PremiumController());
  }
}
