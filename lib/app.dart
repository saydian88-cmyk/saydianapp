import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'ui/app_theme.dart';
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
              Text('正在安全加载本地数据…'),
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
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: SaydianColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 12),
        const Text(
          '赛电',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
