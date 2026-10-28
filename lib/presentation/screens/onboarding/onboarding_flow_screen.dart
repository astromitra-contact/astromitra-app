import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/kundli_models.dart';
import '../../providers/kundli_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/birth_place_autocomplete_field.dart';
import '../../widgets/chat_banner_ad_widget.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/star_field_background.dart';
import '../main_shell.dart';

/// A five-step wizard — name, birth date, birth time, birth place, app language —
/// each on its own page with a progress bar up top.
/// After birth place is selected, Step 4 allows selecting the preferred app
/// language. The final step submits everything to [KundliProvider.createKundli]
/// and saves the selected language.
///
/// Pass [initialDetails] to pre-populate fields (edit mode).
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

  static const _totalSteps = 5;

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
          setState(() => _stepError = context.tr('enterValidName'));
          return;
        }
        _goTo(1);
        break;
      case 1:
        final error = Validators.dateOfBirth(_formattedDate.isEmpty ? null : _formattedDate);
        if (_selectedDate == null || error != null) {
          setState(() => _stepError = context.tr('selectValidDate'));
          return;
        }
        _goTo(2);
        break;
      case 2:
        if (!_timeUnknown && _selectedTime == null) {
          setState(() => _stepError = context.tr('selectValidTime'));
          return;
        }
        _goTo(3);
        break;
      case 3:
        final error = Validators.birthPlace(_placeController.text);
        if (error != null) {
          setState(() => _stepError = context.tr('selectValidPlace'));
          return;
        }
        // Advance to Step 4 (Language Selection) after birth place is entered
        _goTo(4);
        break;
      case 4:
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
      setState(() => _stepError = context.tr('somethingWentWrong'));
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
              // 1. AD FIRST: At the very top of the screen
              const AppBannerAdWidget(),

              // 2. AFTER AD: The TopBar (like chat section)
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
                    // Step 0: Name
                    _StepPage(
                      icon: Icons.person_outline_rounded,
                      title: context.tr('enterFullName'),
                      subtitle: context.tr('nameSubtitle'),
                      field: _NameField(
                        controller: _nameController,
                        label: context.tr('fullName'),
                        hint: context.tr('nameHint'),
                      ),
                    ),
                    // Step 1: Birth Date
                    _StepPage(
                      icon: Icons.calendar_today_rounded,
                      title: context.tr('selectBirthDate'),
                      subtitle: context.tr('dateSubtitle'),
                      field: _PickerField(
                        label: context.tr('birthDate'),
                        value: _formattedDate,
                        placeholder: context.tr('selectDate'),
                        trailingIcon: Icons.calendar_month_rounded,
                        onTap: () => _pickDate(context),
                      ),
                    ),
                    // Step 2: Birth Time
                    _StepPage(
                      icon: Icons.access_time_rounded,
                      title: context.tr('selectBirthTime'),
                      subtitle: context.tr('timeSubtitle'),
                      field: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PickerField(
                            label: context.tr('birthTime'),
                            value: _timeUnknown ? '' : _formattedTimeDisplay,
                            placeholder: _timeUnknown ? context.tr('notProvided') : context.tr('selectTime'),
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
                                Expanded(
                                  child: Text(
                                    context.tr('unknownTime'),
                                    style: AppTextStyles.bodySecondary,
                                  ),
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
                              child: Text(
                                context.tr('noonApproximation'),
                                style: const TextStyle(color: AppColors.warning, fontSize: 12.5, height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Step 3: Birth Place
                    _StepPage(
                      icon: Icons.location_on_outlined,
                      title: context.tr('selectBirthPlace'),
                      subtitle: context.tr('placeSubtitle'),
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
                    // Step 4: App Language (Shown immediately after birth place)
                    _StepPage(
                      icon: Icons.language_rounded,
                      title: context.tr('selectAppLanguage'),
                      subtitle: context.tr('languageSubtitle'),
                      field: const _LanguageSelectionList(),
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
                      label: _step == _totalSteps - 1 ? context.tr('submit') : context.tr('next'),
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
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
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
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 30),
          field,
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _NameField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 19, color: AppColors.textMuted),
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

/// Interactive selection list for choosing app language with rich styling
class _LanguageSelectionList extends StatelessWidget {
  const _LanguageSelectionList();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final current = languageProvider.currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: AppLanguage.values.map((lang) {
        final isSelected = lang == current;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              languageProvider.setLanguage(lang);
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.borderSoft,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.textMuted,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.gold : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 15, color: AppColors.onGold)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.nativeName,
                          style: TextStyle(
                            color: isSelected ? AppColors.goldBright : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.gold : AppColors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
