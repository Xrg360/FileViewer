import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readmine/pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FolderExplorer(),
    );
  }
}

class FolderExplorer extends StatefulWidget {
  const FolderExplorer({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FolderExplorerState createState() => _FolderExplorerState();
}

class _FolderExplorerState extends State<FolderExplorer> {
  List<FileSystemEntity> _folderContents = [];
  final List<String> _directoryStack = []; // Stack of visited directories

  Future<void> _chooseFolder([String? directoryPath]) async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    directoryPath ??= await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      Directory directory = Directory(directoryPath);
      List<FileSystemEntity> contents = directory.listSync().where((entity)=>entity is File && entity.path.endsWith('.md')).toList();
      if (contents.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Markdown files found')),
      );
    }
    else {
      setState(() {
        _folderContents = contents;
        _directoryStack.add(directoryPath!);
      });
    }
      // Save the selected directory path
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('directoryPath', directoryPath);
    } else {
       if (kDebugMode) {
         print('No directory selected!');
       }
    }
  }

  void _goBack() {
    if (_directoryStack.isNotEmpty) {
      _directoryStack.removeLast(); // Pop the last directory from the stack
      String lastDirectory = _directoryStack.isNotEmpty ? _directoryStack.last : '/';
      _chooseFolder(lastDirectory);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDirectoryPath();
  }

  Future<void> _loadDirectoryPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? directoryPath = prefs.getString('directoryPath');
    if (directoryPath != null) {
      _chooseFolder(directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Explorer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _chooseFolder,
            child: const Text('Choose Folder'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _folderContents.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = _folderContents[index];
                return ListTile(
                  title: Text(entity.path.split('/').last),
                  leading: Icon(
                    entity is Directory ? Icons.folder : Icons.file_copy,
                  ),
                  onTap: () {
                    if (entity is Directory) {
                      _chooseFolder(entity.path);
                    } else {
                      if (entity.path.endsWith('.md')) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarkdownViewScreen(entity.path),
                          ),
                        );
                      } else {
                        if (kDebugMode) {
                          print('Unsupported file type');
                        }
                      }
                    }
                  },
                  
                );
              },
            )
          ),
        ],
      ),
    );
  }
}
