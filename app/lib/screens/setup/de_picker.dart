import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:droiddesk/theme/droid_theme.dart';
import 'package:droiddesk/state/app_state.dart';
import 'package:droiddesk/screens/setup/setup_progress.dart';

/// Desktop Environment picker — the only choice before Essentials setup.
class DEPickerScreen extends StatelessWidget {
  const DEPickerScreen({super.key});

  static const _desktops = [
    _DEOption(
      id: 'xfce4',
      name: 'XFCE4',
      description:
          'Fast, customizable, low resource usage. The best all-rounder.',
      ram: '~300 MB RAM',
      icon: Icons.grid_view_rounded,
      color: DroidTheme.secondary,
      recommended: true,
    ),
    _DEOption(
      id: 'lxqt',
      name: 'LXQt',
      description: 'Ultra-lightweight Qt-based desktop. Fastest option.',
      ram: '~200 MB RAM',
      icon: Icons.widgets_rounded,
      color: Color(0xFF0A82F1),
      recommended: false,
    ),
    _DEOption(
      id: 'mate',
      name: 'MATE',
      description: 'Classic GNOME 2 fork. Familiar and comfortable.',
      ram: '~400 MB RAM',
      icon: Icons.view_comfy_rounded,
      color: Color(0xFF87A556),
      recommended: false,
    ),
    _DEOption(
      id: 'kde',
      name: 'KDE Plasma',
      description: 'Modern, feature-rich. Needs strong GPU and 4GB+ RAM.',
      ram: '~600 MB RAM',
      icon: Icons.auto_awesome_mosaic_rounded,
      color: Color(0xFF1D99F3),
      recommended: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: DroidTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Step indicator & Theme Toggle ──
                Row(
                  children: [
                    Expanded(child: _buildStepIndicator(1, 2)),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => state.toggleThemeMode(),
                      tooltip: state.isDarkMode
                          ? 'Switch to Light Theme'
                          : 'Switch to Dark Theme',
                      icon: Icon(
                        state.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: DroidTheme.textMuted,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text('Choose Desktop', style: DroidTheme.headingXl)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, duration: 400.ms),

                const SizedBox(height: 8),
                Text(
                  'Desktop Essentials installs the selected desktop, terminal, file manager, and core tools. More apps can be added later.',
                  style: DroidTheme.bodyMd,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                // ── Device info hint ──
                if (state.deviceInfo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DroidTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DroidTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 14,
                          color: DroidTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${state.deviceInfo['brand']} ${state.deviceInfo['model']} · '
                            '${state.deviceInfo['totalRamMB']} MB RAM · '
                            '${state.gpuType}',
                            style: DroidTheme.monoSm,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],

                const SizedBox(height: 24),

                // ── DE Cards ──
                Expanded(
                  child: ListView.separated(
                    itemCount: _desktops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final de = _desktops[index];
                      final selected = state.selectedDE == de.id;
                      return _buildDECard(de, selected, () {
                            state.setSelectedDE(de.id);
                          })
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 200 + index * 80),
                            duration: 400.ms,
                          )
                          .slideY(begin: 0.08, duration: 400.ms);
                    },
                  ),
                ),

                // ── Navigation ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SetupProgressScreen(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Install Essentials'),
                            SizedBox(width: 4),
                            Icon(Icons.download_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDECard(_DEOption de, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? DroidTheme.surfaceLight : DroidTheme.cardBg,
          borderRadius: BorderRadius.circular(DroidTheme.radiusMd),
          border: Border.all(
            color: selected
                ? de.color.withValues(alpha: 0.5)
                : DroidTheme.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: de.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(de.icon, color: de.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        de.name,
                        style: DroidTheme.headingSm.copyWith(fontSize: 15),
                      ),
                      if (de.recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DroidTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BEST',
                            style: DroidTheme.label.copyWith(
                              color: DroidTheme.accent,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(de.ram, style: DroidTheme.monoSm),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(de.description, style: DroidTheme.bodySm),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? de.color : Colors.transparent,
                border: Border.all(
                  color: selected ? de.color : DroidTheme.textDim,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < current;
        final isCurrent = i == current - 1;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isCurrent
                  ? DroidTheme.primary
                  : isActive
                  ? DroidTheme.primary.withValues(alpha: 0.5)
                  : DroidTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _DEOption {
  final String id;
  final String name;
  final String description;
  final String ram;
  final IconData icon;
  final Color color;
  final bool recommended;

  const _DEOption({
    required this.id,
    required this.name,
    required this.description,
    required this.ram,
    required this.icon,
    required this.color,
    required this.recommended,
  });
}
