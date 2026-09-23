import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/common_states.dart';
import '../utils/value_utils.dart';

import '../ai_seed.dart'; // masih boleh ada kalau mau pakai tombol seed di header
import 'socket_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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

    _slide =
        Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fade);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔥 STREAM: analytics/daily
  Stream<DocumentSnapshot<Map<String, dynamic>>> _analyticsStream() {
    return FirebaseFirestore.instance
        .collection('analytics')
        .doc('daily')
        .snapshots();
  }

  // 🔥 STREAM: sockets/*
  Stream<QuerySnapshot<Map<String, dynamic>>> _socketsStream() {
    return FirebaseFirestore.instance
        .collection('sockets')
        .orderBy('priority')
        .snapshots();
  }

  // 🔥 STREAM: ai/daily_energy (AI prediction)
  Stream<DocumentSnapshot<Map<String, dynamic>>> _aiDailyStream() {
    return FirebaseFirestore.instance
        .collection('ai')
        .doc('daily_energy')
        .snapshots();
  }

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
                // -----------------------------------------------------
                // 👋 GREETING HEADER + SEED AI BUTTON
                // -----------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Refan 👋',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here’s your energy today',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),

                    // Despro pill + optional debug AI seed button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bolt,
                                  color: colorScheme.secondary, size: 18),
                              const SizedBox(width: 6),
                              Text('Despro',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          tooltip: 'Seed AI docs',
                          onPressed: () async {
                            try {
                              await seedAiDocs();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AI docs seeded!'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Seed failed: $e'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const FirestoreDebugText(),
                const SizedBox(height: 12),

                // -----------------------------------------------------
                // 🔥 TODAY SUMMARY CARD (analytics/daily)
                // -----------------------------------------------------
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _analyticsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _loadingCard();
                    }

                    if (snapshot.hasError) {
                      return _emptyCard(
                        message:
                        'Failed to load analytics.\n${snapshot.error}',
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _emptyCard(
                        message: 'No analytics data found',
                      );
                    }

                    final data = snapshot.data!.data() ?? {};

                    final efficiency =
                    toDoubleSafe(data['efficiencyScore']); // %
                    final energyKWh =
                    toDoubleSafe(data['energyTodayKWh']); // kWh
                    final costRp = toDoubleSafe(data['costToday']); // Rp
                    final predicted =
                    toDoubleSafe(data['predictedKWh']); // kWh (dari analytics)

                    return _summaryCard(
                      context,
                      efficiency: efficiency,
                      energyToday: energyKWh,
                      costToday: costRp,
                      predicted: predicted,
                    );
                  },
                ),
                const SizedBox(height: 16),
                // -----------------------------------------------------
                // 🔮 AI SUMMARY CARD (ai/daily_energy)
                // -----------------------------------------------------
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _aiDailyStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Biar nggak ganggu layout, pakai skeleton kecil
                      return _aiLoadingCard();
                    }

                    if (snapshot.hasError) {
                      return _aiEmptyCard(
                        message: 'Failed to load AI data.',
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _aiEmptyCard(
                        message: 'AI prediction not available yet.',
                      );
                    }

                    final data = snapshot.data!.data() ?? {};

                    final todayPred =
                    toDoubleSafe(data['predicted_today_kwh']); // kWh
                    final tomorrowPred =
                    toDoubleSafe(data['predicted_tomorrow_kwh']); // kWh

                    return _aiSummaryCard(
                      context,
                      todayPred: todayPred,
                      tomorrowPred: tomorrowPred,
                    );
                  },
                ),


                const SizedBox(height: 24),

                // -----------------------------------------------------
                // 🔥 SMALL STATS (Now / Peak)
                // -----------------------------------------------------
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _analyticsStream(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};

                    final nowPower =
                    toDoubleSafe(data['currentPowerW'], 214); // fallback
                    final peakPower =
                    toDoubleSafe(data['peakPowerW'], 487); // fallback
                    final peakTime =
                    toStringSafe(data['peakTime'], '--:--');

                    return Row(
                      children: [
                        Expanded(
                          child: _SmallStatCard(
                            title: 'Now',
                            value: nowPower,
                            suffix: ' W',
                            subtitle: 'Live power',
                            icon: Icons.flash_on,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallStatCard(
                            title: 'Peak today',
                            value: peakPower,
                            suffix: ' W',
                            subtitle: 'at $peakTime',
                            icon: Icons.trending_up,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // -----------------------------------------------------
                // SOCKETS SECTION TITLE
                // -----------------------------------------------------
                Text(
                  'Sockets',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                // -----------------------------------------------------
                // 🔌 SOCKET GRID (Realtime)
                // -----------------------------------------------------
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _socketsStream(),
                  builder: (context, snapshot) {
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

                    final docs = snapshot.data!.docs;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: docs.map((doc) {
                        final d = doc.data();

                        final name =
                        toStringSafe(d['name'], 'Socket'); // nama
                        final device =
                        toStringSafe(d['deviceLabel'], '-'); // label
                        final powerVal = toDoubleSafe(d['powerW']);
                        final power = '${powerVal.toStringAsFixed(0)} W';
                        final status =
                        (d['isOn'] as bool? ?? false) ? 'On' : 'Off';

                        // Warna: parse hex string "#38BDF8"
                        final hexString =
                        toStringSafe(d['color'], '#38BDF8');
                        Color parsedColor;
                        try {
                          final hex =
                          hexString.replaceAll('#', '').padLeft(6, '0');
                          final intVal = int.parse(hex, radix: 16);
                          parsedColor = Color(0xFF000000 | intVal);
                        } catch (_) {
                          parsedColor = const Color(0xFF38BDF8);
                        }

                        return _SocketCard(
                          name: name,
                          device: device,
                          power: power,
                          status: status,
                          color: parsedColor,
                          icon: Icons.power_outlined,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// ----------------------------------------------------
// 🔧 UI Widgets & Components
// ----------------------------------------------------

Widget _loadingCard() => Container(
  height: 120,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: Colors.black12,
  ),
  child: const Center(child: CircularProgressIndicator()),
);

Widget _emptyCard({String message = 'No analytics data found'}) => Container(
  padding: const EdgeInsets.all(20),
  child: Text(
    message,
    style: const TextStyle(color: Colors.grey),
  ),
);

//
// 🔮 AI SUMMARY CARD
//
Widget _aiLoadingCard() => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: const Color(0xFF101010),
  ),
  child: Row(
    children: [
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Loading AI prediction...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    ],
  ),
);

Widget _aiEmptyCard({String message = 'AI prediction not available yet.'}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF101010),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );

Widget _aiSummaryCard(
    BuildContext context, {
      required double todayPred,
      required double tomorrowPred,
    }) {
  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF111827),
          Color(0xFF020617),
        ],
      ),
      border: Border.all(
        color: colorScheme.secondary.withOpacity(0.4),
        width: 0.8,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF022C22),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: colorScheme.secondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI forecast',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on your recent usage, here\'s the estimated consumption:',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: "Today",
                      value: todayPred,
                      suffix: " kWh",
                      fractionDigits: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryChip(
                      label: "Tomorrow",
                      value: tomorrowPred,
                      suffix: " kWh",
                      fractionDigits: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

//
// 🔥 SUMMARY CARD
//
Widget _summaryCard(
    BuildContext context, {
      required double efficiency,
      required double energyToday,
      required double costToday,
      required double predicted,
    }) {
  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1F2933),
          Color(0xFF0B1120),
        ],
      ),
    ),
    child: Row(
      children: [
        // Big circle
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 3),
            gradient: const RadialGradient(
              colors: [
                Color(0xFF1E293B),
                Color(0xFF020617),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedCount(
                  value: efficiency,
                  suffix: '%',
                  fractionDigits: 0,
                  duration: const Duration(milliseconds: 2000),
                  textStyle: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text('Efficient', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Right side
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's summary",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              Row(
                children: [
                  _SummaryChip(
                    label: "Energy",
                    value: energyToday,
                    suffix: " kWh",
                    fractionDigits: 2,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: "Cost",
                    prefix: "Rp ",
                    value: costToday,
                    fractionDigits: 0,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'AI predicts ~ $predicted kWh by midnight.',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        )
      ],
    ),
  );
}

//
// 🔢 Animated Counter
//
class AnimatedCount extends StatelessWidget {
  final double value;
  final String prefix, suffix;
  final int fractionDigits;
  final Duration duration;
  final TextStyle? textStyle;

  const AnimatedCount({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
    this.duration = const Duration(milliseconds: 1700),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Text(
          '$prefix${animated.toStringAsFixed(fractionDigits)}$suffix',
          style: textStyle ??
              Theme.of(context).textTheme.titleMedium,
        );
      },
    );
  }
}

//
// 🔹 Summary Chip
//
class _SummaryChip extends StatelessWidget {
  final String label;
  final double value;
  final String prefix;
  final String suffix;
  final int fractionDigits;

  const _SummaryChip({
    required this.label,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          AnimatedCount(
            value: value,
            prefix: prefix,
            suffix: suffix,
            fractionDigits: fractionDigits,
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

//
// 🔹 Small Stat Card
//
class _SmallStatCard extends StatelessWidget {
  final String title;
  final double value;
  final String subtitle;
  final String suffix;
  final IconData icon;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[400])),
                AnimatedCount(
                  value: value,
                  suffix: suffix,
                  fractionDigits: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// 🔌 SOCKET CARD (Realtime Toggle)
//
class _SocketCard extends StatelessWidget {
  final String name;
  final String device;
  final String power;
  final String status;
  final IconData icon;
  final Color color;

  const _SocketCard({
    required this.name,
    required this.device,
    required this.power,
    required this.status,
    required this.icon,
    required this.color,
  });

  String _docIdFromName() {
    return name.toLowerCase().replaceAll(" ", "");
  }

  @override
  Widget build(BuildContext context) {
    final isOn = status.toLowerCase() == 'on';
    final heroTag = name;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SocketDetailPage(
              socketName: name,
              deviceName: device,
              icon: icon,
              color: color,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn ? color : const Color(0xFF272727),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon + toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: heroTag,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                ),

                // 🔥 Toggle button (Firestore update)
                GestureDetector(
                  onTap: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('sockets')
                          .doc(_docIdFromName())
                          .update({'isOn': !isOn});
                    } catch (e) {
                      debugPrint("Toggle error: $e");
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOn
                          ? const Color(0xFF022C22)
                          : const Color(0xFF1F2933),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOn ? "On" : "Off",
                      style: TextStyle(
                        fontSize: 11,
                        color: isOn
                            ? const Color(0xFF6EE7B7)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(name, style: TextStyle(color: Colors.grey[400])),
            Text(device,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),

            const Spacer(),

            Text(power,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text('live power',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

//
// 🔧 FIRESTORE DEBUG TEXT
//
class FirestoreDebugText extends StatelessWidget {
  const FirestoreDebugText({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
      FirebaseFirestore.instance.collection('test').doc('hello').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading from Firestore...',
              style: TextStyle(color: Colors.grey, fontSize: 12));
        }

        if (snapshot.hasError) {
          return Text('Firestore error: ${snapshot.error}',
              style:
              const TextStyle(color: Colors.redAccent, fontSize: 12));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Document test/hello not found.',
              style:
              TextStyle(color: Colors.redAccent, fontSize: 12));
        }

        final data = snapshot.data!.data()!;
        final msg = data['message'] ?? 'No message';

        return Text('Firestore says: $msg',
            style:
            const TextStyle(color: Colors.greenAccent, fontSize: 12));
      },
    );
  }
}
