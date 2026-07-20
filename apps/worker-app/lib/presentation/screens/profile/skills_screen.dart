import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/worker_model.dart';
import '../../../domain/repositories/worker_repository.dart';
import '../../../injection_container.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final WorkerRepository _repository = sl<WorkerRepository>();
  bool _isLoading = true;
  bool _isSaving = false;

  // All possible service categories with their icons
  static const List<_CategoryDef> _allCategories = [
    _CategoryDef('PLUMBING', Icons.plumbing),
    _CategoryDef('ELECTRICAL', Icons.electrical_services),
    _CategoryDef('CLEANING', Icons.cleaning_services),
    _CategoryDef('AC_REPAIR', Icons.ac_unit),
    _CategoryDef('CARPENTER', Icons.carpenter),
    _CategoryDef('PAINTING', Icons.format_paint),
    _CategoryDef('MECHANIC', Icons.build),
    _CategoryDef('GENERAL_HANDYMAN', Icons.handyman),
  ];

  // Editable skill list
  final List<_SkillData> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      // Try AuthBloc first
      final authState = context.read<AuthBloc>().state;
      List<SkillModel> existingSkills = [];
      if (authState is Authenticated) {
        existingSkills = authState.worker.skills;
      } else {
        final worker = await _repository.getProfile();
        existingSkills = worker.skills;
      }

      // Build full list: existing skills enabled, rest disabled
      final existingMap = {for (var s in existingSkills) s.category: s};

      _skills.clear();
      for (final cat in _allCategories) {
        final existing = existingMap[cat.category];
        _skills.add(
          _SkillData(
            category: cat.category,
            icon: cat.icon,
            experience: existing?.experience ?? 0,
            hourlyRate: existing?.hourlyRate ?? 400,
            isVerified: existing?.isVerified ?? false,
            isEnabled: existing != null,
          ),
        );
      }
    } catch (e) {
      // Build default list
      _skills.clear();
      for (final cat in _allCategories) {
        _skills.add(
          _SkillData(
            category: cat.category,
            icon: cat.icon,
            experience: 0,
            hourlyRate: 400,
            isVerified: false,
            isEnabled: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSkills() async {
    setState(() => _isSaving = true);

    try {
      final enabledSkills = _skills
          .where((s) => s.isEnabled)
          .map(
            (s) => SkillModel(
              category: s.category,
              experience: s.experience,
              hourlyRate: s.hourlyRate,
              isVerified: s.isVerified,
            ),
          )
          .toList();

      await _repository.updateProfile(skills: enabledSkills);

      if (mounted) {
        // Refresh AuthBloc so profile screen shows updated skills
        context.read<AuthBloc>().add(RefreshProfile());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skills saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save skills: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Skills'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSkills,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _skills.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final skill = _skills[index];
                return _buildSkillCard(skill, index);
              },
            ),
    );
  }

  Widget _buildSkillCard(_SkillData skill, int index) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(
          color: skill.isEnabled ? AppColors.primary : AppColors.border,
          width: skill.isEnabled ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (skill.isEnabled
                              ? AppColors.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Icon(
                  skill.icon,
                  color: skill.isEnabled
                      ? AppColors.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          skill.category.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (skill.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    if (skill.isEnabled)
                      Text(
                        '${skill.experience} years exp \u2022 Rs. ${skill.hourlyRate.toStringAsFixed(0)}/hr',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: skill.isEnabled,
                onChanged: (value) {
                  setState(() {
                    _skills[index] = skill.copyWith(isEnabled: value);
                  });
                  if (value) {
                    _showEditSkillDialog(skill, index);
                  }
                },
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (skill.isEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditSkillDialog(skill, index),
                    child: const Text('Edit Details'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showEditSkillDialog(_SkillData skill, int index) {
    final experienceController = TextEditingController(
      text: skill.experience.toString(),
    );
    final hourlyRateController = TextEditingController(
      text: skill.hourlyRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(skill.category.replaceAll('_', ' ')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: experienceController,
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate (Rs.)',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final experience = int.tryParse(experienceController.text) ?? 0;
              final hourlyRate =
                  double.tryParse(hourlyRateController.text) ?? 0;

              final expError = Validators.validateExperience(
                experienceController.text,
              );
              final rateError = Validators.validateHourlyRate(
                hourlyRateController.text,
              );

              if (expError != null) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(expError)));
                return;
              }
              if (rateError != null) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(rateError)));
                return;
              }

              setState(() {
                _skills[index] = skill.copyWith(
                  experience: experience,
                  hourlyRate: hourlyRate,
                  isEnabled: true,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CategoryDef {
  final String category;
  final IconData icon;
  const _CategoryDef(this.category, this.icon);
}

class _SkillData {
  final String category;
  final IconData icon;
  final int experience;
  final double hourlyRate;
  final bool isVerified;
  final bool isEnabled;

  _SkillData({
    required this.category,
    required this.icon,
    required this.experience,
    required this.hourlyRate,
    required this.isVerified,
    required this.isEnabled,
  });

  _SkillData copyWith({
    String? category,
    IconData? icon,
    int? experience,
    double? hourlyRate,
    bool? isVerified,
    bool? isEnabled,
  }) {
    return _SkillData(
      category: category ?? this.category,
      icon: icon ?? this.icon,
      experience: experience ?? this.experience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isVerified: isVerified ?? this.isVerified,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
