import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal.dart';
import 'auth_repository.dart';

final goalsRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return GoalsRepository(uid);
});

class GoalsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  GoalsRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _firestore.collection('users').doc(userId).collection('goals');

  Stream<List<Goal>> watchGoals() {
    return _goalsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Goal(
          id: doc.id,
          title: data['title'] ?? '',
          emoji: data['emoji'] ?? '🎯',
          currentAmount: (data['currentAmount'] ?? 0).toDouble(),
          targetAmount: (data['targetAmount'] ?? 0).toDouble(),
          monthlyContribution: (data['monthlyContribution'] ?? 0).toDouble(),
          estimatedCompletion: (data['estimatedCompletion'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> createGoal(Goal goal) async {
    await _goalsRef.add({
      'title': goal.title,
      'emoji': goal.emoji,
      'currentAmount': goal.currentAmount,
      'targetAmount': goal.targetAmount,
      'monthlyContribution': goal.monthlyContribution,
      'estimatedCompletion': Timestamp.fromDate(goal.estimatedCompletion),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalsRef.doc(goal.id).update({
      'title': goal.title,
      'emoji': goal.emoji,
      'currentAmount': goal.currentAmount,
      'targetAmount': goal.targetAmount,
      'monthlyContribution': goal.monthlyContribution,
      'estimatedCompletion': Timestamp.fromDate(goal.estimatedCompletion),
    });
  }

  Future<void> deleteGoal(String id) async {
    await _goalsRef.doc(id).delete();
  }
}
