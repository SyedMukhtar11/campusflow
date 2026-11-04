import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/program_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/context_colors.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final programs = context.watch<ProgramProvider>();
    final theme = context.watch<ThemeProvider>();

    final name = auth.user?.name ?? 'Learner';
    final email = auth.user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.indigo,
              child: Text(initial,
                  style: const TextStyle(fontSize: 36, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(name,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
          ),
          if (email.isNotEmpty)
            Center(
              child: Text(email, style: TextStyle(color: context.textMuted)),
            ),
          Center(
            child: Text('Learner', style: TextStyle(color: context.textMuted)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _Stat(
                  label: 'Registered',
                  value: '${programs.registeredCount}',
                  icon: Icons.how_to_reg_outlined),
              const SizedBox(width: 12),
              _Stat(
                  label: 'Feedback sent',
                  value: '${programs.feedbackCount}',
                  icon: Icons.rate_review_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: SwitchListTile(
                secondary: Icon(
                    theme.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                title: const Text('Dark mode'),
                value: theme.isDark,
                onChanged: (_) => theme.toggle(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () {
              context.read<ProgramProvider>().clearUserData();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary)),
            Text(label,
                style: TextStyle(fontSize: 12, color: context.textMuted)),
          ],
        ),
      ),
    );
  }
}
