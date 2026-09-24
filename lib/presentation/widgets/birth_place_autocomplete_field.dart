import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/place_suggestion.dart';
import '../../data/services/place_service.dart';

class BirthPlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onChanged;

  const BirthPlaceAutocompleteField({
    super.key,
    required this.controller,
    this.onSelected,
    this.onChanged,
  });

  @override
  State<BirthPlaceAutocompleteField> createState() => _BirthPlaceAutocompleteFieldState();
}

class _BirthPlaceAutocompleteFieldState extends State<BirthPlaceAutocompleteField> {
  final PlaceService _placeService = PlaceService();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.controller.text.trim().isNotEmpty) {
        _performSearch(widget.controller.text);
      }
    } else {
      // Delay closing dropdown slightly so taps on items register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showDropdown = false);
        }
      });
    }
  }

  void _onTextChanged(String text) {
    widget.onChanged?.call(text);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      _performSearch(text);
    });
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
          _showDropdown = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    try {
      final results = await _placeService.search(clean);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showDropdown = _focusNode.hasFocus && results.isNotEmpty;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectPlace(PlaceSuggestion place) {
    widget.controller.text = place.displayName;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: place.displayName.length),
    );
    widget.onSelected?.call(place.displayName);
    widget.onChanged?.call(place.displayName);

    setState(() {
      _showDropdown = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Birth Place', style: AppTextStyles.label),
        const SizedBox(height: 8),

        // Search Input Field
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: 'e.g. Surat, Gujarat, India',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.goldBright),
            suffixIcon: _buildSuffixIcon(),
          ),
        ),

        // Suggestions Dropdown List (only when typing)
        if (_showDropdown && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 230),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSoft),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  final subtitle = [place.state, place.country].where((s) => s != null && s.isNotEmpty).join(', ');

                  return InkWell(
                    onTap: () => _selectPlace(place),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppColors.goldBright,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.city.isNotEmpty ? place.city : place.displayName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (subtitle.isNotEmpty && subtitle != place.city) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.north_west_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
        ),
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
        onPressed: () {
          widget.controller.clear();
          widget.onChanged?.call('');
          _performSearch('');
        },
      );
    }

    return null;
  }
}
