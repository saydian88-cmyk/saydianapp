import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController.production();
  await controller.initialize();
  runApp(SaydianApp(controller: controller));
}
