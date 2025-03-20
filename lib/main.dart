import 'package:accelerator_squared/login.dart';
import 'package:accelerator_squared/orgprojectsview.dart';
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
  var sampleOrgList = [
    'Organisation 1',
    'Organisation 2',
    'Organisation 3',
    'Organisation 4',
    'Organisation 5',
  ];

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
                  var orgmemberlist = [];
                  showDialog(
                    context: context,
                    builder: (context) {
                      TextEditingController orgnamecontroller =
                          TextEditingController();
                      TextEditingController orgdesccontroller =
                          TextEditingController();
                      TextEditingController emailaddingcontroller =
                          TextEditingController();

                      return AlertDialog(
                        content: SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 1.5,
                          child: Column(
                            children: [
                              Text(
                                "Create new project",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  TextField(
                                    controller: orgnamecontroller,
                                    decoration: InputDecoration(
                                      label: Text("Project Name"),
                                      hintText: "Enter project name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: orgdesccontroller,
                                    minLines: 3,
                                    maxLines: 20,
                                    decoration: InputDecoration(
                                      label: Text("Project description"),
                                      hintText: "Enter project description",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      // open google account selector
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        20,
                                        0,
                                        20,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "../assets/drive.png",
                                            height: 30,
                                          ),
                                          SizedBox(width: 15),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "dummyemail@gmail.com",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "Click to change account",
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text("Member list"),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                            3,
                                        child: TextField(
                                          controller: emailaddingcontroller,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            hintText: "Enter email to add",
                                            label: Text("Add members' email"),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          orgmemberlist.add(
                                            emailaddingcontroller.text,
                                          );
                                          print(orgmemberlist);
                                          emailaddingcontroller.clear();
                                          setState(() {});
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            13,
                                            0,
                                            13,
                                          ),
                                          child: Text(
                                            "Add",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  !orgmemberlist.isEmpty
                                      ? ListView.builder(
                                        itemBuilder: (context, index) {
                                          return Card(
                                            child: Text(orgmemberlist[index]),
                                          );
                                        },
                                        itemCount: orgmemberlist.length,
                                      )
                                      : Text("No members added yet"),
                                ],
                              ),
                              Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  // create project
                                  Navigator.of(context).pop();
                                },
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                                  child: Text(
                                    "Create organisation",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
                      TextEditingController orgcodecontroller =
                          TextEditingController();
                      return AlertDialog(
                        content: SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.height / 2,
                          child: Column(
                            children: [
                              Text(
                                "Join organisation",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Center(
                                child: TextField(
                                  controller: orgcodecontroller,
                                  decoration: InputDecoration(
                                    hintText: "Enter join code",
                                    label: Text("Organisation code"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Spacer(),
                              ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                                  child: Text(
                                    "Send join request",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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
