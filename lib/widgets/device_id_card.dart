import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeviceIdCard extends StatelessWidget {
  const DeviceIdCard({
    super.key,
    required this.scanTitle,
    required this.scanHint,
    required this.scanButtonLabel,
    required this.manualTitle,
    required this.onScan,
    required this.input,
    this.scanLeadingIcon,
    this.scanButtonIcon,
    this.brandColor = const Color(0xFF042A72),
    this.primaryTextColor = const Color(0xFF172033),
    this.secondaryTextColor = const Color(0xFF697386),
    this.cardBackgroundColor = const Color(0xFFF7FAFF),
    this.cardBorderColor = const Color(0xFFDCE6F8),
    this.iconBackgroundColor = const Color(0xFFEAF3FF),
  });

  final String scanTitle;
  final String scanHint;
  final String scanButtonLabel;
  final String manualTitle;
  final VoidCallback onScan;
  final Widget input;

  final IconData? scanLeadingIcon;
  final IconData? scanButtonIcon;

  final Color brandColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final leadingIcon =
        scanLeadingIcon ??
        (isIOS ? CupertinoIcons.qrcode_viewfinder : Icons.qr_code_scanner_rounded);
    final buttonIcon =
        scanButtonIcon ??
        (isIOS
            ? CupertinoIcons.qrcode_viewfinder
            : Icons.center_focus_strong_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBorderColor),
              ),
              child:
                  isNarrow
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            scanTitle: scanTitle,
                            scanHint: scanHint,
                            iconData: leadingIcon,
                            brandColor: brandColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            iconBackgroundColor: iconBackgroundColor,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _ScanButton(
                              label: scanButtonLabel,
                              onPressed: onScan,
                              iconData: buttonIcon,
                              brandColor: brandColor,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: _Header(
                              scanTitle: scanTitle,
                              scanHint: scanHint,
                              iconData: leadingIcon,
                              brandColor: brandColor,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              iconBackgroundColor: iconBackgroundColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: _ScanButton(
                                label: scanButtonLabel,
                                onPressed: onScan,
                                iconData: buttonIcon,
                                brandColor: brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          manualTitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: secondaryTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        input,
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scanTitle,
    required this.scanHint,
    required this.iconData,
    required this.brandColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.iconBackgroundColor,
  });

  final String scanTitle;
  final String scanHint;
  final IconData iconData;
  final Color brandColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconData, color: brandColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scanTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                scanHint,
                softWrap: true,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.label,
    required this.onPressed,
    required this.iconData,
    required this.brandColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData iconData;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: brandColor,
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isIOS ? 10 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      icon: Icon(iconData, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
