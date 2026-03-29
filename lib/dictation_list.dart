import 'dictation_item.dart';

class DictationList {
  final String id;
  String title;
  String languageCode;
  List<DictationItem> items;
  final DateTime createdAt;

  DictationList({
    required this.id,
    required this.title,
    required this.languageCode,
    required this.items,
    required this.createdAt,
  });

  // Convert to JSON for export and local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'languageCode': languageCode,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  // Create from JSON for import and loading from local storage
  factory DictationList.fromJson(Map<String, dynamic> json) => DictationList(
    id: json['id'],
    title: json['title'],
    languageCode: json['languageCode'] ?? 'en-US',
    items: (json['items'] as List)
        .map(
          (item) =>
              DictationItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
