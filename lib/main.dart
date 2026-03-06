import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';
import 'presentation/bloc/discovery/discovery_bloc.dart';
import 'presentation/bloc/locale/locale_cubit.dart';
import 'presentation/bloc/permission/permission_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/bloc/transfer/transfer_bloc.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependencies
  await di.initDependencies();

  runApp(const FastShareApp());
}

/// Root application widget.
class FastShareApp extends StatelessWidget {
  const FastShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<TransferBloc>(create: (_) => sl<TransferBloc>()),
        BlocProvider<DiscoveryBloc>(create: (_) => sl<DiscoveryBloc>()),
        BlocProvider<PermissionBloc>(
          create: (_) => sl<PermissionBloc>()
            ..add(const CheckPermissionsEvent()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'Fast Share',
                debugShowCheckedModeBanner: false,

                // Theme
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,

                // Localization
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // Main screen
                home: const MainShell(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Main navigation shell with bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
