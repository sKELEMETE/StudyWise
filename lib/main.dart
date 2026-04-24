import 'package:flutter/material.dart';
import 'app.dart';
import 'service/supabase/supabase_config.dart';
import 'service/env_service.dart';
import 'service/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvService.init();
  await SupabaseConfig.init();

  initDependencies();

  runApp(const MyApp());
}