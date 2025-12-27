import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/team_provider.dart';
import 'providers/project_provider.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/team_screen.dart';
import 'screens/project_screen.dart';
import 'screens/task_screen.dart';
import 'screens/team_detail_screen.dart';
import 'screens/project_detail_screen.dart';

import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final GoRouter _router;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _initRouter();
  }

  void _initRouter() {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Check auth immediately
    _authProvider.checkAuth();

    _router = GoRouter(
      refreshListenable: _authProvider,
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/teams',
          builder: (context, state) => const TeamScreen(),
        ),
        GoRoute(
          path: '/teams/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TeamDetailScreen(teamId: id);
          },
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ProjectDetailScreen(projectId: id);
          },
        ),
      ],
      redirect: (context, state) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = auth.isAuthenticated;
        final loggingIn = state.uri.toString() == '/login';
        final registering = state.uri.toString() == '/register';

        if (!loggedIn && !registering) return '/login';
        if (loggedIn && (loggingIn || registering)) return '/';

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CollabU',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      scrollBehavior: const CustomScrollBehavior(),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
