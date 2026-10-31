import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    this.read = false,
  });

  static const Map<String, IconData> _iconMap = {
    'campaign': Icons.campaign_outlined,
    'rate_review': Icons.rate_review_outlined,
    'notifications_active': Icons.notifications_active_outlined,
    'menu_book': Icons.menu_book_outlined,
    'event_available': Icons.event_available_outlined,
    'event_busy': Icons.event_busy_outlined,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final iconName = json['icon']?.toString() ?? 'campaign';
    final resolvedIcon = _iconMap[iconName] ?? Icons.notifications_outlined;

    return AppNotification(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timeAgo: json['timeAgo']?.toString() ?? 'Just now',
      icon: resolvedIcon,
      read: json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timeAgo': timeAgo,
      'read': read,
    };
  }
}
