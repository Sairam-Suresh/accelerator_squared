import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/create_organisation_dialog.dart';
import 'package:accelerator_squared/views/Home%20Page/Add%20Organisation/join_organisation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:accelerator_squared/util/page_title.dart';

class AddOrganisationButton extends StatelessWidget {
  const AddOrganisationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      distance: 70,
      type: ExpandableFabType.up,
      onOpen: () {},
      children: [
        Row(
          children: [
            Text("Create organisation"),
            SizedBox(width: 20),
            FloatingActionButton(
              onPressed: () async {
                setPageTitle('Organisations - Create Organisation');
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, StateSetter setState) {
                        return CreateOrganisationDialog();
                      },
                    );
                  },
                );
                setPageTitle('Organisations');
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
              onPressed: () async {
                setPageTitle('Organisations - Join Organisation');
                await showDialog(
                  context: context,
                  builder: (context) {
                    TextEditingController orgcodecontroller =
                        TextEditingController();
                    return JoinOrganisationDialog(
                      orgcodecontroller: orgcodecontroller,
                    );
                  },
                );
                setPageTitle('Organisations');
              },
              child: Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ],
    );
  }
}
