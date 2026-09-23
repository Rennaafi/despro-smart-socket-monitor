// lib/services/ai_seed.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedAiDocs() async {
  final firestore = FirebaseFirestore.instance;

  // Model 1 - Daily energy prediction
  await firestore.collection('ai').doc('daily_energy').set({
    'model_type': 'linear_regression_daily_energy',
    'predicted_today_kwh': 3.4,
    'predicted_tomorrow_kwh': 3.7,
    'model_version': 1,
    'updated_at': FieldValue.serverTimestamp(),
  });

  // Model 2 - Overview / insights
  await firestore.collection('ai').doc('overview').set({
    'weekly_top_sockets': ['socket1', 'socket2', 'socket3'],
    'night_ratios': {
      'socket1': 0.17,
      'socket2': 0.07,
      'socket3': 0.12,
    },
    'weekly_saving_estimates': {
      'socket1': 0.08,
      'socket2': 0.03,
      'socket3': 0.05,
    },
    'abnormal_usage': {
      'socket1': false,
      'socket2': true,
      'socket3': false,
    },
    'updated_at': FieldValue.serverTimestamp(),
  });
}
