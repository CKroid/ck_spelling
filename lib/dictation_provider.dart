import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dictation_item.dart';
import 'dictation_list.dart';

class DictationProvider extends ChangeNotifier {
  List<DictationList> _lists = [];
  final _box = Hive.box('dictation_box');

  DictationProvider() {
    _loadData();
  }

  List<DictationList> get lists => _lists;

  DictationList? getList(String id) {
    try {
      return _lists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  void _loadData() {
    final data = _box.get('lists', defaultValue: '[]');
    final List<dynamic> jsonList = jsonDecode(data);
    _lists = jsonList
        .map((e) => DictationList.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    notifyListeners();
  }

  void _saveData() {
    final jsonList = _lists.map((e) => e.toJson()).toList();
    _box.put('lists', jsonEncode(jsonList));
  }

  String exportToJson() {
    final jsonList = _lists.map((e) => e.toJson()).toList();
    return jsonEncode(jsonList);
  }

  bool importFromJson(String jsonString, {bool append = false}) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final importedLists = jsonList
          .map(
            (e) => DictationList.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (append) {
        for (var i = 0; i < importedLists.length; i++) {
          final list = importedLists[i];
          // Create a new ID to prevent conflicts with existing lists
          final newId = '${DateTime.now().microsecondsSinceEpoch}_$i';
          _lists.add(
            DictationList(
              id: newId,
              title: list.title,
              languageCode: list.languageCode,
              items: list.items,
              createdAt: list.createdAt,
            ),
          );
        }
      } else {
        _lists = importedLists;
      }

      _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import Error: $e');
      return false;
    }
  }

  void addList(DictationList list) {
    _lists.add(list);
    _saveData();
    notifyListeners();
  }

  void updateList(DictationList updatedList) {
    final index = _lists.indexWhere((list) => list.id == updatedList.id);
    if (index != -1) {
      _lists[index] = updatedList;
      _saveData();
      notifyListeners();
    }
  }

  void deleteList(String id) {
    _lists.removeWhere((list) => list.id == id);
    _saveData();
    notifyListeners();
  }

  void addItemToList(String listId, DictationItem item) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      _lists[listIndex].items.add(item);
      _saveData();
      notifyListeners();
    }
  }

  void updateItemInList(String listId, DictationItem updatedItem) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final itemIndex = _lists[listIndex].items.indexWhere(
        (i) => i.id == updatedItem.id,
      );
      if (itemIndex != -1) {
        _lists[listIndex].items[itemIndex] = updatedItem;
        _saveData();
        notifyListeners();
      }
    }
  }

  void deleteItemFromList(String listId, String itemId) {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      _lists[listIndex].items.removeWhere((i) => i.id == itemId);
      _saveData();
      notifyListeners();
    }
  }
}
