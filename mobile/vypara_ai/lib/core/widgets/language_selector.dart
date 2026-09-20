import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language selection is coming soon.')),
      ),
      icon: const Text('EN'),
      label: const Icon(Icons.keyboard_arrow_down, size: 18),
    );
  }
}
