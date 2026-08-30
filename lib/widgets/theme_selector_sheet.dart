import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final themeOptions = [
      _ThemeOptionItem(
        mode: AppThemeMode.light,
        title: 'Mode Siang (Terang)',
        subtitle: 'Tampilan bersih, cerah dengan aksen teal',
        icon: Icons.wb_sunny_rounded,
        iconColor: Colors.amber.shade700,
        previewBg: const Color(0xFFF8FAFC),
        previewAccent: Colors.teal.shade700,
      ),
      _ThemeOptionItem(
        mode: AppThemeMode.dark,
        title: 'Mode Malam (Gelap)',
        subtitle: 'Nyaman di mata saat gelap & hemat baterai',
        icon: Icons.nightlight_round,
        iconColor: const Color(0xFF2DD4BF),
        previewBg: const Color(0xFF0F172A),
        previewAccent: const Color(0xFF2DD4BF),
      ),
      _ThemeOptionItem(
        mode: AppThemeMode.sepia,
        title: 'Mode Hangat (Krem / Mushaf)',
        subtitle: 'Warna kertas klasik yang menenangkan mata',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF8D6E63),
        previewBg: const Color(0xFFF4ECD8),
        previewAccent: const Color(0xFF00796B),
      ),
      _ThemeOptionItem(
        mode: AppThemeMode.system,
        title: 'Otomatis (Ikuti Sistem)',
        subtitle: 'Menyesuaikan tema perangkat HP/komputer Anda',
        icon: Icons.brightness_auto_rounded,
        iconColor: Colors.blueGrey,
        previewBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        previewAccent: Colors.teal,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pilihan Mode Baca & Tema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Theme Options List
          ...themeOptions.map((option) {
            final isSelected = themeProvider.currentMode == option.mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  themeProvider.setThemeMode(option.mode);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Preview Circle & Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: option.previewBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: option.previewAccent, width: 2),
                        ),
                        child: Icon(option.icon, color: option.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Radio indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        )
                      else
                        Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.grey.withValues(alpha: 0.5),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeOptionItem {
  final AppThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color previewBg;
  final Color previewAccent;

  const _ThemeOptionItem({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.previewBg,
    required this.previewAccent,
  });
}
