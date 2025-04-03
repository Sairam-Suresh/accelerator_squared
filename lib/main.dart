import 'package:accelerator_squared/organisations/joinorganizationdialog.dart';
import 'package:accelerator_squared/login.dart';
import 'package:accelerator_squared/organisations/orgcreationdialog.dart';
import 'package:accelerator_squared/orgprojectsview.dart';
import 'package:accelerator_squared/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var sampleOrgList = ['Organisation 1', 'Organisation 2', 'Organisation 3'];

  var sampleStatusList = [
    'Student',
    'Teacher',
    'Student',
    'Student',
    'Student',
  ];

  var sampleDescriptionList = [
    "Project description goes here or something",
    "This is a very fun project trust",
    "Why am I doing this",
    "somebody send help rn",
    "no",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 70,
        type: ExpandableFabType.up,
        children: [
          Row(
            children: [
              Text("Create organisation"),
              SizedBox(width: 20),
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return OrgCreationDialog();
                    },
                  );
                },
                child: Icon(Icons.add),
              ),
            ],
          ),
          Row(
            children: [
              Text("Join organisation"),
              SizedBox(width: 20),
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return JoinOrganizationDialog();
                    },
                  );
                },
                child: Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          "Accelerator^2",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return SettingsPage();
                    },
                  ),
                );
              },
              icon: Icon(Icons.settings),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Organisations",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 18),
                                Align(
                                  child: Text(sampleStatusList[index]),
                                  alignment: Alignment.centerLeft,
                                ),
                              ],
                            ),
                            ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) {
                                      return ProjectPage(
                                        orgName: sampleOrgList[index],
                                      );
                                    },
                                  ),
                                );
                              },
                              title: Text(
                                sampleOrgList[index],
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                sampleDescriptionList[index],
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 10);
                  },
                  itemCount: sampleOrgList.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
