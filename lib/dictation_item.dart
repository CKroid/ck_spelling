class DictationItem {
  final String id;
  String text;

  DictationItem({required this.id, required this.text});

  // Convert to JSON for export and local storage
  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  // Create from JSON for import and loading from local storage
  factory DictationItem.fromJson(Map<String, dynamic> json) =>
      DictationItem(id: json['id'], text: json['text']);
}
