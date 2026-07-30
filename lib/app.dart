import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'ui/pages.dart';

class SaydianApp extends StatelessWidget {
  const SaydianApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF116B68);
    return MaterialApp(
      title: 'Saydian 赛电',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.isBooting) {
            return const _BootPage();
          }
          if (!controller.isAuthenticated && !controller.isPreviewMode) {
            return LoginPage(controller: controller);
          }
          return AppShell(controller: controller);
        },
      ),
    );
  }
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在安全加载本地数据…'),
          ],
        ),
      ),
    );
  }
}
