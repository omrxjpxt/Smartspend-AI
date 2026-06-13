import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../design_system/components/premium_card.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'widgets/generate_statement_modal.dart';

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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.accentAI,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                Text('Account Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                
                PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                const SizedBox(height: 4),
                                if (_isEditingName)
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentAI)),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentAI)),
                                    ),
                                  )
                                else
                                  Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (!_isEditingName)
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.accentAI, size: 20),
                              onPressed: () => setState(() => _isEditingName = true),
                            ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 32),
                      
                      const Text('Email', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(profile.email, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      
                      const Divider(color: Colors.white12, height: 32),
                      
                      const Text('Account Created', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(dateFormatter.format(profile.createdAt), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                
                if (_isEditingName) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAI,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _isSaving ? null : () {
                      setState(() {
                        _isEditingName = false;
                        _nameController.text = profile.name;
                      });
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.xxl),
                Text('Financial Statements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: AppColors.accentAI),
                    title: const Text('Generate Statement', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Download your monthly financial report', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: () {
                      GenerateStatementModal.show(context);
                    },
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline, color: AppColors.accentAI),
                        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
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
                      const Divider(color: Colors.white12, height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppColors.negative),
                        title: const Text('Logout', style: TextStyle(color: AppColors.negative)),
                        onTap: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          // Router will auto-redirect to login via authState provider
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
