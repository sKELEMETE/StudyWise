import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'service/supabase/supabase_config.dart';
import 'service/env_service.dart';
import 'service/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EnvService.init();
    await SupabaseConfig.init();
    initDependencies();

    runApp(const MyApp());
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('Startup error: $e');
      debugPrint('$stack');
    }
    runApp(const StartupErrorApp());
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'StudyWise could not start. Please check the app configuration.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
