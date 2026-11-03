import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/local_db.dart';
import 'core/utils/provider_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize SQLite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DioClient().init();
  await LocalDb().database;
  await PushNotificationService.instance.init();

  runApp(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const SlinkApp(),
    ),
  );
}
