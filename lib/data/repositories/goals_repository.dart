import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_contribution.dart';
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalsRef.doc(goal.id).update({
      'title': goal.title,
      'emoji': goal.emoji,
      'currentAmount': goal.currentAmount,
      'targetAmount': goal.targetAmount,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _goalsRef.doc(id).delete();
  }

  Stream<List<GoalContribution>> watchGoalContributions(String goalId) {
    return _goalsRef
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GoalContribution(
          id: doc.id,
          goalId: goalId,
          amount: (data['amount'] ?? 0).toDouble(),
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> addContribution({
    required String goalId,
    required double currentSavedAmount,
    required double contributionAmount,
  }) async {
    final batch = _firestore.batch();
    
    // 1. Add contribution record
    final contributionRef = _goalsRef.doc(goalId).collection('contributions').doc();
    batch.set(contributionRef, {
      'amount': contributionAmount,
      'date': FieldValue.serverTimestamp(),
    });

    // 2. Update parent goal's current amount
    final goalDocRef = _goalsRef.doc(goalId);
    batch.update(goalDocRef, {
      'currentAmount': currentSavedAmount + contributionAmount,
    });

    await batch.commit();
  }
}
