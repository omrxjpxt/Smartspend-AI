import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import 'auth_repository.dart';

final userProfileRepositoryProvider = Provider((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return UserProfileRepository(user?.uid ?? 'anonymous', user?.email ?? '');
});

class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String userEmail;
  
  UserProfileRepository(this.userId, this.userEmail);

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _firestore.collection('users').doc(userId);

  Stream<UserProfile?> watchProfile() {
    return _profileRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Create default profile if missing to prevent resets
        final defaultData = {
          'name': 'User',
          'email': userEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
        };
        _profileRef.set(defaultData, SetOptions(merge: true));
        return UserProfile(
          id: userId,
          name: 'User',
          monthlyIncome: 0,
          monthlySavingsTarget: 0,
          riskProfile: 'Moderate',
          investmentExperience: 'Beginner',
          onboardingCompleted: false,
          email: userEmail,
          createdAt: DateTime.now(),
        );
      }
      final data = snapshot.data()!;

      bool isCompleted = data['onboardingCompleted'] ?? false;
      
      // Migration logic: If any onboarding data exists but flag is false, mark it as completed.
      if (!isCompleted && (data.containsKey('monthlyIncome') || data.containsKey('riskProfile') || data.containsKey('investmentExperience'))) {
        isCompleted = true;
      }

      return UserProfile(
        id: snapshot.id,
        name: data['name'] ?? 'User',
        monthlyIncome: (data['monthlyIncome'] ?? 0).toDouble(),
        monthlySavingsTarget: (data['monthlySavingsTarget'] ?? data['savingsGoal'] ?? 0).toDouble(), // fallback to savingsGoal for old data
        riskProfile: data['riskProfile'] ?? 'Moderate',
        investmentExperience: data['investmentExperience'] ?? 'Beginner',
        onboardingCompleted: isCompleted,
        email: data['email'] ?? userEmail,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  Future<UserProfile?> getProfile() async {
    final snapshot = await _profileRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      final defaultData = {
        'name': 'User',
        'email': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
      };
      await _profileRef.set(defaultData, SetOptions(merge: true));
      return UserProfile(
        id: userId,
        name: 'User',
        monthlyIncome: 0,
        monthlySavingsTarget: 0,
        riskProfile: 'Moderate',
        investmentExperience: 'Beginner',
        onboardingCompleted: false,
        email: userEmail,
        createdAt: DateTime.now(),
      );
    }
    final data = snapshot.data()!;

    bool isCompleted = data['onboardingCompleted'] ?? false;
    
    // Migration logic
    if (!isCompleted && (data.containsKey('monthlyIncome') || data.containsKey('riskProfile') || data.containsKey('investmentExperience'))) {
      isCompleted = true;
    }

    return UserProfile(
      id: snapshot.id,
      name: data['name'] ?? 'User',
      monthlyIncome: (data['monthlyIncome'] ?? 0).toDouble(),
      monthlySavingsTarget: (data['monthlySavingsTarget'] ?? data['savingsGoal'] ?? 0).toDouble(),
      riskProfile: data['riskProfile'] ?? 'Moderate',
      investmentExperience: data['investmentExperience'] ?? 'Beginner',
      onboardingCompleted: isCompleted,
      email: data['email'] ?? userEmail,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _profileRef.set(data, SetOptions(merge: true));
  }
}
