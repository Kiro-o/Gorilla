import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/firebase_config.dart';
import 'auth_screen.dart';
import 'data/storage/local_storage_service.dart';
import 'presentation/viewmodels/workout_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with Gorilla credentials
  await Firebase.initializeApp(
    options: GorillaFirebaseConfig.options,
  );

  // Load persisted theme preference (defaults to dark)
  final themeNotifier = await ThemeNotifier.create();

  // Set immersive status bar based on initial theme
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          themeNotifier.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          themeNotifier.isDark ? AppTheme.bgCore : AppTheme.lBgCore,
      systemNavigationBarIconBrightness:
          themeNotifier.isDark ? Brightness.light : Brightness.dark,
    ),
  );

  // Initialize offline persistent local storage
  final storageService = await LocalStorageService.create();
  final workoutViewModel = WorkoutViewModel(storageService);

  runApp(GorillaGymApp(
    viewModel: workoutViewModel,
    themeNotifier: themeNotifier,
  ));
}

class GorillaGymApp extends StatelessWidget {
  final WorkoutViewModel viewModel;
  final ThemeNotifier themeNotifier;

  const GorillaGymApp({
    super.key,
    required this.viewModel,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return AnimatedTheme(
          data: themeNotifier.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          duration: const Duration(milliseconds: 280),
          child: MaterialApp(
            title: 'GORILLA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.mode,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // While checking Firebase Auth status
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    backgroundColor: context.gorilla.bgCore,
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🦍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          CircularProgressIndicator(
                            color: AppTheme.neonGreen,
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Authenticated → Home Screen
                if (snapshot.hasData && snapshot.data != null) {
                  return HomeScreen(
                    viewModel: viewModel,
                    themeNotifier: themeNotifier,
                  );
                }

                // Unauthenticated → Gorilla Auth Screen
                return AuthScreen(themeNotifier: themeNotifier);
              },
            ),
          ),
        );
      },
    );
  }
}
