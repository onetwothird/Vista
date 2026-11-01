// File: lib/roles/partially_sighted/home/sections/home_screen/location.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_header.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/widgets/location_map_widget.dart';

class LocationSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final Map<String, dynamic> userData;

  const LocationSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return _buildLocationUnavailable();
    }

    return _buildLocationSection();
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VistaSectionTitle(
          title: 'Your location',
          subtitle: 'Your caretaker can see this',
          isDarkMode: isDarkMode,
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border(isDarkMode)),
          ),
          child: LocationMapWidget(
            isDarkMode: isDarkMode,
            theme: theme,
            userId: userId,
            userData: userData,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationUnavailable() {
    return Container(
      padding: EdgeInsets.all(spacingXLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.border(isDarkMode)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacingLarge),
            decoration: BoxDecoration(
              color: Palette.alertTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_rounded,
              size: 40,
              color: Palette.alert,
            ),
          ),
          SizedBox(height: spacingLarge),
          Text(
            'Location unavailable',
            style: bodyBold.copyWith(fontSize: 16, color: theme.textColor),
          ),
          SizedBox(height: spacingSmall),
          Text(
            'Sign in to share your location with your caretaker.',
            style: body.copyWith(fontSize: 13, color: theme.subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
