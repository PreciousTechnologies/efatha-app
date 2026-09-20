import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/supabase_database_service.dart';
import 'upload_event_screen.dart';
import 'event_detail_screen.dart';

/// Events Screen - Church events and activities
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'upcoming', 'this_week', 'this_month'];

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchEvents();
  }

  Future<void> _loadUserRole() async {
    // Supabase-first (Django fallback while migrating).
    if (SupabaseConfig.isConfigured) {
      try {
        final profile = await SupabaseAuthService().getCurrentProfile();
        if (profile != null && mounted) {
          setState(() {
            _userRole = profile['role']?.toString() ?? 'member';
          });
          return;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'user';
    });
  }

  /// Client-side date filter (works for both backends).
  bool _matchesDateFilter(Map<String, dynamic> event) {
    if (_selectedFilter == 'all') return true;
    try {
      final start = DateTime.parse(event['start_date'].toString());
      final now = DateTime.now();
      switch (_selectedFilter) {
        case 'upcoming':
          return !start.isBefore(now);
        case 'this_week':
          return !start.isBefore(now) &&
              start.isBefore(now.add(const Duration(days: 7)));
        case 'this_month':
          return start.year == now.year && start.month == now.month;
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _validateEvents(
    List<Map<String, dynamic>> eventsList,
  ) {
    // Validate each event has required fields
    final validEvents = <Map<String, dynamic>>[];
    for (var event in eventsList) {
      if (event['start_date'] != null && event['title'] != null) {
        if (_matchesDateFilter(event)) validEvents.add(event);
      } else {
        print(
          'WARNING: Skipping invalid event (missing start_date or title): $event',
        );
      }
    }
    return validEvents;
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);

    try {
      // Supabase-first (Django fallback while migrating).
      if (SupabaseConfig.isConfigured) {
        final events = await SupabaseDatabaseService().getEvents(limit: 100);
        if (!mounted) return;
        setState(() {
          _events = _validateEvents(events);
          _isLoading = false;
        });
        print('DEBUG: ${_events.length} valid events (Supabase)');
        return;
      }

      String endpoint = ApiConfig.events;
      final now = DateTime.now();

      // Apply filters based on selection
      if (_selectedFilter == 'upcoming') {
        // All future events from now onwards
        endpoint += '?start_date__gte=${now.toIso8601String()}';
      } else if (_selectedFilter == 'this_week') {
        // Events within the next 7 days
        final weekEnd = now.add(const Duration(days: 7));
        endpoint +=
            '?start_date__gte=${now.toIso8601String()}&start_date__lte=${weekEnd.toIso8601String()}';
      } else if (_selectedFilter == 'this_month') {
        // Events within the current month
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        endpoint +=
            '?start_date__gte=${monthStart.toIso8601String()}&start_date__lte=${monthEnd.toIso8601String()}';
      }
      // 'all' filter - no date filtering, shows all events

      print('DEBUG: Fetching events with filter: $_selectedFilter');
      print('DEBUG: API endpoint: $endpoint');

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        print('DEBUG: Response type: ${decodedData.runtimeType}');
        print('DEBUG: Response data: $decodedData');

        // Handle paginated response with 'results' key
        List<Map<String, dynamic>> eventsList;
        if (decodedData is Map && decodedData.containsKey('results')) {
          // Paginated response from Django REST framework
          eventsList = (decodedData['results'] as List)
              .cast<Map<String, dynamic>>();
        } else if (decodedData is List) {
          // Direct list response
          eventsList = decodedData.cast<Map<String, dynamic>>();
        } else if (decodedData is Map) {
          // If single object, wrap it in a list
          eventsList = [decodedData.cast<String, dynamic>()];
        } else {
          eventsList = [];
        }

        print('DEBUG: Parsed ${eventsList.length} events');

        // Validate each event has required fields
        final validEvents = <Map<String, dynamic>>[];
        for (var event in eventsList) {
          if (event['start_date'] != null && event['title'] != null) {
            validEvents.add(event);
          } else {
            print(
              'WARNING: Skipping invalid event (missing start_date or title): $event',
            );
          }
        }

        print('DEBUG: ${validEvents.length} valid events after filtering');

        if (!mounted) return;
        setState(() {
          _events = _validateEvents(validEvents);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to load events');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching events: $e');
      print('DEBUG: Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteEvent(dynamic eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supabase-first (Django fallback while migrating).
        if (SupabaseConfig.isConfigured) {
          await SupabaseDatabaseService().delete(
            SupabaseConfig.eventsTable,
            eventId,
          );
          if (!mounted) return;
          _showSuccess('Event deleted successfully');
          _fetchEvents(); // Refresh list
          return;
        }

        // Get auth token
        final storageService = StorageService();
        final token = await storageService.getAccessToken();

        if (token == null) {
          _showError('Authentication required. Please log in again.');
          return;
        }

        final url = Uri.parse('${ApiConfig.events}$eventId/');
        final response = await http.delete(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 204) {
          _showSuccess('Event deleted successfully');
          _fetchEvents(); // Refresh list
        } else {
          _showError('Failed to delete event');
        }
      } catch (e) {
        _showError('Error: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  bool get _canManageEvents {
    // Mirrors Django can_edit_content (admin/editor/data_entry/leadership).
    const allowed = {
      'admin',
      'editor',
      'data_entry',
      'chief_apostle',
      'katibu_kiongozi',
      'apostle',
      'senior_pastor',
      'bishop',
    };
    return allowed.contains(_userRole?.toLowerCase());
  }

  String _getFilterDescription() {
    final count = _events.length;
    final eventText = count == 1 ? 'event' : 'events';

    switch (_selectedFilter) {
      case 'all':
        return 'Showing all $count $eventText';
      case 'upcoming':
        return 'Showing $count upcoming $eventText';
      case 'this_week':
        return 'Showing $count $eventText this week';
      case 'this_month':
        return 'Showing $count $eventText this month';
      default:
        return 'Showing $count $eventText';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'all':
        return 'No Events Available';
      case 'upcoming':
        return 'No Upcoming Events';
      case 'this_week':
        return 'No Events This Week';
      case 'this_month':
        return 'No Events This Month';
      default:
        return 'No Events Found';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'all':
        return 'There are no events created yet.';
      case 'upcoming':
        return 'There are no upcoming events scheduled.';
      case 'this_week':
        return 'No events are scheduled for this week.';
      case 'this_month':
        return 'No events are scheduled for this month.';
      default:
        return 'Try selecting a different filter.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBackgroundSoft,
      body: RefreshIndicator(
        onRefresh: _fetchEvents,
        color: AppColors.primaryPurpleDeep,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with + button
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.neutralTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_events.length} events',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutralTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (_canManageEvents)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadEventScreen(),
                        ),
                      );
                      if (result == true) {
                        _fetchEvents();
                      }
                    },
                    tooltip: 'Create New Event',
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () {},
                  color: AppColors.primaryPurpleDeep,
                ),
              ],
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return _FilterChip(
                            label: filter.replaceAll('_', ' ').toUpperCase(),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _selectedFilter = filter);
                              _fetchEvents();
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFilterDescription(),
                      style: AppTextStyles.metadataSmall.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Event Cards or Loading
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_events.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: AppColors.neutralTextMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyStateMessage(),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.neutralTextMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptyStateSubtitle(),
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.neutralTextMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_canManageEvents) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UploadEventScreen(),
                              ),
                            );
                            if (result == true) {
                              _fetchEvents();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurpleDeep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ] else if (_selectedFilter != 'all') ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedFilter = 'all');
                            _fetchEvents();
                          },
                          child: const Text('View All Events'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EnhancedEventCard(
                        event: _events[index],
                        canManage: _canManageEvents,
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UploadEventScreen(event: _events[index]),
                            ),
                          );
                          if (result == true) {
                            _fetchEvents();
                          }
                        },
                        onDelete: () => _deleteEvent(_events[index]['id']),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailScreen(event: _events[index]),
                            ),
                          );
                          if (result == true) {
                            _fetchEvents();
                          }
                        },
                      ),
                    ),
                    childCount: _events.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _EnhancedEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _EnhancedEventCard({
    required this.event,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Add null safety checks for all fields
    try {
      final startDateStr = event['start_date'];
      if (startDateStr == null || startDateStr.toString().isEmpty) {
        print('ERROR: Event has null or empty start_date: $event');
        return _buildErrorCard('Invalid event data');
      }

      final startDate = DateTime.parse(startDateStr);
      // Supabase rows carry `banner_url`; Django used `banner_image`.
      final coverUrl = event['banner_image'] ?? event['banner_url'];
      final registrationCount = event['registered_count'] ?? 0;
      final maxAttendees = event['max_attendees'];
      final category = event['category'] ?? 'other';

      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Photo with Date Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: coverUrl != null
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryLabel(category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Date Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.primaryPurpleDeep,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, y').format(startDate),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Edit/Delete buttons for admin/editor
                  if (canManage)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _IconButton(
                            icon: Icons.edit,
                            onTap: onEdit,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _IconButton(
                            icon: Icons.delete,
                            onTap: onDelete,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Event Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event['title'] ?? 'Untitled Event',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.neutralTextMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(startDate),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutralTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.neutralTextMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event['location'] ?? 'Location TBA',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutralTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (event['requires_registration'] == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: AppColors.primaryPurpleDeep,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            maxAttendees != null
                                ? '$registrationCount/$maxAttendees registered'
                                : '$registrationCount registered',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryPurpleDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR: Failed to build event card: $e');
      print('Event data: $event');
      print('Stack trace: $stackTrace');
      return _buildErrorCard('Error displaying event');
    }
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.neutralBackgroundSoft,
      child: Icon(Icons.event, size: 64, color: AppColors.neutralTextMuted),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'worship':
        return Colors.purple;
      case 'conference':
        return Colors.blue;
      case 'seminar':
        return Colors.orange;
      case 'fellowship':
        return Colors.green;
      case 'outreach':
        return Colors.red;
      case 'youth':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'worship':
        return 'Worship';
      case 'conference':
        return 'Conference';
      case 'seminar':
        return 'Seminar';
      case 'fellowship':
        return 'Fellowship';
      case 'outreach':
        return 'Outreach';
      case 'youth':
        return 'Youth';
      default:
        return 'Other';
    }
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryPurpleDeep,
                    AppColors.primaryPurpleVibrant,
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.neutralBackgroundMuted,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurpleVibrant.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyRegular.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.neutralTextMuted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
