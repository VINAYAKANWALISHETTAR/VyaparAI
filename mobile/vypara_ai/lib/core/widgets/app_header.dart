import 'package:flutter/material.dart';
import 'package:vypara_ai/core/widgets/language_selector.dart';
import 'package:vypara_ai/core/widgets/notification_button.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.title});

  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title == null ? const Text('VyaparaAI') : Text(title!),
      actions: const <Widget>[LanguageSelector(), NotificationButton()],
    );
  }
}
