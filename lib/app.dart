import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'ui/app_theme.dart';
import 'ui/brand_assets.dart';
import 'ui/pages.dart';

class SaydianApp extends StatelessWidget {
  const SaydianApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saydian 赛电',
      debugShowCheckedModeBanner: false,
      theme: buildSaydianTheme(),
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
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: saydianSoftGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BootLogo(),
              SizedBox(height: 26),
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(height: 14),
              Text('正在为你准备…'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootLogo extends StatelessWidget {
  const _BootLogo();

  @override
  Widget build(BuildContext context) {
    return const SaydianBrandLockup(width: 185);
  }
}
