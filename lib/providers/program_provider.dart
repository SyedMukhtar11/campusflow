import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/feedback_entry.dart';
import '../models/program.dart';
import '../models/user_registration.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/program_service.dart';

class ProgramProvider extends ChangeNotifier {
  final ProgramService _service;
  final NotificationService _notificationService;

  ProgramProvider({
    ProgramService? service,
    NotificationService? notificationService,
    List<Program>? initialPrograms,
    bool autoLoad = true,
  })  : _service = service ?? ProgramService(),
        _notificationService = notificationService ?? NotificationService() {
    if (initialPrograms != null) {
      _programs = initialPrograms;
      _isLoading = false;
    } else if (autoLoad) {
      loadPrograms();
    } else {
      _isLoading = false;
    }
  }

  // ---------------------------------------------------------------------
  // Programs
  // ---------------------------------------------------------------------
  List<Program> _programs = [];
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the programs. Used on start-up and by the Retry button / pull-to-refresh.
  Future<void> loadPrograms() async {
    _isLoading = true;
    _error = null;
    _safeNotify();
    try {
      _programs = await _service.fetchPrograms();
    } catch (_) {
      _error = 'We could not load the programs. Please try again.';
    }
    _isLoading = false;
    _safeNotify();
  }

  /// Synchronize all user-dependent data (registrations & notifications) with backend.
  Future<void> syncWithBackend() async {
    try {
      // 1. Refresh programs from backend
      final freshPrograms = await _service.fetchPrograms();
      if (freshPrograms.isNotEmpty) {
        _programs = freshPrograms;
      }

      // 2. Refresh registrations
      final regs = await _service.fetchMyRegistrations();
      if (regs.isNotEmpty) {
        _userRegistrations
          ..clear()
          ..addAll(regs);
        _registeredIds
          ..clear()
          ..addAll(regs.map((r) => r.programId));
      } else if (ApiClient.instance.token != null) {
        _userRegistrations.clear();
        _registeredIds.clear();
      }

      // 3. Refresh notifications
      final notifResult = await _notificationService.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(notifResult.notifications);
    } catch (_) {
      // Silently fall back to cached data if network momentarily fails
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final List<String> categories = const [
    'All',
    'Workshop',
    'Seminar',
    'Career',
  ];

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      title: 'Event Registration Confirmed',
      message: 'You are registered for Design Thinking Workshop on Oct 15, 2026.',
      timeAgo: '2h ago',
      icon: Icons.event_available_outlined,
    ),
    AppNotification(
      id: 'n2',
      title: 'New Announcement',
      message: "Campus Innovation Day is next week. Don't forget to register!",
      timeAgo: '5h ago',
      icon: Icons.campaign_outlined,
    ),
    AppNotification(
      id: 'n3',
      title: 'Feedback Request',
      message: "We'd love to hear your thoughts about the Career Skills Bootcamp.",
      timeAgo: '1d ago',
      icon: Icons.rate_review_outlined,
    ),
    AppNotification(
      id: 'n4',
      title: 'Event Reminder',
      message: 'Tech & Product Meet is tomorrow at 4:00 PM.',
      timeAgo: '1d ago',
      icon: Icons.notifications_active_outlined,
      read: true,
    ),
    AppNotification(
      id: 'n5',
      title: 'Program Update',
      message: 'New resources were added to the AI & Future Skills program.',
      timeAgo: '2d ago',
      icon: Icons.menu_book_outlined,
      read: true,
    ),
  ];

  final Set<String> _registeredIds = {};
  final List<UserRegistration> _userRegistrations = [];
  final List<FeedbackEntry> _feedback = [];
  String _selectedCategory = 'All';
  String _query = '';

  List<Program> get allPrograms => _programs;
  String get selectedCategory => _selectedCategory;

  List<Program> get filteredPrograms {
    return _programs.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesQuery = p.title.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Program> get registeredPrograms =>
      _programs.where((p) => isRegistered(p.id)).toList();

  List<Program> get upcomingPrograms =>
      _programs.where((p) => !isRegistered(p.id)).toList();

  void clearFilters() {
    _selectedCategory = 'All';
    _query = '';
    _safeNotify();
  }

  // ---------------------------------------------------------------------
  // User Registrations & Learning Progress
  // ---------------------------------------------------------------------
  List<UserRegistration> get registrations =>
      List.unmodifiable(_userRegistrations);

  List<UserRegistration> get ongoingRegistrations =>
      _userRegistrations.where((r) => r.isOngoing).toList();

  List<UserRegistration> get completedRegistrations =>
      _userRegistrations.where((r) => r.isCompleted).toList();

  UserRegistration? getRegistration(String programId) {
    try {
      return _userRegistrations.firstWhere((r) => r.programId == programId);
    } catch (_) {
      return null;
    }
  }

  int get ongoingCount => ongoingRegistrations.length;
  int get completedCount => completedRegistrations.length;

  // ---------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------
  List<FeedbackEntry> get feedbackEntries => List.unmodifiable(_feedback);
  int get feedbackCount => _feedback.length;

  Future<bool> addFeedback(FeedbackEntry entry) async {
    _feedback.add(entry);
    _safeNotify();

    try {
      await _service.submitFeedback(entry);
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> submitFeedback(FeedbackEntry entry) => addFeedback(entry);

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> markRead(String id) async {
    for (final n in _notifications) {
      if (n.id == id && !n.read) {
        n.read = true;
        _safeNotify();

        // Only send network PATCH if id is a valid 24-character hex MongoDB ObjectId
        if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
          try {
            await _notificationService.markRead(id);
          } catch (_) {}
        }
        break;
      }
    }
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    _safeNotify();
    try {
      await _notificationService.markAllRead();
    } catch (_) {}
  }

  Future<void> reloadNotifications() async {
    try {
      final result = await _notificationService.fetchNotifications();
      _notifications
        ..clear()
        ..addAll(result.notifications);
      _safeNotify();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Registration & Module Completion
  // ---------------------------------------------------------------------
  int get registeredCount => _registeredIds.length;

  bool isRegistered(String id) => _registeredIds.contains(id);

  int seatsTaken(Program p) => p.registered + (isRegistered(p.id) ? 1 : 0);

  int spotsLeft(Program p) => p.capacity - seatsTaken(p);

  void setCategory(String category) {
    _selectedCategory = category;
    _safeNotify();
  }

  void setQuery(String query) {
    _query = query;
    _safeNotify();
  }

  /// Registers user for a program and calls backend API.
  Future<bool> register(Program p) async {
    if (isRegistered(p.id) || spotsLeft(p) <= 0) {
      return false;
    }

    _registeredIds.add(p.id);

    // Optimistically add to user registrations
    _userRegistrations.removeWhere((r) => r.programId == p.id);
    _userRegistrations.insert(
      0,
      UserRegistration(
        id: 'local_${p.id}',
        programId: p.id,
        completedModules: const [],
        progress: 0,
        status: 'ongoing',
        registeredAt: DateTime.now(),
        program: p,
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        id: 'reg_${p.id}',
        title: 'Event Registration Confirmed',
        message: 'You are registered for ${p.title} on ${p.date}.',
        timeAgo: 'Just now',
        icon: Icons.event_available_outlined,
      ),
    );
    _safeNotify();

    try {
      final updated = await _service.registerForProgram(p.id);
      final idx = _programs.indexWhere((item) => item.id == p.id);
      if (idx != -1) {
        _programs[idx] = updated;
      }

      // Re-sync backend notifications and registrations
      try {
        final freshRegs = await _service.fetchMyRegistrations();
        if (freshRegs.isNotEmpty) {
          _userRegistrations
            ..clear()
            ..addAll(freshRegs);
        }
        await reloadNotifications();
      } catch (_) {}

      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409 ||
          e.message.toLowerCase().contains('already registered')) {
        // Backend confirms the user is already registered. Sync and reflect it locally!
        _registeredIds.add(p.id);
        _safeNotify();
        await syncWithBackend();
        return true;
      }
      if (e.message.contains('status 400') && e.data == null) {
        return true;
      }
      _registeredIds.remove(p.id);
      _userRegistrations.removeWhere((r) => r.programId == p.id);
      _safeNotify();
      rethrow;
    } catch (_) {
      // Offline fallback: keep local state
      return true;
    }
  }

  /// Cancels registration for a program.
  Future<bool> unregister(Program p) async {
    if (!isRegistered(p.id)) return false;

    _registeredIds.remove(p.id);
    _userRegistrations.removeWhere((r) => r.programId == p.id);
    _safeNotify();

    try {
      final updated = await _service.cancelRegistration(p.id);
      if (updated != null) {
        final idx = _programs.indexWhere((item) => item.id == p.id);
        if (idx != -1) {
          _programs[idx] = updated;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Clears user-specific registrations and notifications on logout.
  void clearUserData() {
    _registeredIds.clear();
    _userRegistrations.clear();
    _safeNotify();
  }

  /// Toggles module completion for an enrolled program and updates progress.
  Future<bool> toggleModule(String programId, int moduleIndex) async {
    final program = _programs.cast<Program?>().firstWhere(
          (p) => p?.id == programId,
          orElse: () => null,
        );
    final total =
        (program?.learningPath.length ?? 0) > 0 ? program!.learningPath.length : 1;

    // Optimistic local update
    final regIndex =
        _userRegistrations.indexWhere((r) => r.programId == programId);
    if (regIndex != -1) {
      final cur = _userRegistrations[regIndex];
      final modules = List<int>.from(cur.completedModules);
      if (modules.contains(moduleIndex)) {
        modules.remove(moduleIndex);
      } else {
        modules.add(moduleIndex);
      }
      final newProgress =
          ((modules.length / total) * 100).round().clamp(0, 100);
      final newStatus = newProgress == 100 ? 'completed' : 'ongoing';

      _userRegistrations[regIndex] = cur.copyWith(
        completedModules: modules,
        progress: newProgress,
        status: newStatus,
        completedAt: newStatus == 'completed' ? DateTime.now() : null,
      );
      _safeNotify();
    } else {
      final modules = [moduleIndex];
      final newProgress =
          ((modules.length / total) * 100).round().clamp(0, 100);
      _userRegistrations.add(
        UserRegistration(
          id: 'local_$programId',
          programId: programId,
          completedModules: modules,
          progress: newProgress,
          status: newProgress == 100 ? 'completed' : 'ongoing',
          registeredAt: DateTime.now(),
          program: program,
        ),
      );
      _safeNotify();
    }

    try {
      final updatedReg =
          await _service.toggleModuleCompletion(programId, moduleIndex);
      final idx =
          _userRegistrations.indexWhere((r) => r.programId == programId);
      if (idx != -1) {
        _userRegistrations[idx] = updatedReg.copyWith(
          program: _userRegistrations[idx].program ?? program,
        );
      } else {
        _userRegistrations.add(updatedReg.copyWith(program: program));
      }
      if (updatedReg.isCompleted) {
        await reloadNotifications();
      }
      _safeNotify();
      return true;
    } catch (_) {
      return true;
    }
  }
}
