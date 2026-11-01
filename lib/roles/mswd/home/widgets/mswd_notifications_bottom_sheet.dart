// File: lib/roles/mswd/home/widgets/mswd_notifications_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
// USING THE MSWD DETAILS SCREEN INSTEAD OF CARETAKER
import 'package:seelai_app/roles/mswd/home/sections/requests/requests_details.dart';
import 'package:seelai_app/shared/widgets/vista_empty_state.dart';
import 'package:seelai_app/shared/widgets/vista_loader.dart';

class MSWDNotificationsBottomSheet extends StatefulWidget {
  final String adminId;
  final bool isDarkMode;
  final dynamic theme; // Added theme required for MSWD Details Screen
  final AssistanceRequestService assistanceRequestService;

  const MSWDNotificationsBottomSheet({
    super.key,
    required this.adminId,
    required this.isDarkMode,
    required this.theme,
    required this.assistanceRequestService,
  });

  @override
  State<MSWDNotificationsBottomSheet> createState() =>
      _MSWDNotificationsBottomSheetState();
}

class _MSWDNotificationsBottomSheetState
    extends State<MSWDNotificationsBottomSheet> {
  final Map<String, String?> _profileImageCache = {};

  Future<void> _loadProfileImage(String patientId) async {
    if (_profileImageCache.containsKey(patientId)) return;
    try {
      final userData = await databaseService.getUserData(patientId);
      if (mounted) {
        setState(() {
          _profileImageCache[patientId] =
              userData?['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? Palette.nightPage : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Palette.ink;
    final subTextColor = widget.isDarkMode ? Colors.white54 : Palette.inkMuted;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle & Title
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.inkSubtle.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.done_all, color: primary),
                  onPressed: () {},
                  tooltip: 'Mark all as read',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications Stream
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: widget.assistanceRequestService.streamAllRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: VistaLoader(size: 88));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading notifications.',
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return VistaEmptyState(
                    title: 'No notifications yet',
                    message: 'Requests and alerts that need you show up here.',
                    isDarkMode: widget.isDarkMode,
                    mascotSize: 130,
                  );
                }

                // Categorize into "New" (Pending) and "Earlier"
                final newRequests = requests
                    .where((r) => r.status == RequestStatus.pending)
                    .toList();
                final earlierRequests = requests
                    .where((r) => r.status != RequestStatus.pending)
                    .toList();

                newRequests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                earlierRequests.sort(
                  (a, b) => b.timestamp.compareTo(a.timestamp),
                );

                for (var req in requests) {
                  _loadProfileImage(req.patientId);
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (newRequests.isNotEmpty) ...[
                      _buildSectionHeader('New Alerts', textColor),
                      ...newRequests.map(
                        (req) => _buildNotificationTile(
                          req,
                          isNew: true,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),
                      ),
                    ],
                    if (earlierRequests.isNotEmpty) ...[
                      if (newRequests.isNotEmpty) const Divider(height: 1),
                      _buildSectionHeader('Earlier', textColor),
                      ...earlierRequests
                          .take(30)
                          .map(
                            (req) => _buildNotificationTile(
                              req,
                              isNew: false,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    RequestModel request, {
    required bool isNew,
    required Color textColor,
    required Color subTextColor,
  }) {
    final profileUrl = _profileImageCache[request.patientId];
    final timeAgo = _getTimeAgo(request.timestamp);

    final unreadBgColor = widget.isDarkMode
        ? Palette.info.withValues(alpha: 0.1)
        : Palette.info.withValues(alpha: 0.05);

    return InkWell(
      onTap: () {
        // Correctly route to MSWD Details Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsScreen(
              request: request,
              isDarkMode: widget.isDarkMode,
              theme: widget.theme,
              userDataCache: const {}, // Will self-fetch missing data
            ),
          ),
        );
      },
      child: Container(
        color: isNew ? unreadBgColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Palette.line,
                  backgroundImage: profileUrl != null
                      ? NetworkImage(profileUrl)
                      : null,
                  child: profileUrl == null
                      ? Icon(Icons.person, color: Palette.inkMuted, size: 30)
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: request.getPriorityColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNew
                            ? (widget.isDarkMode
                                  ? Palette.nightPage
                                  : Palette.paper)
                            : (widget.isDarkMode
                                  ? Palette.nightPage
                                  : Colors.white),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      request.getIcon(),
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '${request.patientName} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: isNew
                              ? 'needs system assistance for a '
                              : 'generated a request for ',
                        ),
                        TextSpan(
                          text: '${request.requestType} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: request.status == RequestStatus.pending
                              ? 'request.'
                              : '(Status: ${request.status.name}).',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 13,
                      color: isNew ? Palette.info : subTextColor,
                      fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isNew)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 8),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Palette.info,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${difference.inDays ~/ 7}w';
  }
}
