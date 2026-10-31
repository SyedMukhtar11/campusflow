import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../config/api_config.dart';
import '../models/feedback_entry.dart';
import '../models/program.dart';
import 'api_client.dart';

/// Loads programs from the backend (when USE_API=true) or from the local
/// JSON file. If the backend cannot be reached, the local JSON is used so the
/// app still works.
class ProgramService {
  final ApiClient _api;
  final Future<String> Function() _loader;
  final ApiClient? _api;

  /// Optional delay used in UI previews or unit tests.
  final Duration delay;

  /// True when the last load came from the local JSON file.
  bool usedLocalData = true;

  ProgramService({
    ApiClient? api,
    Future<String> Function()? loader,
    ApiClient? api,
    this.delay = const Duration(milliseconds: 800),
  })  : _loader = loader ?? _defaultLoader,
        _api = api;

  static Future<String> _defaultLoader() =>
      rootBundle.loadString('assets/data/programs.json');

  /// Fetches programs from the backend API, falling back to local JSON if offline.
  Future<List<Program>> fetchPrograms({
    String? category,
    String? query,
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    final api = _api;
    if (ApiConfig.useApi && api != null) {
      try {
        final data = await api.get(ApiConfig.programsPath);
        final programs = _parse(_extractList(data));
        if (programs.isNotEmpty) {
          usedLocalData = false;
          return programs;
        }
      } catch (e) {
        debugPrint('API programs failed, using local data: $e');
      }
    }
    usedLocalData = true;
    return _parse(json.decode(await _loader()));
  }

  List<Program> _parse(dynamic list) {
    if (list is! List) {
      throw const FormatException('Expected a JSON list of programs');
    }
    return list
        .map((e) => Program.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (category != null && category != 'All') {
      list = list.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      list = list
          .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return list;
  }

  /// Fetches a single program by its ID.
  Future<Program> fetchProgramById(String id) async {
    try {
      final response = await _api.get('/programs/$id');
      return Program.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      final all = await fetchPrograms();
      return all.firstWhere((p) => p.id == id);
    }
  }

  /// Registers the current user for a program via the backend.
  Future<Program> registerForProgram(String id) async {
    final response = await _api.post('/programs/$id/register');
    final programData = response['program'] as Map<String, dynamic>?;
    if (programData != null) {
      return Program.fromJson(programData);
    }
    return fetchProgramById(id);
  }

  /// Cancels a user's registration for a program.
  Future<Program?> cancelRegistration(String id) async {
    final response = await _api.delete('/programs/$id/register');
    final programData = response['program'] as Map<String, dynamic>?;
    if (programData != null) {
      return Program.fromJson(programData);
    }
    return null;
  }

  /// Fetches the list of programs registered by the authenticated user.
  Future<List<String>> fetchMyRegisteredProgramIds() async {
    final list = await fetchMyRegistrations();
    return list.map((r) => r.programId).toList();
  }

  /// Fetches detailed user registrations including module progress and status.
  Future<List<UserRegistration>> fetchMyRegistrations() async {
    try {
      final dynamic response = await _api.get('/registrations');
      if (response is List) {
        return response
            .map((item) =>
                UserRegistration.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Non-critical: return empty list if offline or unauthorized
    }
    return [];
  }

  /// Toggles a module's completed state for an enrolled program.
  Future<UserRegistration> toggleModuleCompletion(
    String programId,
    int moduleIndex,
  ) async {
    final dynamic response = await _api.patch(
      '/registrations/$programId/modules/$moduleIndex/toggle',
    );
    if (response is Map<String, dynamic> && response['registration'] != null) {
      return UserRegistration.fromJson(
        response['registration'] as Map<String, dynamic>,
      );
    }
    throw const FormatException('Unexpected response when toggling module');
  }

  /// Submits user feedback for a program.
  Future<FeedbackEntry> submitFeedback(FeedbackEntry entry) async {
    final response = await _api.post(
      '/programs/${entry.programId}/feedback',
      body: entry.toJson(),
    );
    final feedbackData = response['feedback'] as Map<String, dynamic>?;
    if (feedbackData != null) {
      return FeedbackEntry.fromJson(feedbackData);
    }
    return entry;
  }

  dynamic _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['programs', 'data', 'items', 'results']) {
        if (data[key] is List) return data[key];
      }
    }
    throw const FormatException('Unexpected programs response');
  }

  /// Sends a registration to the backend (does nothing in demo mode).
  Future<void> submitRegistration(String programId) async {
    final api = _api;
    if (!ApiConfig.useApi || api == null) return;
    await api.post(ApiConfig.registrationsPath, {'programId': programId});
  }

  /// Sends feedback to the backend (does nothing in demo mode).
  Future<void> submitFeedback(FeedbackEntry entry) async {
    final api = _api;
    if (!ApiConfig.useApi || api == null) return;
    await api.post(ApiConfig.feedbackPath, {
      'programId': entry.programId,
      'rating': entry.rating,
      'category': entry.category,
      'email': entry.email,
      'comment': entry.comment,
    });
  }
}
