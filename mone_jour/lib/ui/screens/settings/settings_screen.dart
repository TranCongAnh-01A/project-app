import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../logic/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài đặt',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'Giao diện',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                // Nếu themeMode == system, ta kiểm tra độ sáng hệ thống để lấy giá trị tương đối
                final isSystemDark =
                    MediaQuery.of(context).platformBrightness == Brightness.dark;
                final isDark = themeMode == ThemeMode.dark ||
                    (themeMode == ThemeMode.system && isSystemDark);

                return SwitchListTile(
                  title: Text(
                    'Chế độ tối (Dark Mode)',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Đổi màu nền đen để bảo vệ mắt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: isDark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primaryPastel,
                  onChanged: (value) {
                    context.read<ThemeCubit>().toggleTheme(value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
