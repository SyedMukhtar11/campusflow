import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/program.dart';
import '../providers/program_provider.dart';
import '../utils/context_colors.dart';
import '../utils/theme.dart';
import '../widgets/feedback_button.dart';
import 'registration_confirmation_screen.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final Program program;
  const ProgramDetailsScreen({super.key, required this.program});

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  bool _isRegistering = false;

  Future<void> _handleRegister(ProgramProvider provider) async {
    setState(() => _isRegistering = true);
    try {
      final success = await provider.register(widget.program);
      if (!mounted) return;
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationConfirmationScreen(
              program: widget.program,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final provider = context.watch<ProgramProvider>();
    final registered = provider.isRegistered(program.id);
    final reg = provider.getRegistration(program.id);
    final isProgramCompleted = reg?.isCompleted ?? false;
    final progress = reg?.progress ?? 0;
    final completedModules = reg?.completedModules ?? const <int>[];
    final left = provider.spotsLeft(program);
    final full = left <= 0 && !registered;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 245,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: program.color,
            actions: [
              IconButton(
                tooltip: 'Save program',
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    program.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: program.color,
                      child: Icon(program.icon, size: 84, color: Colors.white),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(program.category),
                        labelStyle: const TextStyle(color: AppColors.navy),
                        backgroundColor: AppColors.lavender,
                        side: BorderSide.none,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        program.title,
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: context.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        program.tagline,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(program.about, style: _bodyStyle(context)),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Program at a glance',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _Fact(
                              icon: Icons.schedule,
                              label: program.duration,
                            ),
                            _Fact(
                              icon: Icons.payments_outlined,
                              label: program.fee,
                            ),
                            _Fact(
                              icon: Icons.location_on_outlined,
                              label: program.location,
                            ),
                          ],
                        ),
                      ),
                      _Section(
                        title: 'What you will do',
                        child: _BulletList(program.whatYouWillDo),
                      ),
                      _Section(
                        title: 'Recommendation',
                        child: _Callout(
                          icon: Icons.thumb_up_alt_outlined,
                          text: program.recommendation,
                        ),
                      ),
                      _Section(
                        title: 'Supported by',
                        child: _Callout(
                          icon: Icons.school_outlined,
                          text: program.supportedBy,
                        ),
                      ),
                      _Section(
                        title: 'Learning Path',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (registered) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isProgramCompleted
                                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                                      : AppColors.lavender.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isProgramCompleted
                                        ? const Color(0xFF059669).withValues(alpha: 0.3)
                                        : AppColors.indigo.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isProgramCompleted
                                                  ? Icons.workspace_premium
                                                  : Icons.trending_up,
                                              size: 18,
                                              color: isProgramCompleted
                                                  ? const Color(0xFF059669)
                                                  : AppColors.indigo,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isProgramCompleted
                                                  ? 'Program Completed! 🎉'
                                                  : 'Your Progress',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isProgramCompleted
                                                    ? const Color(0xFF059669)
                                                    : AppColors.indigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '$progress%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isProgramCompleted
                                                ? const Color(0xFF059669)
                                                : AppColors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress / 100,
                                        minHeight: 6,
                                        backgroundColor: context.isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isProgramCompleted
                                              ? const Color(0xFF059669)
                                              : AppColors.indigo,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isProgramCompleted
                                          ? 'All modules completed! Your completion rewards are unlocked.'
                                          : '${completedModules.length} of ${program.learningPath.length} modules completed. Tap "Mark as complete" as you finish each module.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            for (
                              var i = 0;
                              i < program.learningPath.length;
                              i++
                            )
                              _PathItem(
                                number: i + 1,
                                title: 'Module ${i + 1}',
                                description: program.learningPath[i],
                                isLast: i == program.learningPath.length - 1,
                                isRegistered: registered,
                                isCompleted: completedModules.contains(i),
                                onToggle: () =>
                                    provider.toggleModule(program.id, i),
                              ),
                          ],
                        ),
                      ),
                      _Section(
                        title: 'Upcoming cohort dates',
                        child: _DateTable(
                          lastDateToApply: program.lastDateToApply,
                          startDate: program.startDate,
                          endDate: program.endDate,
                        ),
                      ),
                      _Section(
                        title: 'Rewards for completion',
                        child: _BulletList(
                          program.completionRewards,
                          icon: Icons.stars,
                        ),
                      ),
                      _Section(
                        title: 'Eligibility',
                        child: _BulletList(
                          program.eligibility,
                          icon: Icons.verified_user_outlined,
                        ),
                      ),
                      _Section(
                        title: 'Share your experience',
                        child: FeedbackButton(program: program),
                      ),
                      _Section(
                        title: 'Your rewards',
                        child: Card(
                          elevation: 0,
                          color: context.isDark
                              ? const Color(0xFF3A2A12)
                              : const Color(0xFFFFF7ED),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Everything you earn in one place',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                ...program.completionRewards.map(
                                  (reward) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.workspace_premium,
                                          size: 19,
                                          color: Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(reward)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (registered || full || _isRegistering)
                ? null
                : () => _handleRegister(provider),
            child: _isRegistering
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    registered
                        ? 'Registered ✓'
                        : full
                        ? 'Event full'
                        : 'Register',
                  ),
          ),
        ),
      ),
    );
  }
}

TextStyle _bodyStyle(BuildContext context) =>
    TextStyle(color: context.textMuted, height: 1.5);

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Fact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.textPrimary),
          const SizedBox(width: 7),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  const _BulletList(this.items, {this.icon = Icons.check_circle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 19, color: AppColors.teal),
                  const SizedBox(width: 9),
                  Expanded(child: Text(item, style: _bodyStyle(context))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Callout({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.textPrimary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _bodyStyle(context))),
        ],
      ),
    );
  }
}

class _PathItem extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool isLast;
  final bool isRegistered;
  final bool isCompleted;
  final VoidCallback? onToggle;

  const _PathItem({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
    this.isRegistered = false,
    this.isCompleted = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = isCompleted
        ? const Color(0xFF059669)
        : (context.isDark ? AppColors.indigo : AppColors.navy);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: avatarColor,
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : AppColors.lavender,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? const Color(0xFF059669)
                                : context.textPrimary,
                          ),
                        ),
                      ),
                      if (isRegistered && onToggle != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                                  : AppColors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFF059669)
                                    : AppColors.indigo.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: isCompleted
                                      ? const Color(0xFF059669)
                                      : AppColors.indigo,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isCompleted ? 'Completed ✓' : 'Mark as complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? const Color(0xFF059669)
                                        : AppColors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: isCompleted
                          ? context.textMuted
                          : context.textPrimary.withValues(alpha: 0.85),
                      height: 1.4,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
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
}

class _DateTable extends StatelessWidget {
  final String lastDateToApply;
  final String startDate;
  final String endDate;
  const _DateTable({
    required this.lastDateToApply,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          _DateRow(label: 'Last date to apply', value: lastDateToApply),
          _DateRow(label: 'Start date', value: startDate),
          _DateRow(label: 'End date', value: endDate),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  const _DateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.dateAccent, height: 1.5),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
