import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class LoadingButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final double height;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
    this.icon = Icons.save,
    this.backgroundColor = const Color(0xFF042A72),
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton.icon(
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon),
        label: Text(loading ? S.of(context).submitting : label),
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
