import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dictation_item.dart';
import 'dictation_provider.dart';
import 'session_screen.dart';

class ListDetailsScreen extends StatelessWidget {
  final String listId;

  const ListDetailsScreen({super.key, required this.listId});

  void _showItemDialog(BuildContext context, {DictationItem? item}) {
    final textController = TextEditingController(text: item?.text ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Add Word/Phrase' : 'Edit Word/Phrase'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Text'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isEmpty) return;

                final provider = context.read<DictationProvider>();
                if (item == null) {
                  final newItem = DictationItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    text: text,
                  );
                  provider.addItemToList(listId, newItem);
                } else {
                  final updatedItem = DictationItem(id: item.id, text: text);
                  provider.updateItemInList(listId, updatedItem);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    DictationProvider provider,
    String listId,
    String itemId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word?'),
        content: const Text(
          'Are you sure you want to delete this word from the list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      provider.deleteItemFromList(listId, itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictationProvider>(
      builder: (context, provider, child) {
        final list = provider.getList(listId);

        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('List not found')),
            body: const Center(
              child: Text('This list has been deleted or does not exist.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(list.title),
            actions: [
              if (list.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Start Spelling/Dictation',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionScreen(list: list),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: list.items.isEmpty
              ? const Center(
                  child: Text(
                    'No words added yet.\nTap + to add a word!',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: list.items.length,
                  itemBuilder: (context, index) {
                    final item = list.items[index];
                    return ListTile(
                      title: Text(item.text),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteItem(
                          context,
                          provider,
                          listId,
                          item.id,
                        ),
                      ),
                      onTap: () => _showItemDialog(context, item: item),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showItemDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
