import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/views/Login%20Page/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserBloc>().state as UserLoggedIn;

    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserInitial) {
          Navigator.of(context).pushReplacement(
            PageTransition(
              type: PageTransitionType.leftToRight,
              child: PopScope(canPop: false, child: LoginPage()),
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child:
                    userState.photoUrl == null
                        ? Icon(Icons.person, size: 160)
                        : Image.network(
                          userState.photoUrl!,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userState.displayName ?? "Dummy Name",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  Text(userState.email, style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            "Stats",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
          ),
          Text("Working on x projects"),
          Text("Completed x tasks this month"),
          SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<UserBloc>().add(UserLogoutEvent());
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 15, 5, 15),
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Log Out",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
