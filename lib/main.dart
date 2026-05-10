import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
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
      final fallbackLogger = sl.isRegistered<Logger>() ? sl<Logger>() : Logger();
      fallbackLogger.e('Startup error', error: e, stackTrace: stack);
    }
    runApp(StartupErrorApp(onRetry: () => main()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final VoidCallback onRetry;

  const StartupErrorApp({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'StudyWise failed to start. Check your configuration.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}