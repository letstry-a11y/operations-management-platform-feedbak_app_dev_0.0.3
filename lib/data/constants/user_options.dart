import 'package:flutter/widgets.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

/// Common option lists for identity (organization) and role selections.
/// Ids are numeric strings as required by backend.
class UserOptions {
  static List<Map<String, String>> identityOptions(BuildContext context) => [
        {'id': '1', 'label': S.of(context).hospital},
        {'id': '2', 'label': 'OBD'},
        {'id': '3', 'label': S.of(context).existingAgent},
        {'id': '4', 'label': S.of(context).potentialPartner},
      ];

  static List<Map<String, String>> roleOptions(BuildContext context) => [
        {'id': '1', 'label': S.of(context).doctor},
        {'id': '2', 'label': S.of(context).nurse},
        {'id': '3', 'label': S.of(context).hospitalTechEngineer},
        {'id': '4', 'label': S.of(context).manufacturerTechEngineer},
        {'id': '5', 'label': S.of(context).manufacturerClinicalExpert},
        {'id': '0', 'label': S.of(context).other},
      ];
}




