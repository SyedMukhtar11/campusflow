import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/program.dart';
import '../models/user_registration.dart';
import '../providers/program_provider.dart';
import '../utils/context_colors.dart';
import '../utils/theme.dart';
import 'program_details_screen.dart';

class MyProgramsScreen extends StatefulWidget {
  final VoidCallback? onExplore;
  const MyProgramsScreen({super.key, this.onExplore});

  @override
  State<MyProgramsScreen> createState() => _MyProgramsScreenState();
}

class _MyProgramsScreenState extends State<MyProgramsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final ongoing = provider.ongoingRegistrations;
    final completed = provider.completedRegistrations;
    final all = provider.registrations;

    // Calculate average progress across enrolled programs
    final avgProgress = all.isEmpty
        ? 0
        : (all.fold<int>(0, (sum, r) => sum + r.progress) / all.length).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.indigo,
          unselectedLabelColor: context.textMuted,
          indicatorColor: AppColors.indigo,
          indicatorWeight: 3,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Ongoing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ongoing.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _BadgeCount(count: ongoing.length, color: AppColors.indigo),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Completed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (completed.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _BadgeCount(
                      count: completed.length,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'All',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (all.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _BadgeCount(count: all.length, color: AppColors.dateAccent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.syncWithBackend(),
        child: Column(
          children: [
            _SummaryHeader(
              ongoingCount: ongoing.length,
              completedCount: completed.length,
              avgProgress: avgProgress,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProgramListTab(
                    registrations: ongoing,
                    emptyTitle: 'No ongoing programs',
                    emptyMessage:
                        'Enroll in a workshop or seminar to track your learning journey.',
                    onExplore: widget.onExplore,
                  ),
                  _ProgramListTab(
                    registrations: completed,
                    emptyTitle: 'No completed programs yet',
                    emptyMessage:
                        'Finish all modules in your active courses to unlock certificates and rewards.',
                    onExplore: widget.onExplore,
                  ),
                  _ProgramListTab(
                    registrations: all,
                    emptyTitle: 'No enrolled programs',
                    emptyMessage:
                        'Browse our campus catalog to find upcoming opportunities.',
                    onExplore: widget.onExplore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;
  final Color color;
  const _BadgeCount({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int ongoingCount;
  final int completedCount;
  final int avgProgress;

  const _SummaryHeader({
    required this.ongoingCount,
    required this.completedCount,
    required this.avgProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Ongoing',
              value: '$ongoingCount',
              color: AppColors.indigo,
              icon: Icons.play_circle_outline,
            ),
          ),
          Container(width: 1, height: 32, color: context.borderColor),
          Expanded(
            child: _StatColumn(
              label: 'Completed',
              value: '$completedCount',
              color: const Color(0xFF059669),
              icon: Icons.check_circle_outline,
            ),
          ),
          Container(width: 1, height: 32, color: context.borderColor),
          Expanded(
            child: _StatColumn(
              label: 'Avg. Progress',
              value: '$avgProgress%',
              color: const Color(0xFFD97706),
              icon: Icons.donut_large_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: context.textMuted),
        ),
      ],
    );
  }
}

class _ProgramListTab extends StatelessWidget {
  final List<UserRegistration> registrations;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? onExplore;

  const _ProgramListTab({
    required this.registrations,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    if (registrations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: context.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                style: TextStyle(color: context.textMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (onExplore != null) ...[
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: onExplore,
                  child: const Text('Browse Programs'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final provider = context.read<ProgramProvider>();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: registrations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final reg = registrations[index];
        final prog = reg.program ??
            provider.allPrograms.cast<Program?>().firstWhere(
                  (p) => p?.id == reg.programId,
                  orElse: () => null,
                );

        if (prog == null) {
          return const SizedBox.shrink();
        }

        return _LearningProgramCard(registration: reg, program: prog);
      },
    );
  }
}

class _LearningProgramCard extends StatelessWidget {
  final UserRegistration registration;
  final Program program;

  const _LearningProgramCard({
    required this.registration,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final totalModules = program.learningPath.length;
    final completedCount = registration.completedModules.length;
    final isDone = registration.isCompleted;

    // Find next uncompleted module title
    String? nextModuleTitle;
    if (!isDone && totalModules > 0) {
      for (var i = 0; i < totalModules; i++) {
        if (!registration.completedModules.contains(i)) {
          nextModuleTitle = 'Module ${i + 1}: ${program.learningPath[i]}';
          break;
        }
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      color: context.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramDetailsScreen(program: program),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Pill & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      program.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${registration.progress}% Done',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                program.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                program.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: registration.progress / 100,
                  minHeight: 7,
                  backgroundColor: context.isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? const Color(0xFF059669) : AppColors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Modules done text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      '$completedCount of $totalModules modules completed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: Text(
                      program.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              // Next module preview if ongoing
              if (nextModuleTitle != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.next_plan_outlined,
                        size: 16,
                        color: AppColors.indigo,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextModuleTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Action Button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgramDetailsScreen(program: program),
                      ),
                    );
                  },
                  icon: Icon(
                    isDone ? Icons.visibility_outlined : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(isDone ? 'View Rewards' : 'Continue Learning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
