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
          currentAmount: 0.0, // Computed dynamically in the provider
          targetAmount: (data['targetAmount'] ?? 0).toDouble(),
        );
      }).toList();
    });
  }

  Future<void> createGoal(Goal goal) async {
    await _goalsRef.add({
      'title': goal.title,
      'emoji': goal.emoji,
      'targetAmount': goal.targetAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Creates a goal document and returns its auto-generated Firestore ID.
  /// Used when the caller needs to immediately post an initial contribution
  /// to the ledger with a referenceId pointing to the new goal.
  Future<String> createGoalAndGetId(Goal goal) async {
    final docRef = await _goalsRef.add({
      'title': goal.title,
      'emoji': goal.emoji,
      'targetAmount': goal.targetAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalsRef.doc(goal.id).update({
      'title': goal.title,
      'emoji': goal.emoji,
      'targetAmount': goal.targetAmount,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _goalsRef.doc(id).delete();
  }
}
