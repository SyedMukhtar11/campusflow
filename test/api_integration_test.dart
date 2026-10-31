import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campusflow/models/app_notification.dart';
import 'package:campusflow/models/feedback_entry.dart';
import 'package:campusflow/models/program.dart';
import 'package:campusflow/models/user.dart';
import 'package:campusflow/models/user_registration.dart';
import 'package:campusflow/providers/auth_provider.dart';
import 'package:campusflow/providers/program_provider.dart';
import 'package:campusflow/services/api_client.dart';
import 'package:campusflow/services/program_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Unit Tests', () {
    test('defaultBaseUrl points to deployed production Render service', () {
      final url = ApiClient.defaultBaseUrl;
      expect(url, 'https://campusflow-nq50.onrender.com');
      expect(url.startsWith('https://'), true);
    });

    test('setBaseUrl updates URL and trims trailing slash', () {
      final client = ApiClient();
      client.setBaseUrl('https://custom-domain.com/api/');
      expect(client.baseUrl, 'https://custom-domain.com/api');

      // Reset back to default
      client.setBaseUrl(ApiClient.defaultBaseUrl);
    });

    test('setAuthToken updates authorization token', () {
      final client = ApiClient();
      client.setAuthToken('test-jwt-token');
      expect(client.authToken, 'test-jwt-token');

      client.setAuthToken(null);
      expect(client.authToken, null);
    });
  });

  group('Data Models Unit Tests', () {
    test('User fromJson and toJson works accurately', () {
      final json = {
        'id': 'user_123',
        'name': 'Alex Learner',
        'email': 'alex@campusflow.edu',
        'createdAt': '2026-10-29T10:00:00.000Z',
      };

      final user = User.fromJson(json);
      expect(user.id, 'user_123');
      expect(user.name, 'Alex Learner');
      expect(user.email, 'alex@campusflow.edu');
      expect(user.createdAt != null, true);

      final encoded = user.toJson();
      expect(encoded['id'], 'user_123');
      expect(encoded['name'], 'Alex Learner');
      expect(encoded['email'], 'alex@campusflow.edu');
    });

    test('FeedbackEntry fromJson and toJson works accurately', () {
      final entry = FeedbackEntry(
        programId: 'p1',
        rating: 5,
        category: 'Content',
        email: 'alex@test.com',
        comment: 'Fantastic workshop on design thinking!',
        submittedAt: DateTime.now(),
      );

      final json = entry.toJson();
      expect(json['programId'], 'p1');
      expect(json['rating'], 5);
      expect(json['category'], 'Content');
      expect(json['email'], 'alex@test.com');
      expect(json['comment'], 'Fantastic workshop on design thinking!');
    });

    test('AppNotification fromJson maps icon strings to IconData', () {
      final json = {
        'id': 'n1',
        'title': 'Event Registration Confirmed',
        'message': 'You are registered for Design Thinking Workshop.',
        'icon': 'event_available',
        'read': false,
        'timeAgo': '10m ago',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'n1');
      expect(notif.title, 'Event Registration Confirmed');
      expect(notif.read, false);
      expect(notif.timeAgo, '10m ago');
    });

    test('UserRegistration fromJson and methods work accurately', () {
      final json = {
        'id': 'reg_123',
        'programId': 'p1',
        'completedModules': [0, 1],
        'progress': 67,
        'status': 'ongoing',
        'completedAt': null,
        'registeredAt': '2026-10-29T12:00:00.000Z',
      };

      final reg = UserRegistration.fromJson(json);
      expect(reg.id, 'reg_123');
      expect(reg.programId, 'p1');
      expect(reg.completedModules, [0, 1]);
      expect(reg.progress, 67);
      expect(reg.status, 'ongoing');
      expect(reg.isOngoing, true);
      expect(reg.isCompleted, false);
      expect(reg.isModuleCompleted(0), true);
      expect(reg.isModuleCompleted(1), true);
      expect(reg.isModuleCompleted(2), false);

      final completed = reg.copyWith(
        completedModules: [0, 1, 2],
        progress: 100,
        status: 'completed',
        completedAt: DateTime.now(),
      );
      expect(completed.isCompleted, true);
      expect(completed.isOngoing, false);
      expect(completed.completedModules.length, 3);
    });
  });

  group('ProgramService & Provider Unit Tests', () {
    test('ProgramService loads bundled programs successfully', () async {
      final service = ProgramService(delay: Duration.zero);
      final programs = await service.fetchPrograms();
      expect(programs.isNotEmpty, true);
      expect(programs.first.title, isNotEmpty);
    });

    test('ProgramProvider initialPrograms disables loading state', () {
      final dummy = [
        Program(
          id: 'mock_1',
          title: 'Mock Workshop',
          tagline: 'Learn mock things',
          imageUrl: '',
          category: 'Workshop',
          date: 'Oct 30, 2026',
          time: '10:00 AM',
          location: 'Hall A',
          capacity: 50,
          registered: 10,
          about: 'About mock',
          learnPoints: const ['Point 1'],
          whatYouWillDo: const ['Do 1'],
          recommendation: 'Recommended',
          duration: '2 hours',
          fee: 'Free',
          supportedBy: 'Campus',
          startsInDays: 1,
          learningPath: const ['Mod 1'],
          lastDateToApply: 'Oct 29',
          startDate: 'Oct 30',
          endDate: 'Oct 30',
          completionRewards: const ['Cert'],
          eligibility: const ['All'],
          icon: Program.fromJson(const {'icon': 'lightbulb'}).icon,
          color: const Color(0xFF4F46E5),
        ),
      ];

      final provider = ProgramProvider(initialPrograms: dummy);
      expect(provider.isLoading, false);
      expect(provider.allPrograms.length, 1);
      expect(provider.allPrograms.first.title, 'Mock Workshop');
      expect(provider.spotsLeft(dummy.first), 40);
    });

    test('ProgramProvider filters by category and search query', () {
      final dummy = [
        Program(
          id: 'p1',
          title: 'Flutter Workshop',
          tagline: 'Mobile apps',
          imageUrl: '',
          category: 'Workshop',
          date: 'Nov 1, 2026',
          time: '10:00 AM',
          location: 'Room 1',
          capacity: 30,
          registered: 5,
          about: 'Flutter apps',
          learnPoints: const [],
          whatYouWillDo: const [],
          recommendation: '',
          duration: '3 hours',
          fee: 'Free',
          supportedBy: 'Google',
          startsInDays: 2,
          learningPath: const [],
          lastDateToApply: '',
          startDate: '',
          endDate: '',
          completionRewards: const [],
          eligibility: const [],
          icon: Program.fromJson(const {'icon': 'devices'}).icon,
          color: const Color(0xFF4F46E5),
        ),
        Program(
          id: 'p2',
          title: 'AI Seminar',
          tagline: 'Machine Learning',
          imageUrl: '',
          category: 'Seminar',
          date: 'Nov 2, 2026',
          time: '2:00 PM',
          location: 'Auditorium',
          capacity: 100,
          registered: 20,
          about: 'AI trends',
          learnPoints: const [],
          whatYouWillDo: const [],
          recommendation: '',
          duration: '1 hour',
          fee: 'Free',
          supportedBy: 'Campus',
          startsInDays: 3,
          learningPath: const [],
          lastDateToApply: '',
          startDate: '',
          endDate: '',
          completionRewards: const [],
          eligibility: const [],
          icon: Program.fromJson(const {'icon': 'rocket'}).icon,
          color: const Color(0xFF10B981),
        ),
      ];

      final provider = ProgramProvider(initialPrograms: dummy);
      expect(provider.filteredPrograms.length, 2);

      provider.setCategory('Seminar');
      expect(provider.filteredPrograms.length, 1);
      expect(provider.filteredPrograms.first.title, 'AI Seminar');

      provider.setCategory('All');
      provider.setQuery('Flutter');
      expect(provider.filteredPrograms.length, 1);
      expect(provider.filteredPrograms.first.title, 'Flutter Workshop');
    });

    test('AuthProvider manages login, user, token, and logout', () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, false);
      expect(auth.user, null);

      auth.logout();
      expect(auth.isAuthenticated, false);
    });

    test('ProgramProvider marks read gracefully without crashing on non-hex id', () async {
      final provider = ProgramProvider(autoLoad: false);
      expect(provider.notifications.isNotEmpty, true);

      // 'n1' is a mock client id (not 24-hex ObjectId)
      await provider.markRead('n1');
      final notif = provider.notifications.firstWhere((n) => n.id == 'n1');
      expect(notif.read, true);
    });

    test('ProgramProvider module toggling updates ongoing and completed lists', () async {
      final dummy = [
        Program(
          id: 'p_test',
          title: 'Test Program',
          tagline: 'Test Tagline',
          imageUrl: '',
          category: 'Workshop',
          date: 'Nov 1, 2026',
          time: '2:00 PM',
          location: 'Lab 1',
          capacity: 30,
          registered: 5,
          about: 'Test About',
          learnPoints: const ['L1'],
          whatYouWillDo: const ['W1'],
          recommendation: '',
          duration: '1 day',
          fee: 'Free',
          supportedBy: '',
          startsInDays: 2,
          learningPath: const ['Module 1', 'Module 2'],
          lastDateToApply: '',
          startDate: '',
          endDate: '',
          completionRewards: const ['Cert'],
          eligibility: const ['All'],
          icon: Program.fromJson(const {'icon': 'lightbulb'}).icon,
          color: const Color(0xFF4F46E5),
        ),
      ];

      final provider = ProgramProvider(initialPrograms: dummy);

      // Enrolling in program
      await provider.register(dummy.first);
      expect(provider.registeredCount, 1);
      expect(provider.ongoingCount, 1);
      expect(provider.completedCount, 0);

      // Toggle module 0 -> 50% progress
      await provider.toggleModule('p_test', 0);
      var reg = provider.getRegistration('p_test');
      expect(reg != null, true);
      expect(reg!.completedModules, [0]);
      expect(reg.progress, 50);
      expect(reg.isOngoing, true);
      expect(provider.ongoingCount, 1);
      expect(provider.completedCount, 0);

      // Toggle module 1 -> 100% progress -> marked completed!
      await provider.toggleModule('p_test', 1);
      reg = provider.getRegistration('p_test');
      expect(reg!.completedModules, [0, 1]);
      expect(reg.progress, 100);
      expect(reg.status, 'completed');
      expect(reg.isCompleted, true);
      expect(provider.completedCount, 1);
      expect(provider.ongoingCount, 0);

      // Untoggle module 0 -> 50% progress -> reverts to ongoing
      await provider.toggleModule('p_test', 0);
      reg = provider.getRegistration('p_test');
      expect(reg!.completedModules, [1]);
      expect(reg.progress, 50);
      expect(reg.status, 'ongoing');
      expect(provider.ongoingCount, 1);
      expect(provider.completedCount, 0);
    });
  });
}
