import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'dictation_provider.dart';
import 'dictation_list.dart';
import 'list_details_screen.dart';
import 'session_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('dictation_box');

  final packageInfo = await PackageInfo.fromPlatform();

  runApp(
    ChangeNotifierProvider(
      create: (context) => DictationProvider(),
      child: MainApp(packageInfo: packageInfo),
    ),
  );
}

class MainApp extends StatelessWidget {
  final PackageInfo packageInfo;
  const MainApp({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CK Spelling',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Material(
          child: Column(
            children: [
              Expanded(child: child!), // The active screen
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'CK Spelling v${packageInfo.version}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showAddListDialog(BuildContext context) {
    final textController = TextEditingController();
    String selectedLanguage = 'en-US';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New List'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'List Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'en-US', child: Text('English')),
                      DropdownMenuItem(
                        value: 'zh-CN',
                        child: Text('Chinese (Simplified)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedLanguage = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isNotEmpty) {
                      final newList = DictationList(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: text,
                        languageCode: selectedLanguage,
                        items: [],
                        createdAt: DateTime.now(),
                      );
                      context.read<DictationProvider>().addList(newList);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteList(
    BuildContext context,
    DictationProvider provider,
    String listId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List?'),
        content: const Text(
          'Are you sure you want to delete this list? This action cannot be undone.',
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
      provider.deleteList(listId);
    }
  }

  Future<void> _exportData(
    BuildContext context,
    DictationProvider provider,
  ) async {
    final jsonStr = provider.exportToJson();
    final bytes = utf8.encode(jsonStr);

    await FileSaver.instance.saveFile(
      name: 'dictation_backup',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup downloaded successfully!')),
      );
    }
  }

  Future<void> _importData(
    BuildContext context,
    DictationProvider provider,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // FileType.any is much more reliable on Web browsers
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      // Manually verify it's a JSON file
      if (!result.files.single.name.toLowerCase().endsWith('.json')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .json file.')),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Ask user whether to append or overwrite
      final appendMode = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Options'),
          content: const Text(
            'Do you want to append these lists to your existing ones, or overwrite everything?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Overwrite'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Append'),
            ),
          ],
        ),
      );

      if (appendMode == null) return; // User cancelled

      final bytes = result.files.single.bytes!;
      final jsonStr = utf8.decode(bytes);
      final success = provider.importFromJson(jsonStr, append: appendMode);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Backup imported successfully!'
                  : 'Failed to import backup. Invalid JSON.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Spelling/Dictation Lists'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = context.read<DictationProvider>();
              if (value == 'export') {
                _exportData(context, provider);
              } else if (value == 'import') {
                _importData(context, provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Backup (.json)'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Backup (.json)'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<DictationProvider>(
        builder: (context, provider, child) {
          if (provider.lists.isEmpty) {
            return const Center(
              child: Text(
                'Your lists will appear here.\nTap + to create one!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.lists.length,
            itemBuilder: (context, index) {
              final list = provider.lists[index];
              return ListTile(
                title: Text(list.title),
                subtitle: Text(
                  '${list.items.length} items • ${list.languageCode == 'en-US' ? 'English' : 'Chinese'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit List',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListDetailsScreen(listId: list.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete List',
                      onPressed: () =>
                          _confirmDeleteList(context, provider, list.id),
                    ),
                  ],
                ),
                onTap: () {
                  if (list.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add words to this list first!'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionScreen(list: list),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
