import 'package:flutter/material.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguage = 'English';
  String _selectedCode = 'EN';

  final List<({String code, String name, String nativeName})> _languages = const [
    (code: 'EN', name: 'English', nativeName: 'English'),
    (code: 'HI', name: 'Hindi', nativeName: 'हिंदी'),
    (code: 'TA', name: 'Tamil', nativeName: 'தமிழ்'),
    (code: 'TE', name: 'Telugu', nativeName: 'తెలుగు'),
    (code: 'KN', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    (code: 'ML', name: 'Malayalam', nativeName: 'മലയാളം'),
    (code: 'BN', name: 'Bengali', nativeName: 'বাংলা'),
  ];

  void _openLanguageModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Language',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.outline),
                    const SizedBox(height: 8),

                    // Language list
                    ..._languages.map((lang) {
                      final isSelected = lang.name == _selectedLanguage;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang.name;
                            _selectedCode = lang.code;
                          });
                          setModalState(() {});
                          Navigator.pop(modalContext);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Row(
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                lang.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(Icons.check, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openLanguageModal,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
