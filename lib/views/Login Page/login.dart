import 'package:accelerator_squared/views/Home%20Page/home.dart';
import 'package:accelerator_squared/views/Login%20Page/signup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Log In",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(
                        builder: (context) {
                          return HomePage();
                        },
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12.5, 20, 12.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("../../assets/google.png", height: 30),
                        SizedBox(width: 10),
                        Text(
                          "Log in with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Divider(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) {
                          return SignupPage();
                        },
                      ),
                    );
                  },
                  child: Text("Sign up"),
                ),
                // Row(
                //   children: [
                //     Text("Don't have an account?"),
                //     ElevatedButton(
                //       onPressed: () {},
                //       child: Padding(
                //         padding: EdgeInsets.all(10),
                //         child: Text("Sign up"),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
