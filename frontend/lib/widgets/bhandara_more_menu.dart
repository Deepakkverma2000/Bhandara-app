import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BhandaraMoreMenu extends StatelessWidget {
  final VoidCallback onReport;

  const BhandaraMoreMenu({super.key, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textDark, size: 22),
        onSelected: (value) {
          if (value == 'report') onReport();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: AppColors.templeRed),
                SizedBox(width: 10),
                Text('Report'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
