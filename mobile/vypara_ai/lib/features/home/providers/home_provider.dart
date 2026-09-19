import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeProvider extends Notifier<void> {
  @override
  void build() {
    // Future: implement home state management
  }
}

final homeProvider = NotifierProvider<HomeProvider, void>(HomeProvider.new);
