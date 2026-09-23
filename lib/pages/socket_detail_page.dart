import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/common_states.dart';
import '../utils/value_utils.dart';

class SocketDetailPage extends StatefulWidget {
  final String socketName;
  final String deviceName;
  final IconData icon;
  final Color color;
  final String heroTag;

  const SocketDetailPage({
    super.key,
    required this.socketName,
    required this.deviceName,
    required this.icon,
    required this.color,
    required this.heroTag,
  });

  @override
  State<SocketDetailPage> createState() => _SocketDetailPageState();
}

class _SocketDetailPageState extends State<SocketDetailPage> {
  String _docId() {
    return widget.socketName.toLowerCase().replaceAll(" ", "");
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("sockets")
          .doc(_docId())
          .snapshots(),
      builder: (context, snapshot) {
        // ---------- STATE HANDLING MAIN DOC ----------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: SimpleLoading()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SimpleError('Failed to load socket detail.'),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SimpleEmpty('Socket document not found.'),
            ),
          );
        }

        // ---------- DATA SIAP DIPAKAI ----------
        final data = snapshot.data!.data() ?? {};

        final power = toDoubleSafe(data['powerW']); // W
        final voltage = toDoubleSafe(data['voltage']); // V
        final currentA = toDoubleSafe(data['currentA']); // A
        final energyToday = toDoubleSafe(data['energyTodayKWh']); // kWh
        final isOn = (data['isOn'] as bool?) ?? false;
        final priority = toIntSafe(data['priority'], 1).clamp(1, 4);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(widget.socketName),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.color.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: widget.heroTag,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.deviceName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Real-time monitoring',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // LIVE VALUES
                  Text(
                    'Live values',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _LiveTile(
                          label: 'Power',
                          value: '${power.toStringAsFixed(0)} W',
                          icon: Icons.flash_on,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LiveTile(
                          label: 'Voltage',
                          value: '${voltage.toStringAsFixed(0)} V',
                          icon: Icons.bolt_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _LiveTile(
                          label: 'Current',
                          value: '${currentA.toStringAsFixed(2)} A',
                          icon: Icons.speed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LiveTile(
                          label: 'Today',
                          value: '${energyToday.toStringAsFixed(2)} kWh',
                          icon: Icons.energy_savings_leaf,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // PRIORITY SLIDER
                  Text(
                    'Priority',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust how important this socket is',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: widget.color,
                            thumbColor: widget.color,
                            inactiveTrackColor: widget.color.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: priority.toDouble(),
                            min: 1,
                            max: 4,
                            divisions: 3,
                            label: 'Priority: $priority',
                            onChanged: (val) {
                              FirebaseFirestore.instance
                                  .collection('sockets')
                                  .doc(_docId())
                                  .update({'priority': val.toInt()});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // POWER SWITCH
                  Text(
                    'Power switch',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Socket status',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Switch(
                          value: isOn,
                          activeColor: Colors.white,
                          activeTrackColor: widget.color,
                          onChanged: (val) {
                            FirebaseFirestore.instance
                                .collection('sockets')
                                .doc(_docId())
                                .update({'isOn': val});
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // -----------------------------------------------------
                  // 🤖 AI INSIGHTS (from ai/overview)
                  // -----------------------------------------------------
                  Text(
                    'AI insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('ai')
                        .doc('overview')
                        .snapshots(),
                    builder: (context, aiSnap) {
                      if (aiSnap.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Loading AI insights...',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }

                      if (aiSnap.hasError) {
                        return const SimpleError(
                            'Failed to load AI overview.');
                      }

                      if (!aiSnap.hasData || !aiSnap.data!.exists) {
                        return const SimpleEmpty(
                            'AI overview data not available yet.');
                      }

                      final overview = aiSnap.data!.data() ?? {};
                      final socketId = _docId();

                      final nightRatios =
                          (overview['night_ratios'] as Map<String, dynamic>?) ??
                              {};
                      final savingEst =
                          (overview['weekly_saving_estimates']
                          as Map<String, dynamic>?) ??
                              {};
                      final abnormal =
                          (overview['abnormal_usage']
                          as Map<String, dynamic>?) ??
                              {};
                      final rankingList =
                          (overview['weekly_top_sockets'] as List<dynamic>?) ??
                              [];

                      final nightRatio =
                      toDoubleSafe(nightRatios[socketId]).clamp(0, 1);
                      final saving = toDoubleSafe(savingEst[socketId]);
                      final isAbnormal =
                          (abnormal[socketId] as bool?) ?? false;

                      final rankIndex = rankingList.indexOf(socketId);
                      String rankText;
                      if (rankIndex == -1 || rankingList.isEmpty) {
                        rankText = 'Not in top usage this week.';
                      } else {
                        rankText =
                        'Rank #${rankIndex + 1} of ${rankingList.length} sockets by energy usage.';
                      }

                      final nightPercent = (nightRatio * 100);
                      final savingPercent = (saving * 100);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.insights_outlined,
                              color: scheme.secondary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart suggestions for this socket',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rankText,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    nightRatio > 0
                                        ? 'Around ${nightPercent.toStringAsFixed(1)}% of this socket’s energy is used at night.'
                                        : 'Night-time usage is minimal for this socket.',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    saving > 0
                                        ? 'Reducing night usage could save about ${savingPercent.toStringAsFixed(1)}% of its weekly energy.'
                                        : 'No significant saving potential detected yet.',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAbnormal
                                        ? 'Today’s usage looks higher than usual. Consider checking what’s plugged in.'
                                        : 'Today’s usage is within normal range.',
                                    style: TextStyle(
                                      color: isAbnormal
                                          ? scheme.error
                                          : Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // TODAY'S TREND + CHART (Firestore logs)
                  Text(
                    'Today’s trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child:
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('sockets')
                          .doc(_docId())
                          .collection('logs')
                          .orderBy('timestamp')
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SimpleLoading();
                        }

                        if (snapshot.hasError) {
                          return SimpleError(
                            'Failed to load log data.\n${snapshot.error}',
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const SimpleEmpty('No log data yet.');
                        }

                        final points = snapshot.data!.docs.map((doc) {
                          final d = doc.data();
                          final ts = d['timestamp'] as Timestamp?;
                          final p = toDoubleSafe(d['powerW']);
                          return PowerPoint(
                            time: ts?.toDate() ?? DateTime.now(),
                            power: p,
                          );
                        }).toList();

                        return _PowerTrendChart(
                          points: points,
                          color: widget.color,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// LIVE METRIC TILE
class _LiveTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _LiveTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

/// DATA MODEL FOR CHART
class PowerPoint {
  final DateTime time;
  final double power;

  PowerPoint({required this.time, required this.power});
}

/// UPGRADED LINE + AREA CHART
class _PowerTrendChart extends StatelessWidget {
  final List<PowerPoint> points;
  final Color color;

  const _PowerTrendChart({
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Center(
        child: Text(
          'Not enough data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // hitung min, max, latest buat label
    double minPower = points.first.power;
    double maxPower = points.first.power;
    for (final p in points) {
      if (p.power < minPower) minPower = p.power;
      if (p.power > maxPower) maxPower = p.power;
    }
    final latest = points.last.power;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            CustomPaint(
              painter: _PowerChartPainter(
                points: points,
                color: color,
              ),
              child: const SizedBox.expand(),
            ),
            // latest value (top-right)
            Positioned(
              right: 4,
              top: 0,
              child: Text(
                '${latest.toStringAsFixed(0)} W',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            // max (top-left)
            Positioned(
              left: 4,
              top: 0,
              child: Text(
                'max ${maxPower.toStringAsFixed(0)} W',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
            // min (bottom-left)
            Positioned(
              left: 4,
              bottom: 0,
              child: Text(
                'min ${minPower.toStringAsFixed(0)} W',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PowerChartPainter extends CustomPainter {
  final List<PowerPoint> points;
  final Color color;

  _PowerChartPainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minTime =
    points.first.time.millisecondsSinceEpoch.toDouble();
    final maxTime =
    points.last.time.millisecondsSinceEpoch.toDouble();

    double minPower = points.first.power;
    double maxPower = points.first.power;

    for (final p in points) {
      if (p.power < minPower) minPower = p.power;
      if (p.power > maxPower) maxPower = p.power;
    }

    if (maxPower == minPower) {
      maxPower += 1; // biar nggak divide by zero
    }
    if (maxTime == minTime) {
      return; // waktu semua sama, skip gambar
    }

    const padding = 8.0;
    final width = size.width - 2 * padding;
    final height = size.height - 2 * padding;

    // ---------------- GRID LINES ----------------
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // vertical (5 kolom)
    for (int i = 0; i <= 4; i++) {
      final x = padding + (width / 4) * i;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + height),
        gridPaint,
      );
    }

    // horizontal (4 baris)
    for (int i = 0; i <= 3; i++) {
      final y = padding + (height / 3) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + width, y),
        gridPaint,
      );
    }

    // baseline bawah
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padding, padding + height),
      Offset(padding + width, padding + height),
      basePaint,
    );

    // ---------------- HITUNG TITIK ----------------
    final offsets = <Offset>[];
    for (final p in points) {
      final t = p.time.millisecondsSinceEpoch.toDouble();
      final pw = p.power;

      final normX = (t - minTime) / (maxTime - minTime);
      final normY = (pw - minPower) / (maxPower - minPower);

      final dx = padding + normX * width;
      final dy = padding + height * (1 - normY);

      offsets.add(Offset(dx, dy));
    }

    if (offsets.length < 2) return;

    // ---------------- PATH LINE ----------------
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }

    // glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // garis utama
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // ---------------- AREA FILL ----------------
    final first = offsets.first;
    final last = offsets.last;

    final fillPath = Path.from(path)
      ..lineTo(last.dx, padding + height)
      ..lineTo(first.dx, padding + height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.02),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_PowerChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
