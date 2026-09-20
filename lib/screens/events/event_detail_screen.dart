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

/// Event Detail Screen - Full event information with RSVP
class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final SupabaseDatabaseService _supabaseDb = SupabaseDatabaseService();

  bool _isRegistered = false;
  bool _isLoading = false; // ignore: unused_field
  String? _userRole;
  int? _userId; // Django int id (fallback path)
  String? _supabaseUid; // Supabase uuid (primary path)
  String? _myRegistrationId; // Supabase registration row id
  int _registrationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkRegistrationStatus();
  }

  bool get _useSupabase => SupabaseConfig.isConfigured && _supabaseUid != null;

  Future<void> _loadUserData() async {
    // Supabase-first (Django fallback while migrating).
    if (SupabaseConfig.isConfigured) {
      try {
        final auth = SupabaseAuthService();
        final profile = await auth.getCurrentProfile();
        if (profile != null && mounted) {
          setState(() {
            _userRole = profile['role']?.toString() ?? 'member';
            _supabaseUid = auth.currentUser?.id;
          });
          _checkRegistrationStatus();
          return;
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'user';
      _userId = prefs.getInt('user_id');
    });
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      // Supabase-first.
      if (_useSupabase) {
        final eventId = widget.event['id'].toString();
        final regs = await _supabaseDb.getEventRegistrations(eventId);
        final mine = await _supabaseDb.getMyEventRegistration(
          eventId,
          _supabaseUid!,
        );
        if (!mounted) return;
        setState(() {
          _isRegistered = mine != null;
          _myRegistrationId = mine?['id']?.toString();
          _registrationCount = regs.length;
        });
        return;
      }

      if (_userId == null) return;

      // Get auth token
      final storageService = StorageService();
      final token = await storageService.getAccessToken();

      if (token == null) return;

      final url = Uri.parse(
        '${ApiConfig.eventRegistrations}?event=${widget.event['id']}&user=$_userId',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _isRegistered = data.isNotEmpty;
          _registrationCount = widget.event['registered_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error checking registration: $e');
    }
  }

  Future<void> _toggleRegistration() async {
    // ignore: unused_element
    if (!_useSupabase && _userId == null) {
      _showError('Please log in to register for events');
      return;
    }

    // Check if registration is required
    if (widget.event['requires_registration'] != true) {
      _showError('This event does not require registration');
      return;
    }

    // Check max attendees
    final maxAttendees = widget.event['max_attendees'];
    if (!_isRegistered &&
        maxAttendees != null &&
        _registrationCount >= maxAttendees) {
      _showError('This event is full');
      return;
    }

    // Check registration deadline
    final deadline = widget.event['registration_deadline'];
    if (deadline != null) {
      final deadlineDate = DateTime.parse(deadline);
      if (DateTime.now().isAfter(deadlineDate)) {
        _showError('Registration deadline has passed');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Supabase-first.
      if (_useSupabase) {
        final eventId = widget.event['id'].toString();
        if (_isRegistered) {
          // Unregister
          final mine = await _supabaseDb.getMyEventRegistration(
            eventId,
            _supabaseUid!,
          );
          if (mine != null) {
            await _supabaseDb.unregisterFromEvent(mine['id'].toString());
          }
          if (!mounted) return;
          setState(() {
            _isRegistered = false;
            _myRegistrationId = null;
            _registrationCount = (_registrationCount - 1).clamp(0, 1 << 30);
            _isLoading = false;
          });
          _showSuccess('Registration cancelled');
        } else {
          // Register
          await _supabaseDb.registerForEvent(eventId, _supabaseUid!);
          if (!mounted) return;
          setState(() {
            _isRegistered = true;
            _registrationCount++;
            _isLoading = false;
          });
          _showSuccess('Successfully registered!');
        }
        return;
      }

      // Get auth token
      final storageService = StorageService();
      final token = await storageService.getAccessToken();

      if (token == null) {
        _showError('Authentication required. Please log in again.');
        setState(() => _isLoading = false);
        return;
      }

      if (_isRegistered) {
        // Unregister
        final url = Uri.parse(
          '${ApiConfig.eventRegistrations}?event=${widget.event['id']}&user=$_userId',
        );
        final getResponse = await http.get(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (getResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(getResponse.body);
          if (data.isNotEmpty) {
            final registrationId = data[0]['id'];
            final deleteUrl = Uri.parse(
              '${ApiConfig.eventRegistrations}$registrationId/',
            );
            final deleteResponse = await http.delete(
              deleteUrl,
              headers: {'Authorization': 'Bearer $token'},
            );

            if (deleteResponse.statusCode == 204) {
              setState(() {
                _isRegistered = false;
                _registrationCount--;
                _isLoading = false;
              });
              _showSuccess('Registration cancelled');
            } else {
              setState(() => _isLoading = false);
              _showError('Failed to cancel registration');
            }
          }
        }
      } else {
        // Register
        final url = Uri.parse(ApiConfig.eventRegistrations);
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'event': widget.event['id'], 'user': _userId}),
        );

        if (response.statusCode == 201) {
          setState(() {
            _isRegistered = true;
            _registrationCount++;
            _isLoading = false;
          });
          _showSuccess('Successfully registered!');
        } else {
          setState(() => _isLoading = false);
          _showError('Failed to register');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'This action cannot be undone. All registrations will be deleted.',
        ),
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
          await _supabaseDb.delete(
            SupabaseConfig.eventsTable,
            widget.event['id'],
          );
          if (!mounted) return;
          _showSuccess('Event deleted successfully');
          Navigator.pop(context, true); // Return to events list
          return;
        }

        // Get auth token
        final storageService = StorageService();
        final token = await storageService.getAccessToken();

        if (token == null) {
          _showError('Authentication required. Please log in again.');
          return;
        }

        final url = Uri.parse('${ApiConfig.events}${widget.event['id']}/');
        final response = await http.delete(
          url,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 204) {
          _showSuccess('Event deleted successfully');
          Navigator.pop(context, true); // Return to events list
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

  bool get _canManageEvent {
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

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.parse(widget.event['start_date']);
    final endDate = DateTime.parse(widget.event['end_date']);
    // Supabase rows carry `banner_url`; Django used `banner_image`.
    final coverUrl =
        widget.event['banner_image'] ?? widget.event['banner_url'];
    final category = widget.event['category'] ?? 'other';
    final requiresRegistration = widget.event['requires_registration'] == true;
    final maxAttendees = widget.event['max_attendees'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover Photo App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primaryPurpleDeep,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_canManageEvent) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UploadEventScreen(event: widget.event),
                      ),
                    );
                    if (result == true) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onPressed: _deleteEvent,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryPurpleDeep,
                        child: Icon(
                          Icons.event,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.primaryPurpleDeep,
                      child: Icon(
                        Icons.event,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
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
                  // Category Badge
                  Positioned(
                    bottom: 70,
                    left: 16,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.event['title'] ?? 'Untitled Event',
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date & Time
                        _InfoRow(
                          icon: Icons.calendar_today,
                          title: 'Date & Time',
                          content:
                              '${DateFormat('EEEE, MMMM d, y').format(startDate)}\n'
                              '${DateFormat('h:mm a').format(startDate)} - ${DateFormat('h:mm a').format(endDate)}',
                        ),
                        const SizedBox(height: 16),

                        // Location
                        _InfoRow(
                          icon: Icons.location_on,
                          title: 'Location',
                          content: widget.event['location'] ?? 'Location TBA',
                        ),

                        if (requiresRegistration) ...[
                          const SizedBox(height: 16),
                          _InfoRow(
                            icon: Icons.people,
                            title: 'Registration',
                            content: maxAttendees != null
                                ? '$_registrationCount / $maxAttendees registered'
                                : '$_registrationCount registered',
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'About This Event',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.event['description'] ??
                              'No description available.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            height: 1.6,
                            color: AppColors.neutralTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurpleDeep.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryPurpleDeep, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutralTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
