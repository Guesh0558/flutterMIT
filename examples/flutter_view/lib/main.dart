// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FlutterView());
}

class FlutterView extends StatelessWidget {
  const FlutterView({super.key});

  // ADDRESSING INCONSISTENCY: Changed from 'My Flutter App' to 'Flutter View'
  static const String appTitle = 'Flutter View'; 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This now correctly uses 'Flutter View' for the system/task switcher
      title: appTitle, 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0553B1),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0553B1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: appTitle), 
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _channel = 'increment';
  static const String _pong = 'pong';
  static const String _emptyMessage = '';
  static const BasicMessageChannel<String?> platform = BasicMessageChannel<String?>(
    _channel,
    StringCodec(),
  );

  int _counter = 0;

  @override
  void initState() {
    super.initState();
    platform.setMessageHandler(_handlePlatformIncrement);
  }

  Future<String> _handlePlatformIncrement(String? message) async {
    setState(() {
      _counter++;
    });
    return _emptyMessage;
  }

  void _sendFlutterIncrement() {
    platform.send(_pong);
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        // This remains 'Flutter View' as it pulls from the constant above
        title: Text(widget.title), 
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset counter',
            onPressed: _resetCounter,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '$_counter',
                        key: ValueKey<int>(_counter),
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform button tapped $_counter time${_counter == 1 ? '' : 's'}.',
                      style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: scheme.surfaceContainerLow,
              child: Row(
                children: <Widget>[
                  Image.asset('assets/flutter-mark-square-64.png', scale: 1.5),
                  const SizedBox(width: 8),
                  Text(
                    'Flutter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendFlutterIncrement,
        icon: const Icon(Icons.touch_app),
        label: const Text('Ping Native'),
      ),
    );
  }
}