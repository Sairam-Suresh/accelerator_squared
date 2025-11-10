import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/views/Login%20Page/login.dart';
import 'package:accelerator_squared/views/Home%20Page/home.dart';
import 'package:accelerator_squared/views/loading_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserLoading) {
          return LoadingScreen();
        } else if (state is UserInitial || state is UserError) {
          // Show login page for both initial and error states
          // UserError will be handled by the login page to show error messages
          return ResponsiveBreakpoints.builder(
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
            child: LoginPage(),
          );
        } else if (state is UserLoggedIn || state is UserCreated) {
          return ResponsiveBreakpoints.builder(
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
            child: HomePage(),
          );
        } else {
          // Fallback to loading screen for any unknown state
          return LoadingScreen();
        }
      },
    );
  }
} 