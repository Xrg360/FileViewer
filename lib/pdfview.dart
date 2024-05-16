import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownViewScreen extends StatefulWidget {
  final String path;

  const MarkdownViewScreen(this.path, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MarkdownViewScreenState createState() => _MarkdownViewScreenState();
}

class _MarkdownViewScreenState extends State<MarkdownViewScreen> {
  String _markdownData = '';

  @override
  void initState() {
    super.initState();
    _loadMarkdownData();
  }

  Future<void> _loadMarkdownData() async {
    String markdownData;
    try {
      markdownData = await File(widget.path).readAsString();
    } catch (e) {
      markdownData = 'Error loading file: $e';
    }
    setState(() {
      _markdownData = markdownData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown View'),
      ),
      body: Markdown(
        data: _markdownData,
      ),
    );
  }
}