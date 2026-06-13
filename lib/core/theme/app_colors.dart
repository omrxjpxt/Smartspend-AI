import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF000000); // Pitch black
  static const Color surface = Color(0xFF141414); // Deep dark gray for cards
  static const Color surfaceHighlight = Color(0xFF1F1F1F); // Slightly lighter for hovers/active states

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFA0A0A0); // Soft gray
  static const Color textTertiary = Color(0xFF6E6E6E); // Darker gray for subtle labels

  // Accents
  static const Color accentAI = Color(0xFF6B4CA6); // Deeper, less saturated violet
  static const Color positive = Color(0xFF34D399); // Mint green for gains/income
  static const Color negative = Color(0xFFF87171); // Soft red for losses/expenses
  static const Color warning = Color(0xFFFBBF24); // Amber
  static const Color primaryAction = Color(0xFFFFFFFF); // White for primary buttons

  // Borders & Dividers
  static const Color border = Color(0xFF262626);
  
  // Gradients
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF4B317A), Color(0xFF313063)], // Deep dark violet to deep indigo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
