import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/program_provider.dart';
import '../utils/context_colors.dart';
import '../utils/theme.dart';
import '../widgets/program_card.dart';
import '../widgets/state_views.dart';
import '../widgets/theme_toggle_button.dart';
import 'notifications_screen.dart';
import 'program_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSeeAll;
  const HomeScreen({super.key, required this.onSeeAll});

  static const _announcements = [
    ('Campus Innovation Day is next week', 'Oct 10, 2026'),
    ('New Program: AI & Future Skills', 'Oct 8, 2026'),
    ('Campus office hours update', 'Oct 6, 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: LoadingView());
    }
    if (provider.error != null) {
      return Scaffold(
        body: ErrorView(
          message: provider.error!,
          onRetry: provider.loadPrograms,
        ),
      );
    }

    final upcoming = provider.allPrograms.take(3).toList();
    final auth = context.watch<AuthProvider?>();
    final userName = auth?.user?.name.trim().isNotEmpty == true
        ? auth!.user!.name.trim().split(' ').first
        : 'Alex';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusFlow',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Browse programs',
            icon: const Icon(Icons.search),
            onPressed: onSeeAll,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              if (provider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppColors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${provider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Good morning, ${context.watch<AuthProvider>().user?.name ?? 'there'} 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening across your campus.",
            style: TextStyle(color: context.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                icon: Icons.menu_book_outlined,
                label: 'Programs',
                value: '${provider.allPrograms.length}',
              ),
              const SizedBox(width: 10),
              const _StatCard(
                icon: Icons.event_outlined,
                label: 'Events',
                value: '8',
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.how_to_reg_outlined,
                label: 'Registered',
                value: '${provider.registeredCount}',
              ),
            ],
          ),
          if (provider.ongoingRegistrations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ongoing Programs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${provider.ongoingCount} active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.ongoingRegistrations.map((reg) {
              final prog = reg.program ??
                  provider.allPrograms.cast<Program?>().firstWhere(
                        (p) => p?.id == reg.programId,
                        orElse: () => null,
                      );
              if (prog == null) return const SizedBox.shrink();
              return _OngoingProgramHomeCard(
                registration: reg,
                program: prog,
              );
            }),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('View all')),
            ],
          ),
          ...upcoming.map(
            (p) => ProgramCard(
              program: p,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgramDetailsScreen(program: p),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._announcements.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: AppColors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          a.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.indigo, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
