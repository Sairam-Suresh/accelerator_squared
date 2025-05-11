import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/views/Home%20Page/settings.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/add_organisation_button.dart';
import 'package:accelerator_squared/widgets/organisation_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Organisation> organisations = [
    Organisation(
      name: "Tech Innovators Inc.",
      description: "Leading the way in tech innovation.",
      students: [
        StudentInOrganisation(
          name: "Alice Johnson",
          email: "alice@techinnovators.com",
          photoUrl: null,
          type: UserInOrganisationType.student,
        ),
        StudentInOrganisation(
          name: "Bob Smith",
          email: "bob@techinnovators.com",
          photoUrl: null,
          type: UserInOrganisationType.teacher,
        ),
      ],
      projects: [
        Project(
          name: "AI Research",
          description: "Exploring advancements in artificial intelligence.",
          studentsInvolved: [
            Student(
              name: "Alice Johnson",
              email: "alice@techinnovators.com",
              photoUrl: null,
            ),
          ],
        ),
      ],
    ),
    Organisation(
      name: "Green Future Solutions",
      description: "Sustainable solutions for a better tomorrow.",
      students: [],
      projects: [],
    ),
    Organisation(
      name: "HealthTech Innovations",
      description: "Revolutionizing healthcare through technology.",
      students: [],
      projects: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: AddOrganisationButton(),
      appBar: AppBar(
        title: Text(
          "Organisations",
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
          padding: EdgeInsets.all(10),
          child: Expanded(
            child: GridView.builder(
              itemCount: organisations.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder:
                  (context, index) =>
                      OrganisationCard(organisation: organisations[index]),
            ),
          ),
        ),
      ),
    );
  }
}
