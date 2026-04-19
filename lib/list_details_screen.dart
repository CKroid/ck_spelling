import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dictation_item.dart';
import 'dictation_provider.dart';
import 'session_screen.dart';

class ListDetailsScreen extends StatefulWidget {
  final String listId;

  const ListDetailsScreen({super.key, required this.listId});

  @override
  State<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<ListDetailsScreen> {
  final _addController = TextEditingController();
  final _addFocusNode = FocusNode();

  void _addItem() {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<DictationProvider>();
    final newItem = DictationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    );
    provider.addItemToList(widget.listId, newItem);
    _addController.clear();
    _addFocusNode.requestFocus(); // Keep focus for next entry
  }

  void _showEditDialog(BuildContext context, DictationItem item) {
    final textController = TextEditingController(text: item.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Word/Phrase'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Text'),
            autofocus: true,
            onSubmitted: (_) {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                final provider = context.read<DictationProvider>();
                final updatedItem = DictationItem(id: item.id, text: text);
                provider.updateItemInList(widget.listId, updatedItem);
                Navigator.pop(context);
              }
            },
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
                final updatedItem = DictationItem(id: item.id, text: text);
                provider.updateItemInList(widget.listId, updatedItem);
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
        final list = provider.getList(widget.listId);

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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _addController,
                  focusNode: _addFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Add word and press Enter',
                    hintText: 'Type here...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addItem,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addItem(),
                  autofocus: true,
                ),
              ),
              Expanded(
                child: list.items.isEmpty
                    ? const Center(
                        child: Text(
                          'No words added yet.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.items.length,
                        itemBuilder: (context, index) {
                          // Reverse the order to show new items at the top
                          final item = list.items[list.items.length - 1 - index];
                          return ListTile(
                            title: Text(item.text),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteItem(
                                context,
                                provider,
                                widget.listId,
                                item.id,
                              ),
                            ),
                            onTap: () => _showEditDialog(context, item),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }
}
