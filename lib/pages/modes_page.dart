import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModesPage extends StatefulWidget {
  const ModesPage({super.key});

  @override
  State<ModesPage> createState() => _ModesPageState();
}

class _ModesPageState extends State<ModesPage>
    with SingleTickerProviderStateMixin {
  // 0 = Normal, 1 = Energy Saving, 2 = Smart Priority, 3 = Custom Rules
  int _selectedModeIndex = 1;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();

    // load mode awal dari Firestore
    _loadInitialMode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------- FIRESTORE HELPERS ----------

  int _modeIndexFromId(String id) {
    switch (id) {
      case 'normal':
        return 0;
      case 'energy_saving':
        return 1;
      case 'smart_priority':
        return 2;
      case 'custom':
        return 3;
      default:
        return 1; // fallback: Energy Saving
    }
  }

  Future<void> _loadInitialMode() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('modes')
          .doc('current')
          .get();

      final data = doc.data();
      if (data == null) return;

      final activeModeId = data['activeMode'] as String?;
      if (activeModeId == null) return;

      final index = _modeIndexFromId(activeModeId);

      if (!mounted) return;
      setState(() {
        _selectedModeIndex = index;
      });
    } catch (e) {
      // optional: debug log
      // debugPrint('Failed to load initial mode: $e');
    }
  }

  Future<void> _setActiveMode(int index) async {
    // update UI dulu biar terasa responsif
    setState(() => _selectedModeIndex = index);

    // data yang akan dikirim ke Firestore
    late String id;
    late String label;
    late String description;
    late bool autoDutyCycle;
    late bool cutLowestPrioritySocket;
    late bool nightSavingEnabled;
    const int nightStartHour = 23;
    const int nightEndHour = 5;

    switch (index) {
      case 0: // Normal
        id = 'normal';
        label = 'Normal';
        description =
        'Despro only monitors. You control sockets manually.';
        autoDutyCycle = false;
        cutLowestPrioritySocket = false;
        nightSavingEnabled = false;
        break;

      case 1: // Energy Saving
        id = 'energy_saving';
        label = 'Energy Saving';
        description =
        'Automatically manages lowest priority sockets to reduce usage.';
        autoDutyCycle = true;
        cutLowestPrioritySocket = true;
        nightSavingEnabled = true;
        break;

      case 2: // Smart Priority
        id = 'smart_priority';
        label = 'Smart Priority';
        description =
        'Keeps high priority sockets on and cuts others during peak hours.';
        autoDutyCycle = true;
        cutLowestPrioritySocket = true;
        nightSavingEnabled = true;
        break;

      case 3: // Custom Rules
      default:
        id = 'custom';
        label = 'Custom Rules';
        description =
        'Despro follows your own rules for each socket and timeframe.';
        autoDutyCycle = false;
        cutLowestPrioritySocket = false;
        nightSavingEnabled = false;
        break;
    }

    try {
      // simpan mode aktif ke Firestore
      await FirebaseFirestore.instance
          .collection('modes')
          .doc('current')
          .set({
        'activeMode': id,
        'activeModeLabel': label,
        'description': description,
        'autoDutyCycle': autoDutyCycle,
        'cutLowestPrioritySocket': cutLowestPrioritySocket,
        'nightSavingEnabled': nightSavingEnabled,
        'nightStartHour': nightStartHour,
        'nightEndHour': nightEndHour,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // apply ke sockets/*
      await _applyModeToSockets(id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mode changed to $label'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update mode: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 🔥 Logic dummies-friendly:
  /// normal         → nggak ubah socket
  /// energy_saving  → priority >= 3 dimatiin
  /// smart_priority → priority 1 ON, priority >= 3 OFF
  /// custom         → nggak ubah socket (nanti bisa diisi rule sendiri)
  Future<void> _applyModeToSockets(String modeId) async {
    try {
      final socketsSnap =
      await FirebaseFirestore.instance.collection('sockets').get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in socketsSnap.docs) {
        final data = doc.data();
        final priority = (data['priority'] as int?) ?? 1;
        final ref = doc.reference;

        bool? newIsOn;

        switch (modeId) {
          case 'normal':
          // tidak mengubah isOn sama sekali
            break;

          case 'energy_saving':
          // matikan socket prioritas rendah (3 & 4)
            if (priority >= 3) {
              newIsOn = false;
            }
            break;

          case 'smart_priority':
          // priority 1 wajib ON, priority 3-4 OFF
            if (priority == 1) {
              newIsOn = true;
            } else if (priority >= 3) {
              newIsOn = false;
            }
            break;

          case 'custom':
          // TODO: nanti bisa pakai rules per socket
            break;
        }

        if (newIsOn != null) {
          batch.update(ref, {
            'isOn': newIsOn,
            'lastModeApplied': modeId,
          });
        } else {
          // tetap update lastModeApplied biar ESP32 tahu mode terakhir
          batch.update(ref, {
            'lastModeApplied': modeId,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      // debugPrint('Failed to apply mode to sockets: $e');
    }
  }

  // ---------- ACTIVE BANNER TEXT ----------

  String get _activeModeTitle {
    switch (_selectedModeIndex) {
      case 0:
        return 'Normal';
      case 1:
        return 'Energy Saving';
      case 2:
        return 'Smart Priority';
      case 3:
        return 'Custom Rules';
      default:
        return 'Energy Saving';
    }
  }

  String get _activeModeSubtitle {
    switch (_selectedModeIndex) {
      case 0:
        return 'Despro only monitors. No automatic cut-off or duty-cycle.';
      case 1:
        return 'Despro may turn off or duty-cycle lowest priority sockets.';
      case 2:
        return 'High priority sockets stay on, others are limited at peak hours.';
      case 3:
        return 'Despro follows your own rules for each socket and timeframe.';
      default:
        return 'Despro may turn off or duty-cycle lowest priority sockets.';
    }
  }

  IconData get _activeModeIcon {
    switch (_selectedModeIndex) {
      case 0:
        return Icons.toggle_off_outlined;
      case 1:
        return Icons.energy_savings_leaf;
      case 2:
        return Icons.star_rate_rounded;
      case 3:
        return Icons.tune;
      default:
        return Icons.energy_savings_leaf;
    }
  }

  // ---------- BUILD UI ----------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Modes & Automation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how Despro controls your sockets.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),

                const SizedBox(height: 20),

                // PREMIUM ACTIVE MODE BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF020617),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withOpacity(0.8),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // big circular icon (dynamic)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF38BDF8),
                              Color(0xFF0EA5E9),
                            ],
                          ),
                        ),
                        child: Icon(
                          _activeModeIcon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // text side
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.14),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: const Text(
                                    'ACTIVE MODE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                    const Color(0xFF16A34A).withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Live',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF4ADE80),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _activeModeTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activeModeSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[300]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'Available modes',
                  style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick how aggressive Despro should be when saving energy.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),

                const SizedBox(height: 16),

                _ModeCard(
                  modeName: 'Normal',
                  isSelected: _selectedModeIndex == 0,
                  description:
                  'Despro only monitors. You control sockets manually.',
                  icon: Icons.toggle_off_outlined,
                  pillText: 'Safe · Manual control',
                  onTap: () => _setActiveMode(0),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  modeName: 'Energy Saving',
                  isSelected: _selectedModeIndex == 1,
                  description:
                  'Automatically manages lowest priority sockets to reduce usage.',
                  icon: Icons.energy_savings_leaf,
                  pillText: 'Auto duty-cycle · Priority based',
                  onTap: () => _setActiveMode(1),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  modeName: 'Smart Priority',
                  isSelected: _selectedModeIndex == 2,
                  description:
                  'Keeps high priority sockets on, cuts others during peak hours.',
                  icon: Icons.star_rate_rounded,
                  pillText: 'Peak-time aware',
                  onTap: () => _setActiveMode(2),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  modeName: 'Custom Rules',
                  isSelected: _selectedModeIndex == 3,
                  description:
                  'Define rules per socket (schedule, max power, auto-off timer, etc.).',
                  icon: Icons.tune,
                  pillText: 'Tap to configure rules',
                  onTap: () => _setActiveMode(3),
                ),

                const SizedBox(height: 24),

                Text(
                  'Global safety & automation',
                  style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                const _AutomationTile(
                  title: 'Overcurrent protection',
                  subtitle:
                  'If power or current exceeds your threshold, Despro can cut the socket.',
                  initialValue: true,
                ),
                const SizedBox(height: 8),
                const _AutomationTile(
                  title: 'Abnormal pattern alert',
                  subtitle:
                  'Warn when usage pattern looks unusual compared to history.',
                  initialValue: true,
                ),
                const SizedBox(height: 8),
                const _AutomationTile(
                  title: 'Night-time saving window',
                  subtitle:
                  'Automatically turn off lowest priority socket between 23:00 - 05:00.',
                  initialValue: false,
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: colorScheme.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Later you can bind each mode and automation switch to Firestore fields and ESP32 logic.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[300]),
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
}

// ----------------- Mode card widget -----------------

class _ModeCard extends StatelessWidget {
  final String modeName;
  final bool isSelected;
  final String description;
  final IconData icon;
  final String pillText;
  final VoidCallback onTap;

  const _ModeCard({
    required this.modeName,
    required this.isSelected,
    required this.description,
    required this.icon,
    required this.pillText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    isSelected ? const Color(0xFF38BDF8) : const Color(0xFF262626);
    final bgColor =
    isSelected ? const Color(0xFF0B1120) : const Color(0xFF151515);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF38BDF8).withOpacity(0.18)
                      : const Color(0xFF1F2933),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          modeName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withOpacity(0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        pillText,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey[300]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Automation tiles -----------------

class _AutomationTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initialValue;

  const _AutomationTile({
    required this.title,
    required this.subtitle,
    required this.initialValue,
  });

  @override
  State<_AutomationTile> createState() => _AutomationTileState();
}

class _AutomationTileState extends State<_AutomationTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialValue;
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _enabled,
            onChanged: (val) {
              setState(() => _enabled = val);
            },
          ),
        ],
      ),
    );
  }
}
