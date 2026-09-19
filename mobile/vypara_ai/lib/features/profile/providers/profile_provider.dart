import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileProvider extends Notifier<void> {
  @override
  void build() {
    // Future: implement profile state management
  }
}

final profileProvider = NotifierProvider<ProfileProvider, void>(ProfileProvider.new);
