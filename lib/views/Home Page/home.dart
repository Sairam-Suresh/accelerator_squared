import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/views/Home%20Page/invites.dart';
import 'package:accelerator_squared/views/Home%20Page/settings.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/add_organisation_button.dart';
import 'package:accelerator_squared/widgets/organisation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Organisation> organisations = [];

  @override
  void initState() {
    super.initState();

    // Trigger the fetch organisations event
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  int _selectedIndex = 0;

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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavigationRail(
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text("Organisations"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.mail),
                    label: Text("Invites"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text("Settings"),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                labelType: NavigationRailLabelType.all,
              ),
              _selectedIndex == 0
                  ? SizedBox(
                    width: MediaQuery.of(context).size.width - 150,
                    child: BlocBuilder<OrganisationsBloc, OrganisationsState>(
                      builder: (context, state) {
                        if (state is OrganisationsLoading) {
                          return Center(child: CircularProgressIndicator());
                        } else if (state is OrganisationsLoaded) {
                          organisations = state.organisations;
                          return Expanded(
                            child: GridView.builder(
                              itemCount: organisations.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 500,
                                    childAspectRatio: 3 / 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder:
                                  (context, index) => OrganisationCard(
                                    organisation: organisations[index],
                                  ),
                              shrinkWrap: true,
                            ),
                          );
                        } else if (state is OrganisationsError) {
                          return Center(child: Text(state.message));
                        } else {
                          return Center(child: Text("No organisations found"));
                        }
                      },
                    ),
                  )
                  : _selectedIndex == 1
                  ? OrgInvitesPage()
                  : SizedBox(
                    width: MediaQuery.of(context).size.width - 150,
                    child: SettingsPage(),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
