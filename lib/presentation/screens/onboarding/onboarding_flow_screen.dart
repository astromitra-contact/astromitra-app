import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/kundli_models.dart';
import '../../providers/kundli_provider.dart';
import '../../widgets/birth_place_autocomplete_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/star_field_background.dart';
import '../main_shell.dart';

/// A four-step wizard — name, birth date, birth time, birth place — each
/// on its own page with a progress dial up top, mirroring a classic
/// onboarding flow. The final step submits everything to
/// [KundliProvider.createKundli] in one call, exactly like the old
/// single-page form did.
///
/// Pass [initialDetails] to pre-populate all fields (edit mode).
class OnboardingFlowScreen extends StatefulWidget {
  final BirthDetails? initialDetails;

  const OnboardingFlowScreen({super.key, this.initialDetails});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();

  int _step = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _timeUnknown = false;
  bool _isSubmitting = false;
  String? _stepError;

  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDetails;
    if (d != null) {
      _nameController.text = d.name;
      _placeController.text = d.birthPlace;
      // Parse dateOfBirth "YYYY-MM-DD"
      final parts = d.dateOfBirth.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (y != null && m != null && day != null) {
          _selectedDate = DateTime(y, m, day);
        }
      }
      // Parse timeOfBirth "HH:MM"
      if (d.timeOfBirth != null && d.timeOfBirth!.isNotEmpty) {
        final tp = d.timeOfBirth!.split(':');
        if (tp.length == 2) {
          final h = int.tryParse(tp[0]);
          final min = int.tryParse(tp[1]);
          if (h != null && min != null) {
            _selectedTime = TimeOfDay(hour: h, minute: min);
          }
        }
      } else {
        _timeUnknown = true;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    if (_selectedDate == null) return '';
    final d = _selectedDate!;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _formattedTimeDisplay {
    if (_selectedTime == null) return '';
    return _selectedTime!.format(context);
  }

  String get _formattedTime24 {
    if (_selectedTime == null) return '';
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  void _goTo(int step) {
    setState(() => _stepError = null);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _handleNext() async {
    setState(() => _stepError = null);

    switch (_step) {
      case 0:
        final error = Validators.name(_nameController.text);
        if (error != null) {
          setState(() => _stepError = error);
          return;
        }
        _goTo(1);
        break;
      case 1:
        final error = Validators.dateOfBirth(_formattedDate.isEmpty ? null : _formattedDate);
        if (_selectedDate == null || error != null) {
          setState(() => _stepError = error ?? 'Please select your date of birth');
          return;
        }
        _goTo(2);
        break;
      case 2:
        if (!_timeUnknown && _selectedTime == null) {
          setState(() => _stepError = 'Select a time, or mark it as unknown below');
          return;
        }
        _goTo(3);
        break;
      case 3:
        final error = Validators.birthPlace(_placeController.text);
        if (error != null) {
          setState(() => _stepError = error);
          return;
        }
        await _submit();
        break;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _stepError = null;
    });

    try {
      final kundliProvider = context.read<KundliProvider>();
      final activeId = kundliProvider.activeKundliId;

      if (widget.initialDetails != null && activeId != null) {
        await kundliProvider.updateKundli(
          kundliId: activeId,
          name: _nameController.text.trim(),
          dateOfBirth: _formattedDate,
          timeOfBirth: _timeUnknown ? null : _formattedTime24,
          birthPlace: _placeController.text.trim(),
        );
      } else {
        await kundliProvider.createKundli(
          name: _nameController.text.trim(),
          dateOfBirth: _formattedDate,
          timeOfBirth: _timeUnknown ? null : _formattedTime24,
          birthPlace: _placeController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _stepError = e.message);
    } catch (e) {
      setState(() => _stepError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarFieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                step: _step,
                totalSteps: _totalSteps,
                onBack: _step == 0
                    ? null
                    : () => _goTo(_step - 1),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _StepPage(
                      icon: Icons.person_outline_rounded,
                      title: 'Enter Full Name',
                      subtitle: 'What should we call you?',
                      field: _NameField(controller: _nameController),
                    ),
                    _StepPage(
                      icon: Icons.calendar_today_rounded,
                      title: 'Select Birth Date',
                      subtitle: 'When were you born?',
                      field: _PickerField(
                        label: 'Birth Date',
                        value: _formattedDate,
                        placeholder: 'Select date',
                        trailingIcon: Icons.calendar_month_rounded,
                        onTap: () => _pickDate(context),
                      ),
                    ),
                    _StepPage(
                      icon: Icons.access_time_rounded,
                      title: 'Select Birth Time',
                      subtitle: 'What time were you born?',
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PickerField(
                            label: 'Birth Time',
                            value: _timeUnknown ? '' : _formattedTimeDisplay,
                            placeholder: _timeUnknown ? 'Not provided' : 'Select time',
                            trailingIcon: Icons.access_time_rounded,
                            enabled: !_timeUnknown,
                            onTap: () => _pickTime(context),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setState(() => _timeUnknown = !_timeUnknown),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Icon(
                                  _timeUnknown ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 19,
                                  color: _timeUnknown ? AppColors.gold : AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text("I don't know my exact birth time", style: AppTextStyles.bodySecondary),
                                ),
                              ],
                            ),
                          ),
                          if (_timeUnknown) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Noon will be used as an approximation. Your Ascendant may be less precise.',
                                style: TextStyle(color: AppColors.warning, fontSize: 12.5, height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StepPage(
                      icon: Icons.location_on_outlined,
                      title: 'Select Birth Place',
                      subtitle: 'Where were you born?',
                      field: BirthPlaceAutocompleteField(
                        controller: _placeController,
                        onChanged: (_) {
                          if (_stepError != null) setState(() => _stepError = null);
                        },
                        onSelected: (_) {
                          if (_stepError != null) setState(() => _stepError = null);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_stepError != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_stepError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    PrimaryButton(
                      label: _step == _totalSteps - 1 ? 'Submit' : 'Next',
                      icon: _step == _totalSteps - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _handleNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1800),
      lastDate: now,
    );
    if (result != null) setState(() => _selectedDate = result);
  }

  Future<void> _pickTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (result != null) setState(() => _selectedTime = result);
  }
}

class _TopBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  const _TopBar({required this.step, required this.totalSteps, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: onBack,
                  ),
          ),
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (i) {
                final active = i <= step;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.gold : AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget field;

  const _StepPage({required this.icon, required this.title, required this.subtitle, required this.field});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(gradient: AppColors.glyphGradient, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.onGold, size: 30),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 36),
          field,
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Full Name', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'e.g. Priya Sharma',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 19, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final IconData trailingIcon;
  final VoidCallback onTap;
  final bool enabled;

  const _PickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.trailingIcon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surfaceInput : AppColors.surfaceInput.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? placeholder : value,
                    style: TextStyle(color: value.isEmpty ? AppColors.textMuted : AppColors.textPrimary, fontSize: 14.5),
                  ),
                ),
                Icon(trailingIcon, size: 19, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
