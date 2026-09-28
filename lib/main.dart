import 'dart:async';

import 'package:flutter/material.dart';

import 'business/db/store.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 冷启动读取本地数据，最长等待 6 秒；异常/超时都不阻塞启动。
  try {
    await Store.instance.load().timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('bootstrap load skipped: $e');
  }

  runApp(const CopydApp());
}
