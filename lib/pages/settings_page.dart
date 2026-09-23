import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tune how Despro looks and behaves.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 20),

            // PROFILE CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF38BDF8),
                          Color(0xFFA855F7),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refan',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Despro owner · 4 sockets',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      color: Colors.grey[400], size: 20),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            const _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Dark · Neon blue accent',
            ),
            const SizedBox(height: 8),
            const _SettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'English',
            ),
            const SizedBox(height: 8),
            const _SettingsTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              subtitle: 'Alerts for faults, peak usage & AI tips',
              hasSwitch: true,
              switchValue: true,
            ),

            const SizedBox(height: 24),

            Text(
              'System & devices',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            const _SettingsTile(
              icon: Icons.power_outlined,
              title: 'Socket naming',
              subtitle: 'Rename Socket 1–4 to real devices',
            ),
            const SizedBox(height: 8),
            const _SettingsTile(
              icon: Icons.sensors_outlined,
              title: 'Calibration',
              subtitle: 'Voltage & power offset for each PZEM',
            ),
            const SizedBox(height: 8),
            const _SettingsTile(
              icon: Icons.wifi_tethering_outlined,
              title: 'Network & device link',
              subtitle: 'WiFi, MCU, and Despro ID',
            ),

            const SizedBox(height: 24),

            Text(
              'About Despro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt,
                          color: colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Project Despro · v0.1',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Smart 4-socket kWh monitoring, AI prediction, and safety automation.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        'Made for exhibition & learning. Data shown is dummy.',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                '© 2025 Despro Team',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────── small widgets ─────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool hasSwitch;
  final bool switchValue;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hasSwitch = false,
    this.switchValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (hasSwitch)
            Switch(
              value: switchValue,
              onChanged: (val) {
                // TODO: implement later
              },
            ),
        ],
      ),
    );
  }
}
