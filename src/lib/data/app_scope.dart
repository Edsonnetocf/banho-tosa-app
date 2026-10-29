import 'package:flutter/widgets.dart';

import 'app_repository.dart';

class AppScope extends InheritedNotifier<AppRepository> {
  const AppScope({
    super.key,
    required AppRepository repository,
    required super.child,
  }) : super(notifier: repository);
  static AppRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppRepository read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
