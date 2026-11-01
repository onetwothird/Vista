// File: lib/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'detection_detail_screen.dart';
import 'all_detections_screen.dart';

import 'package:seelai_app/shared/widgets/vista_header.dart';
import 'package:seelai_app/shared/widgets/vista_empty_state.dart';
import 'package:seelai_app/shared/accessibility.dart';

class ViewRecentActivities extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final String userId;
  final VoidCallback onToggleDarkMode;

  const ViewRecentActivities({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userId,
    required this.onToggleDarkMode,
  });

  @override
  State<ViewRecentActivities> createState() => _ViewRecentActivitiesState();
}

class _ViewRecentActivitiesState extends State<ViewRecentActivities>
    with TickerProviderStateMixin {
  final Color _primaryColor = Palette.violet;
  final FlutterTts _flutterTts = FlutterTts();

  final int maxDisplayedDetections = 5;
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  bool _isLoading = true;

  bool _isSimulatingLoad = false;

  List<Map<String, dynamic>> _faces = [];
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _texts = [];

  List<Map<String, dynamic>> _allDetections = [];
  List<Map<String, dynamic>> _archivedDetections = [];

  StreamSubscription? _facesSub;
  StreamSubscription? _objectsSub;
  StreamSubscription? _textsSub;

  // === ANIMATION CONTROLLERS ===
  late AnimationController _entryController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _setupRealtimeStreams();
    _initTts();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );

    _entryController.value = 1.0;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(a11y.speechRate);
  }

  void _setupRealtimeStreams() {
    _facesSub = faceDetectionService.streamDetectedFaces(widget.userId).listen((
      faces,
    ) {
      _faces = faces
          .map(
            (face) => {
              ...face,
              'type': 'face',
              'icon': Icons.face_rounded,
              'color': _primaryColor,
            },
          )
          .toList();
      _combineAndSortDetections();
    });

    _objectsSub = objectDetectionService
        .streamDetectedObjects(widget.userId)
        .listen((objects) {
          _objects = objects
              .map(
                (obj) => {
                  ...obj,
                  'type': 'object',
                  'icon': Icons.search_rounded,
                  'color': Palette.success,
                },
              )
              .toList();
          _combineAndSortDetections();
        });

    _textsSub = textScanService.streamScannedTexts(widget.userId).listen((
      texts,
    ) {
      _texts = texts
          .map(
            (text) => {
              ...text,
              'type': 'text',
              'icon': Icons.document_scanner_rounded,
              'color': Palette.warning,
            },
          )
          .toList();
      _combineAndSortDetections();
    });
  }

  void _combineAndSortDetections() {
    final combined = [..._faces, ..._objects, ..._texts];

    combined.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp'] as String);
      final bTime = DateTime.parse(b['timestamp'] as String);
      return bTime.compareTo(aTime);
    });

    if (mounted) {
      setState(() {
        _allDetections = combined.where((d) => d['isDeleted'] != true).toList();
        _archivedDetections = combined
            .where((d) => d['isDeleted'] == true)
            .toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _moveToHistory(Map<String, dynamic> detection) async {
    final type = detection['type'] as String?;
    final dbRef = FirebaseDatabase.instance.ref();

    setState(() {
      detection['isDeleted'] = true;
      _combineAndSortDetections();
    });

    try {
      if (type == 'face') {
        final docId = detection['detectionId'];
        await dbRef.child('detected_faces/${widget.userId}/$docId').update({
          'isDeleted': true,
        });
      } else if (type == 'object') {
        final docId = detection['detectionId'];
        await dbRef.child('detected_objects/${widget.userId}/$docId').update({
          'isDeleted': true,
        });
      } else if (type == 'text') {
        final docId = detection['scanId'];
        await dbRef.child('scanned_texts/${widget.userId}/$docId').update({
          'isDeleted': true,
        });
      }
    } catch (e) {
      debugPrint('Error moving to history: $e');
    }
  }

  Future<void> _deletePermanently(Map<String, dynamic> detection) async {
    final type = detection['type'] as String?;

    setState(() {
      _archivedDetections.removeWhere(
        (d) => d['timestamp'] == detection['timestamp'],
      );
    });

    try {
      if (type == 'face') {
        final docId = detection['detectionId'] as String?;
        if (docId != null) {
          await faceDetectionService.deleteDetection(widget.userId, docId);
        }
      } else if (type == 'object') {
        final docId = detection['detectionId'] as String?;
        if (docId != null) {
          await objectDetectionService.deleteDetection(widget.userId, docId);
        }
      } else if (type == 'text') {
        final docId = detection['scanId'] as String?;
        if (docId != null) {
          await textScanService.deleteScannedText(widget.userId, docId);
        }
      }
    } catch (e) {
      debugPrint('Error permanently deleting: $e');
    }
  }

  Future<void> _deleteAllHistoryPermanently({String typeFilter = 'all'}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> itemsToDelete = _archivedDetections;

      if (typeFilter != 'all') {
        itemsToDelete = _archivedDetections
            .where((d) => d['type'] == typeFilter)
            .toList();
      }

      for (var item in itemsToDelete) {
        await _deletePermanently(item);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _flutterTts.speak('Selected history has been permanently deleted');
    } catch (e) {
      debugPrint('Error permanently deleting history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === UI SHEET FOR FILTERED DELETION ===
  void _showClearHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: widget.theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.subtextColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Titles
            Text(
              'Clear Detections',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a category to permanently delete its records',
              style: TextStyle(fontSize: 14, color: widget.theme.subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Options
            _buildClearOptionCard(
              title: 'Clear All Detections',
              subtitle: 'Permanently delete everything',
              icon: Icons.delete_sweep_rounded,
              color: Palette.alert,
              type: 'all',
            ),
            _buildClearOptionCard(
              title: 'Clear Faces Only',
              subtitle: 'Keep objects and texts',
              icon: Icons.face_rounded,
              color: Palette.violet,
              type: 'face',
            ),
            _buildClearOptionCard(
              title: 'Clear Objects Only',
              subtitle: 'Keep faces and texts',
              icon: Icons.search_rounded,
              color: Palette.success,
              type: 'object',
            ),
            _buildClearOptionCard(
              title: 'Clear Texts Only',
              subtitle: 'Keep faces and objects',
              icon: Icons.document_scanner_rounded,
              color: Palette.warning,
              type: 'text',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _deleteAllHistoryPermanently(typeFilter: type);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.theme.subtextColor.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.theme.subtextColor.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _facesSub?.cancel();
    _objectsSub?.cancel();
    _textsSub?.cancel();
    _entryController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  List<String> _getMascotMessages(
    int faceCount,
    int objectCount,
    int textCount,
  ) {
    return [
      'Hello! You have scanned $faceCount face${faceCount != 1 ? 's' : ''}, $objectCount object${objectCount != 1 ? 's' : ''}, and $textCount text block${textCount != 1 ? 's' : ''}.',
      'Tip: You can tap on any detection card below to view its full details.',
    ];
  }

  Widget _buildSkeletonList(double width) {
    final baseColor = widget.isDarkMode ? Palette.nightSurface : Palette.line;
    final highlightColor = widget.isDarkMode
        ? Palette.nightRaised
        : Palette.paperSunk;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: spacingMedium),
          Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 70,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: spacingLarge),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: spacingMedium),
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radiusLarge),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showSkeleton = _isLoading || _isSimulatingLoad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. FIXED TOP HEADER (Will not scroll)
        FadeTransition(
          opacity: _headerOpacity,
          child: SlideTransition(
            position: _headerSlide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: widget.theme.textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'What Vista has scanned for you',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.theme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshDetections,
                    tooltip: 'Refresh history',
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.card(widget.isDarkMode),
                      side: BorderSide(
                        color: Palette.border(widget.isDarkMode),
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: AnimatedRotation(
                      turns: _isRefreshing ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Palette.text(widget.isDarkMode),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _showClearHistorySheet,
                    tooltip: 'Clear history',
                    style: IconButton.styleFrom(
                      backgroundColor: widget.isDarkMode
                          ? const Color(0xFF3A1A18)
                          : Palette.alertTint,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: Palette.danger(widget.isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: spacingLarge),

        // 2. SCROLLABLE CONTENT AREA
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMascotBanner(_allDetections),

                if (showSkeleton)
                  _buildSkeletonList(width)
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: spacingMedium),

                        _buildFilterTabs(),

                        const SizedBox(height: spacingLarge),

                        _buildDetectionsList(_allDetections),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotBanner(List<Map<String, dynamic>> detections) {
    int faceCount = detections.where((d) => d['type'] == 'face').length;
    int objectCount = detections.where((d) => d['type'] == 'object').length;
    int textCount = detections.where((d) => d['type'] == 'text').length;

    return VistaNote(
      message: _getMascotMessages(faceCount, objectCount, textCount).first,
      isDarkMode: widget.isDarkMode,
      mascotAsset: 'assets/vista-icons/vista-preloader.png',
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Faces', 'Objects', 'Text', 'History'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((label) {
          bool isSelected = _selectedFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = label;
                  _isRefreshing = true;
                });
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) {
                    setState(() {
                      _isRefreshing = false;
                    });
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? _primaryColor
                        : (widget.isDarkMode ? Colors.white10 : Colors.black12),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : widget.theme.subtextColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetectionsList(List<Map<String, dynamic>> allDetections) {
    final sourceList = _selectedFilter == 'History'
        ? _archivedDetections
        : allDetections;

    if (sourceList.isEmpty) {
      return _buildEmptyState();
    }

    final filteredDetections = _filterDetections(sourceList);

    if (filteredDetections.isEmpty) {
      return _buildNoResultsState();
    }

    final displayedDetections = filteredDetections
        .take(maxDisplayedDetections)
        .toList();
    final hasMoreDetections =
        filteredDetections.length > maxDisplayedDetections;

    return AnimationLimiter(
      key: ValueKey(_selectedFilter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            ...displayedDetections.map((detection) {
              return Padding(
                padding: const EdgeInsets.only(bottom: spacingMedium),
                child: _buildDetectionCard(detection),
              );
            }),
            if (hasMoreDetections)
              Padding(
                padding: const EdgeInsets.only(top: spacingSmall),
                child: _buildViewAllButton(filteredDetections),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterDetections(
    List<Map<String, dynamic>> detections,
  ) {
    if (_selectedFilter == 'All' || _selectedFilter == 'History') {
      return detections;
    }

    return detections.where((detection) {
      switch (_selectedFilter) {
        case 'Faces':
          return detection['type'] == 'face';
        case 'Objects':
          return detection['type'] == 'object';
        case 'Text':
          return detection['type'] == 'text';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final type = detection['type'] as String;
    final color = detection['color'] as Color;
    final timestamp = DateTime.parse(detection['timestamp'] as String);
    final timeAgo = _getTimeAgo(timestamp);
    final imageUrl = detection['imageUrl'] as String?;

    String title = '';
    String description = '';
    String detectedLabel = '';

    switch (type) {
      case 'face':
        final faceCount = detection['faceCount'] as int;
        title = 'Face Detection';
        detectedLabel = 'Face';
        description =
            'Detected $faceCount ${faceCount == 1 ? 'face' : 'faces'}';
        break;
      case 'object':
        final objectCount = detection['objectCount'] as int;
        final objects = detection['objects'] as List? ?? [];
        title = 'Object Detection';
        if (objects.isNotEmpty) {
          final firstObject = objects.first['label'] as String;
          detectedLabel =
              '${firstObject[0].toUpperCase()}${firstObject.substring(1).toLowerCase()}';

          if (objectCount > 1) {
            final otherNames = objects
                .skip(1)
                .take(2)
                .map((o) => (o as Map)['label'])
                .join(', ');
            description = objectCount > 3
                ? '+$otherNames, +${objectCount - 3} more'
                : '+$otherNames';
          } else {
            final conf = objects.first['confidence'];
            if (conf != null) {
              description = 'Confidence: ${(conf * 100).toStringAsFixed(1)}%';
            } else {
              description = 'Detected 1 object';
            }
          }
        } else {
          detectedLabel = 'Object';
          description = 'Detected 0 objects';
        }
        break;
      case 'text':
        final textBlockCount = detection['textBlockCount'] as int? ?? 0;
        final text = detection['text'] as String? ?? '';
        title = 'Text Scan';
        detectedLabel = 'Document';
        description = text.length > 40 ? '${text.substring(0, 40)}...' : text;
        if (description.isEmpty) {
          description =
              'Scanned $textBlockCount ${textBlockCount == 1 ? 'block' : 'blocks'}';
        }
        break;
    }

    return Dismissible(
      key: ValueKey(detection['timestamp'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Palette.alert,
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        if (_selectedFilter == 'History') {
          _deletePermanently(detection);
          _flutterTts.speak('$title deleted permanently');
        } else {
          _moveToHistory(detection);
          _flutterTts.speak('$title moved to history');
        }
      },
      child: Semantics(
        label: '$detectedLabel. $title. $description. Scanned $timeAgo',
        button: true,
        hint: 'Double tap to view details',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetectionDetailScreen(
                    detection: detection,
                    isDarkMode: widget.isDarkMode,
                    theme: widget.theme,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(radiusLarge),
            child: Container(
              padding: const EdgeInsets.all(spacingMedium),
              decoration: BoxDecoration(
                color: widget.theme.cardColor,
                borderRadius: BorderRadius.circular(radiusLarge),
                boxShadow: widget.isDarkMode ? [] : softShadow,
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(radiusMedium),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              detection['icon'] as IconData? ??
                                  Icons.image_rounded,
                              color: color,
                              size: 30,
                            ),
                          )
                        : Icon(
                            detection['icon'] as IconData? ??
                                Icons.image_rounded,
                            color: color,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: spacingMedium),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                detectedLabel,
                                style: h3.copyWith(
                                  fontSize: 16,
                                  color: widget.theme.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: caption.copyWith(
                                fontSize: 11,
                                color: widget.theme.subtextColor.withOpacity(
                                  0.8,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: caption.copyWith(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: body.copyWith(
                            fontSize: 13,
                            color: widget.theme.subtextColor,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: spacingSmall),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.theme.subtextColor.withOpacity(0.4),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllButton(List<Map<String, dynamic>> filteredDetections) {
    final totalCount = filteredDetections.length;
    final categoryLabel = _selectedFilter == 'All'
        ? 'Detections'
        : _selectedFilter;

    return Semantics(
      label: 'View all $totalCount $categoryLabel',
      button: true,
      hint: 'Double tap to open full detection list',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllDetectionsScreen(
                  detections: filteredDetections,
                  isDarkMode: widget.isDarkMode,
                  theme: widget.theme,
                  selectedFilter: _selectedFilter,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(spacingMedium),
            decoration: BoxDecoration(
              color: widget.theme.cardColor,
              borderRadius: BorderRadius.circular(radiusMedium),
              border: Border.all(
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.view_list_rounded, color: primary, size: 20),
                const SizedBox(width: spacingSmall),
                Text(
                  'View All $categoryLabel ($totalCount)',
                  style: bodyBold.copyWith(
                    fontSize: 14,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: spacingSmall),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return VistaEmptyState(
      title: 'No detections yet',
      message: 'Start scanning to see your detection history',
      isDarkMode: widget.isDarkMode,
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: spacingXLarge,
        horizontal: spacingLarge,
      ),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: widget.isDarkMode ? [] : softShadow,
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: widget.theme.subtextColor.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: spacingMedium),
          Text(
            'No $_selectedFilter detections',
            style: bodyBold.copyWith(
              fontSize: 16,
              color: widget.theme.textColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacingMedium),
            child: Text(
              'Try scanning with $_selectedFilter detection mode',
              style: caption.copyWith(
                fontSize: 13,
                color: widget.theme.subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  void _refreshDetections() {
    setState(() {
      _isRefreshing = true;
      _isSimulatingLoad = false;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isSimulatingLoad = false;
        });
      }
    });
  }
}

class TypewriterText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) => Text(text, style: style);
}

class PremiumThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;
  final Color buttonBgColor;
  final Color iconColor;

  const PremiumThemeToggle({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
    required this.buttonBgColor,
    required this.iconColor,
  });

  @override
  State<PremiumThemeToggle> createState() => _PremiumThemeToggleState();
}

class _PremiumThemeToggleState extends State<PremiumThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.7,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.7,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double glowOpacity = _controller.isAnimating
              ? (1.0 - _controller.value).clamp(0.0, 0.4)
              : 0.0;

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: RotationTransition(
              turns: _rotationAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.buttonBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: glowOpacity),
                      blurRadius: 20 * _controller.value,
                      spreadRadius: 8 * _controller.value,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    widget.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    key: ValueKey<bool>(widget.isDarkMode),
                    size: 20,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
