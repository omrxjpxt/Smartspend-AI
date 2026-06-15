import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'widgets/generate_statement_modal.dart';
import 'widgets/reset_data_modals.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSaving = false;

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userProfileRepositoryProvider).updateProfile({'name': name});
      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final dateFormatter = DateFormat('MMMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
            }

            if (!_isEditingName) {
              _nameController.text = profile.name;
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                const SizedBox(height: AppSpacing.md),

                // ── Avatar + Name + Email ──
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.accentAI.withValues(alpha: 0.85),
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Account ──
                _sectionLabel('Account'),
                const SizedBox(height: 10),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      label: 'Name',
                      trailing: _isEditingName
                          ? Expanded(
                              child: TextField(
                                controller: _nameController,
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            )
                          : Text(profile.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      onTap: _isEditingName ? null : () => setState(() => _isEditingName = true),
                      showChevron: !_isEditingName,
                    ),
                    _SettingsRow(
                      label: 'Email',
                      trailing: Text(profile.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ),
                    _SettingsRow(
                      label: 'Member since',
                      trailing: Text(dateFormatter.format(profile.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      showDivider: false,
                    ),
                  ],
                ),

                if (_isEditingName) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _isEditingName = false;
                                    _nameController.text = profile.name;
                                  });
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentAI,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // ── General ──
                _sectionLabel('General'),
                const SizedBox(height: 10),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.accentAI,
                      label: 'Generate Statement',
                      onTap: () => GenerateStatementModal.show(context),
                    ),
                    _SettingsRow(
                      icon: Icons.lock_outline,
                      iconColor: AppColors.textSecondary,
                      label: 'Change Password',
                      showDivider: false,
                      onTap: () async {
                        try {
                          await ref.read(authRepositoryProvider).sendPasswordResetEmail(profile.email);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Logout ──
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      label: 'Log Out',
                      labelColor: AppColors.negative,
                      showChevron: false,
                      showDivider: false,
                      onTap: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ── Danger Zone ──
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.negative.withValues(alpha: 0.7),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => ResetDataFirstModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.negative.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.negative.withValues(alpha: 0.8), size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Reset All Data',
                          style: TextStyle(
                            color: AppColors.negative,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: AppColors.negative.withValues(alpha: 0.35), size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // ── Footer ──
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 24,
                        fit: BoxFit.contain,
                        opacity: const AlwaysStoppedAnimation(0.4),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'SmartSpend AI',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// iOS-style grouped settings container
// ─────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final List<_SettingsRow> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Single row inside a settings group
// ─────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final bool showChevron;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsRow({
    this.icon,
    this.iconColor,
    required this.label,
    this.labelColor,
    this.trailing,
    this.showChevron = true,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: labelColor ?? Colors.white,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
                if (showChevron && onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: icon != null ? 48.0 : 16.0),
            child: const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
          ),
        ],
    );
  }
}
