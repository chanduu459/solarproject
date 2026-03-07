import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  // 1. Ensure bindings are ready for async calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: SolarInstallationTracker(),
    ),
  );
}

class SolarInstallationTracker extends StatelessWidget {
  const SolarInstallationTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Solar Installation Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData( // Removed 'const' from the entire theme block
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                // h, w, and r are runtime-only values
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            cardTheme: CardThemeData( // Ensure NO 'const' prefix here
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // SplashScreen can remain const because it doesn't use ScreenUtil in its constructor
          home: const SplashScreen(),
        );
      },
    );
  }
}