import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// path relatif dari /pages ke /utils
import '../utils/common_states.dart';
import '../utils/value_utils.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
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
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔥 analytics/daily
  Stream<DocumentSnapshot<Map<String, dynamic>>> _dailyStream() {
    return FirebaseFirestore.instance
        .collection('analytics')
        .doc('daily')
        .snapshots();
  }

  // 🔥 ai/overview (Model 2)
  Stream<DocumentSnapshot<Map<String, dynamic>>> _aiOverviewStream() {
    return FirebaseFirestore.instance
        .collection('ai')
        .doc('overview')
        .snapshots();
  }

  String _formatUpdatedAt(dynamic v) {
    if (v is Timestamp) {
      final dt = v.toDate().toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '-';
  }

  String _prettySocketName(String id) {
    // "socket1" -> "Socket 1"
    if (id.toLowerCase().startsWith('socket')) {
      final tail = id.toLowerCase().replaceFirst('socket', '');
      return 'Socket ${tail.isEmpty ? '?' : tail}';
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _dailyStream(),
            builder: (context, snapshot) {
              // ---------- STATE HANDLING PAKAI WIDGET BARU ----------

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SimpleLoading();
              }

              if (snapshot.hasError) {
                return SimpleError(
                  'Failed to load analytics.\n${snapshot.error}',
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SimpleEmpty(
                  'No analytics data yet.\nAdd a document at analytics/daily.',
                );
              }

              // ---------- DATA SIAP DIPAKAI ----------

              final data = snapshot.data!.data() ?? {};

              final energyTodayKWh =
              toDoubleSafe(data['energyTodayKWh']); // 3.24
              final costToday = toDoubleSafe(data['costToday']); // 5420
              final predictedKWh =
              toDoubleSafe(data['predictedKWh']); // 3.6
              final efficiencyScore =
              toDoubleSafe(data['efficiencyScore']); // 82
              final peakPowerW = toIntSafe(data['peakPowerW']); // 487
              final updatedAtStr = _formatUpdatedAt(data['updatedAt']);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Text(
                      'Analytics & Insights',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See how your energy behaves over time',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TODAY SUMMARY CARD (Firestore)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s usage',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              AnimatedCount(
                                value: energyTodayKWh,
                                fractionDigits: 2,
                                suffix: ' kWh',
                                duration:
                                const Duration(milliseconds: 1800),
                                textStyle: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedCount(
                                value: costToday,
                                fractionDigits: 0,
                                prefix: '·  Rp ',
                                duration:
                                const Duration(milliseconds: 1700),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last updated at $updatedAtStr',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // THREE KPI CARDS (Firestore)
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            title: 'Predicted today',
                            value: predictedKWh,
                            suffix: ' kWh',
                            subtitle: 'Model-based forecast',
                            fractionDigits: 2,
                            duration:
                            const Duration(milliseconds: 1500),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            title: 'Peak power',
                            value: peakPowerW.toDouble(),
                            suffix: ' W',
                            subtitle: 'Max today',
                            duration:
                            const Duration(milliseconds: 1500),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiCard(
                            title: 'Efficiency score',
                            value: efficiencyScore,
                            suffix: ' / 100',
                            subtitle: 'Higher is better',
                            fractionDigits: 0,
                            duration:
                            const Duration(milliseconds: 1700),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // USAGE TREND (masih dummy, visual only)
                    Text(
                      'Usage trend (last 7 days)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: const [
                            _Bar(day: 'Mon', value: 0.4),
                            _Bar(day: 'Tue', value: 0.7),
                            _Bar(day: 'Wed', value: 0.6),
                            _Bar(day: 'Thu', value: 0.9),
                            _Bar(day: 'Fri', value: 0.5),
                            _Bar(day: 'Sat', value: 0.8),
                            _Bar(day: 'Sun', value: 0.3),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --------------------------------------------------
                    // 🤖 TOP SOCKETS THIS WEEK (AI: ai/overview)
                    // --------------------------------------------------
                    Text(
                      'Top sockets this week (AI)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _aiOverviewStream(),
                      builder: (context, aiSnap) {
                        if (aiSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const SimpleLoading();
                        }

                        if (aiSnap.hasError) {
                          return SimpleError(
                            'Failed to load AI overview.\n${aiSnap.error}',
                          );
                        }

                        if (!aiSnap.hasData || !aiSnap.data!.exists) {
                          return const SimpleEmpty(
                              'AI overview data not available yet.');
                        }

                        final overview = aiSnap.data!.data() ?? {};

                        final weeklyTop =
                        (overview['weekly_top_sockets']
                        as List<dynamic>? ??
                            [])
                            .map((e) => e.toString())
                            .toList();

                        final nightRatios =
                        (overview['night_ratios']
                        as Map<String, dynamic>? ??
                            {});
                        final savingEst =
                        (overview['weekly_saving_estimates']
                        as Map<String, dynamic>? ??
                            {});

                        if (weeklyTop.isEmpty) {
                          return const SimpleEmpty(
                              'No AI ranking yet for this week.');
                        }

                        // cari max ratio buat normalisasi bar 0..1
                        double maxNight = 0;
                        for (final id in weeklyTop) {
                          final r =
                          toDoubleSafe(nightRatios[id]) as double;
                          if (r > maxNight) maxNight = r;
                        }
                        if (maxNight == 0) maxNight = 1;

                        final colors = <Color>[
                          const Color(0xFF38BDF8),
                          const Color(0xFFA855F7),
                          const Color(0xFF22C55E),
                          const Color(0xFFF97316),
                        ];

                        final rows = <Widget>[];
                        for (int i = 0; i < weeklyTop.length; i++) {
                          final id = weeklyTop[i];
                          final prettyName = _prettySocketName(id);
                          final nightRatio =
                          toDoubleSafe(nightRatios[id]);
                          final percent = (nightRatio / maxNight)
                              .clamp(0.1, 1.0); // min 10% biar kelihatan
                          final color = colors[i % colors.length];

                          rows.add(_TopSocketRow(
                            name: prettyName,
                            percent: percent,
                            color: color,
                            detail:
                            'Night usage ~ ${(nightRatio * 100).toStringAsFixed(1)}%',
                          ));
                          rows.add(const SizedBox(height: 8));
                        }

                        // build tip dari socket teratas
                        final topId = weeklyTop.first;
                        final topName = _prettySocketName(topId);
                        final saving = toDoubleSafe(savingEst[topId]);
                        final savingPercent = (saving * 100);

                        String tipText;
                        if (saving > 0) {
                          tipText =
                          'AI: Reducing $topName at night could save about ${savingPercent.toStringAsFixed(1)}% of its weekly energy.';
                        } else {
                          tipText =
                          'AI: This week, $topName is one of your most active sockets. Consider reducing its usage during off-hours.';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...rows,
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111827),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tipText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Animated number ----------

class AnimatedCount extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final str = animatedValue.toStringAsFixed(fractionDigits);
        return Text(
          '$prefix$str$suffix',
          style: textStyle ??
              Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}

// ---------- KPI Card ----------

class _KpiCard extends StatelessWidget {
  final String title;
  final double value;
  final String subtitle;
  final String suffix;
  final int fractionDigits;
  final Duration duration;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    this.fractionDigits = 0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            suffix: suffix,
            fractionDigits: fractionDigits,
            duration: duration,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ---------- Bars (dummy trend) ----------

class _Bar extends StatelessWidget {
  final String day;
  final double value; // 0..1

  const _Bar({required this.day, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animated, child) {
                return Container(
                  width: 16,
                  height: 100 * animated,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF38BDF8),
                        Color(0xFF0EA5E9),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[400]),
        ),
      ],
    );
  }
}

// ---------- Top sockets (now AI-driven) ----------

class _TopSocketRow extends StatelessWidget {
  final String name;
  final double percent; // 0..1 for bar length
  final Color color;
  final String? detail;

  const _TopSocketRow({
    required this.name,
    required this.percent,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail!,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[500]),
          ),
        ],
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            FractionallySizedBox(
              widthFactor: clamped,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
