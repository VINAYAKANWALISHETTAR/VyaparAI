import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthProvider extends Notifier<void> {
  @override
  void build() {
    // Future: implement auth state management
  }
}

final authProvider = NotifierProvider<AuthProvider, void>(AuthProvider.new);
