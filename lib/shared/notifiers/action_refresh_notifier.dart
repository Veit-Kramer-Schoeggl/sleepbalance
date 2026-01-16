import 'package:flutter/foundation.dart';

/// Global notifier used to trigger a reload of Action Center.
/// Keeps the solution simple without touching MainNavigation.
final ValueNotifier<int> actionRefreshTick = ValueNotifier<int>(0);

void triggerActionRefresh() {
  actionRefreshTick.value++;
}
