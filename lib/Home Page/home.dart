import 'package:accelerator_squared/Home%20Page/settings.dart';
import 'package:accelerator_squared/Home%20Page/Add%20Organisation/add_organisation_button.dart';
import 'package:accelerator_squared/Project/project_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

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
      floatingActionButton: AddOrganisationButton(),
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
                                  alignment: Alignment.centerLeft,
                                  child: Text(sampleStatusList[index]),
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
