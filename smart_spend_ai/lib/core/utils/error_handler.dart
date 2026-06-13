import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

String getFriendlyErrorMessage(Object error) {
  final e = error.toString().toLowerCase();
  
  if (e.contains('failed-precondition') || e.contains('requires an index')) {
    return 'Data is being prepared. Please try again in a few moments.';
  } else if (e.contains('permission-denied')) {
    return 'You do not have permission to access this data.';
  } else if (e.contains('network-request-failed')) {
    return 'Network error. Please check your connection.';
  } else if (e.contains('not-found')) {
    return 'The requested data could not be found.';
  } else if (e.contains('firebase') || e.contains('firestore')) {
    return 'A service error occurred. Please try again.';
  }
  
  return 'An unexpected error occurred. Please try again.';
}

class AppErrorWidget extends StatelessWidget {
  final Object error;
  const AppErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.negative),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              getFriendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
