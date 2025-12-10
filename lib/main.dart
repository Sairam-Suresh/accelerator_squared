import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/firebase_options.dart';
import 'package:accelerator_squared/theme.dart';
import 'package:accelerator_squared/views/auth_wrapper.dart';
import 'package:accelerator_squared/views/loading_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences.setMockInitialValues({});
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseAnalytics.instance.logEvent(name: 'firebase_initialized');
      if (mounted) {
        setState(() {
          _firebaseInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firebaseInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseInitialized) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => InvitesPageProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "Accelerator Squared",
              theme: themeProvider.theme,
              home: const LoadingScreen(),
            );
          },
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(create: (context) => UserBloc()),
        BlocProvider<OrganisationsBloc>(
          create: (context) => OrganisationsBloc(),
        ),
        BlocProvider<ProjectsBloc>(create: (context) => ProjectsBloc()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => InvitesPageProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "Accelerator Squared",
              theme: themeProvider.theme,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}
