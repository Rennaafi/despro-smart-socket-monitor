import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/common_states.dart';
import '../utils/value_utils.dart';

import 'socket_detail_page.dart';

class SocketPage extends StatelessWidget {
  const SocketPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _socketsStream() {
    return FirebaseFirestore.instance
        .collection('sockets')
        .orderBy('priority')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _socketsStream(),
          builder: (context, snapshot) {
            // ---------- STATE HANDLING ----------
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SimpleLoading();
            }

            if (snapshot.hasError) {
              return SimpleError(
                'Failed to load sockets.\n${snapshot.error}',
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SimpleEmpty('No sockets yet.');
            }

            // ---------- DATA READY ----------
            final docs = snapshot.data!.docs;
            final totalSockets = docs.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Sockets',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your $totalSockets smart sockets',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final socketName =
                      toStringSafe(data['name'], 'Socket ${index + 1}');
                      final deviceName =
                      toStringSafe(data['deviceLabel'], 'Custom Load');

                      final powerVal = toDoubleSafe(data['powerW']);
                      final energyVal =
                      toDoubleSafe(data['energyTodayKWh']);

                      final power = '${powerVal.toStringAsFixed(0)} W';
                      final energyToday =
                          '${energyVal.toStringAsFixed(2)} kWh';

                      final priority = toIntSafe(data['priority'], 1);
                      final isOn = (data['isOn'] as bool? ?? false);
                      final status = isOn ? 'On' : 'Off';

                      // warna hex, default #38BDF8
                      final hexString =
                      toStringSafe(data['color'], '#38BDF8');
                      Color color;
                      try {
                        final hex =
                        hexString.replaceAll('#', '').padLeft(6, '0');
                        final intVal = int.parse(hex, radix: 16);
                        color = Color(0xFF000000 | intVal);
                      } catch (_) {
                        color = const Color(0xFF38BDF8);
                      }

                      final icon = _iconForDevice(deviceName);

                      return _SocketListItem(
                        socketName: socketName,
                        deviceName: deviceName,
                        power: power,
                        energyToday: energyToday,
                        priority: priority,
                        status: status,
                        color: color,
                        icon: icon,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// 🔹 Socket List Item + Hero + Tap Scale
/// ─────────────────────────────────────────
class _SocketListItem extends StatefulWidget {
  final String socketName;
  final String deviceName;
  final String power;
  final String energyToday;
  final int priority;
  final String status;
  final Color color;
  final IconData icon;

  const _SocketListItem({
    required this.socketName,
    required this.deviceName,
    required this.power,
    required this.energyToday,
    required this.priority,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  State<_SocketListItem> createState() => _SocketListItemState();
}

class _SocketListItemState extends State<_SocketListItem> {
  bool _pressed = false;

  void _goToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocketDetailPage(
          socketName: widget.socketName,
          deviceName: widget.deviceName,
          icon: widget.icon,
          color: widget.color,
          heroTag: widget.socketName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOn = widget.status.toLowerCase() == 'on';
    final heroTag = widget.socketName;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          _goToDetail(context);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOn ? widget.color : const Color(0xFF262626),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ICON with Hero
              Hero(
                tag: heroTag,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
              ),

              const SizedBox(width: 12),

              // TEXT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.socketName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      widget.deviceName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.power} · ${widget.energyToday} today',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // STATUS + PRIORITY
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOn
                          ? const Color(0xFF022C22)
                          : const Color(0xFF1F2933),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        isOn ? const Color(0xFF6EE7B7) : Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.priority}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper: pilih icon sesuai nama device/load
IconData _iconForDevice(String deviceName) {
  final n = deviceName.toLowerCase();

  if (n.contains('fridge') || n.contains('kulkas')) {
    return Icons.kitchen;
  } else if (n.contains('laptop') || n.contains('charger')) {
    return Icons.laptop_mac;
  } else if (n.contains('fan') || n.contains('angin')) {
    return Icons.toys; // ikon kipas
  } else if (n.contains('lamp') ||
      n.contains('light') ||
      n.contains('bulb')) {
    return Icons.lightbulb_outline;
  } else if (n.contains('ac') || n.contains('air conditioner')) {
    return Icons.ac_unit;
  } else if (n.contains('tv')) {
    return Icons.tv;
  }

  // default
  return Icons.power_outlined;
}
