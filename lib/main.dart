import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/firebase_options.dart';
import 'package:accelerator_squared/theme.dart';
import 'package:accelerator_squared/views/auth_wrapper.dart';
import 'package:accelerator_squared/views/loading_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (mounted) {
        setState(() {
          _firebaseInitialized = true;
        });
      }
    } catch (e) {
      // Handle Firebase initialization error
      if (mounted) {
        setState(() {
          _firebaseInitialized = true; // Still set to true to show app
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseInitialized) {
      // Show loading screen while Firebase initializes
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Accelerator Squared",
        theme: ThemeData(
          fontFamily: 'IBMPlexSans',
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
        darkTheme: ThemeData(
          fontFamily: 'IBMPlexSans',
          useMaterial3: true,
          colorScheme: darkColorScheme,
        ),
        home: const LoadingScreen(),
      );
    }

    // Show main app once Firebase is initialized
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(create: (context) => UserBloc()),
        BlocProvider<OrganisationsBloc>(
          create: (context) => OrganisationsBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Accelerator Squared",
        theme: ThemeData(
          fontFamily: 'IBMPlexSans',
          useMaterial3: true,
          colorScheme: lightColorScheme,
          appBarTheme: AppBarTheme(
            backgroundColor: lightColorScheme.surface,
            centerTitle: false,
          ),
        ),
        darkTheme: ThemeData(
          fontFamily: 'IBMPlexSans',
          useMaterial3: true,
          colorScheme: darkColorScheme,
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.surface,
            centerTitle: false,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
