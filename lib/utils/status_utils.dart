import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class StatusUtils {
  static String getStatusText(BuildContext context, int status) {
    final s = S.of(context);
    switch (status) {
      case 0:
        return s.pending;
      case 1:
        return s.inProgress;
      case 2:
        return s.completed;
      case 3:
        return s.reviewed;
      default:
        return s.statusException;
    }
  }

  static Color getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      default:
        return Colors.redAccent;
    }
  }
}
