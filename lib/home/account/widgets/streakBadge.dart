// lib/home/account/widgets/streak_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/home/account/accountViewModel.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Streak is server-owned; read it from the backend-backed account.
    final streak = context.select<AccountViewModel, int>(
      (vm) => vm.account?.currentStreak ?? 0,
    );
    final best = context.select<AccountViewModel, int>(
      (vm) => vm.account?.bestStreak ?? 0,
    );

    // Your brand colors here
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 24, color: Colors.teal),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak-day streak',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                'Best: $best',
                style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
