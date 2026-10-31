import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// Fetches all notifications for the authenticated user along with unreadCount.
  Future<({int unreadCount, List<AppNotification> notifications})>
      fetchNotifications() async {
    final response = await _api.get('/notifications');
    final unreadCount = (response['unreadCount'] as num?)?.toInt() ?? 0;
    final list = (response['notifications'] as List<dynamic>? ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();

    return (unreadCount: unreadCount, notifications: list);
  }

  /// Marks a specific notification as read.
  Future<AppNotification> markRead(String id) async {
    final response = await _api.patch('/notifications/$id/read');
    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  /// Marks all notifications for the current user as read.
  Future<({int unreadCount, List<AppNotification> notifications})>
      markAllRead() async {
    final response = await _api.patch('/notifications/read-all');
    final unreadCount = (response['unreadCount'] as num?)?.toInt() ?? 0;
    final list = (response['notifications'] as List<dynamic>? ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();

    return (unreadCount: unreadCount, notifications: list);
  }

  /// Deletes a single notification.
  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }

  /// Clears all notifications for the current user.
  Future<void> clearAll() async {
    await _api.delete('/notifications');
  }
}
