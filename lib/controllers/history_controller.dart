import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaptube/models/history_item_model.dart';

/// Manages download history — persisted to SharedPreferences as JSON.
class HistoryController extends GetxController {
  static const _key = 'snaptube_history';

  final RxList<HistoryItemModel> history = <HistoryItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  /// Add a completed download to history
  void addToHistory(HistoryItemModel item) {
    history.insert(0, item); // newest first
    _saveHistory();
  }

  /// Remove a specific item
  void removeFromHistory(HistoryItemModel item) {
    history.remove(item);
    _saveHistory();
  }

  /// Clear all history
  void clearHistory() {
    history.clear();
    _saveHistory();
  }

  // ── Persistence ───────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => HistoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      history.assignAll(list);
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_key, encoded);
    } catch (_) {}
  }
}
