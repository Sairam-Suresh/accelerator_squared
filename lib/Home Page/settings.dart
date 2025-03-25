import 'package:accelerator_squared/Login%20Page/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Icon(Icons.person, size: 160),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Username",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        "dummyemail@gmail.com",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Stats",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("Working on x projects"),
                      Text("Completed x tasks this month"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                      child: Text("Change username"),
                    ),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        CupertinoPageRoute(
                          builder: (context) {
                            return PopScope(canPop: false, child: LoginPage());
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 15, 5, 15),
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 10),
                          Text("Log Out"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
