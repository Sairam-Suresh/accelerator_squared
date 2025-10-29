import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/views/Home%20Page/invites.dart';
import 'package:accelerator_squared/views/Home%20Page/settings.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/add_organisation_button.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/create_organisation_dialog.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/join_organisation_dialog.dart';
import 'package:accelerator_squared/widgets/organisation_card.dart';
import 'package:accelerator_squared/views/Project/project_page.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:provider/provider.dart';
import 'package:accelerator_squared/theme.dart';
import 'dart:html' as html; // For user agent detection

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Organisation> organisations = [];
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final invitesPageProvider = Provider.of<InvitesPageProvider>(context);
    final showInvitesPage = invitesPageProvider.showInvitesPage;
    // If invites page is hidden and _selectedIndex is now out of range, set to settings page
    final maxIndex = showInvitesPage ? 2 : 1;
    if (_selectedIndex > maxIndex) {
      setState(() {
        _selectedIndex = maxIndex; // Always go to settings page
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showMobileAlertIfNeeded();
    });
    // If toggled ON, do not change the index (user remains on settings)
  }

  void showMobileAlertIfNeeded() {
    if (_dialogShown) return;
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isMobile =
        userAgent.contains('iphone') ||
        userAgent.contains('android') ||
        userAgent.contains('ipad') ||
        userAgent.contains('mobile');

    if (isMobile) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false, // Force user to acknowledge
        builder:
            (context) => AlertDialog(
              title: const Text(
                'Mobile Device Detected',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'This web app is best experienced on a desktop or tablet screen. '
                'For the best performance and layout, please switch to a larger device.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue Anyway'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesPageProvider = Provider.of<InvitesPageProvider>(context);
    final showInvitesPage = invitesPageProvider.showInvitesPage;
    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: AddOrganisationButton(),
      appBar: AppBar(
        title: Text(
          _getPageTitle(showInvitesPage),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.business_outlined),
                    selectedIcon: Icon(Icons.business),
                    label: Text("Organisations"),
                  ),
                  if (showInvitesPage)
                    NavigationRailDestination(
                      icon: Icon(Icons.mail_outline),
                      selectedIcon: Icon(Icons.mail),
                      label: Text("Invites"),
                    ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text("Settings"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceDim,
                child: _buildContent(showInvitesPage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(bool showInvitesPage) {
    if (_selectedIndex == 0) return "Organisations";
    if (showInvitesPage && _selectedIndex == 1) return "Invites";
    return "Settings";
  }

  Widget _buildContent(bool showInvitesPage) {
    if (_selectedIndex == 0) return _buildOrganisationsContent();
    if (showInvitesPage && _selectedIndex == 1) return OrgInvitesPage();
    return SettingsPage();
  }

  Widget _buildOrganisationsContent() {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsError) {
          // Check if this is the "last teacher" error
          if (state.message.contains("last teacher")) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Cannot Leave Organisation'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are the last teacher in this organisation.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'To leave the organisation, you must first assign another member as a teacher.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
            );
          } else {
            // Show other errors as snackbar
            SnackBarHelper.showError(context, message: state.message);
          }
        }
      },
      child: BlocBuilder<OrganisationsBloc, OrganisationsState>(
        builder: (context, state) {
          if (state is OrganisationsLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading organisations...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is OrganisationsLoaded) {
            organisations = state.organisations;
            if (organisations.isEmpty) {
              return _buildEmptyState();
            }
            return _buildOrganisationsGrid();
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.business_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No organisations found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are not a member of any organisations yet.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, StateSetter setState) {
                            return CreateOrganisationDialog();
                          },
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Create Organisation"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        TextEditingController orgcodecontroller =
                            TextEditingController();
                        return JoinOrganisationDialog(
                          orgcodecontroller: orgcodecontroller,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text("Join Organisation"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganisationsGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Organisations',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${organisations.length} organisation${organisations.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              itemCount: organisations.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemBuilder:
                  (context, index) => OrganisationCard(
                    organisation: organisations[index],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => BlocProvider(
                                create:
                                    (context) => OrganisationBloc(
                                      organisationId: organisations[index].id,
                                      initialState: organisations[index],
                                    ),
                                child: ProjectsPage(),
                              ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
