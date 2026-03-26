import 'dart:async';
import 'dart:html' as html;

class BrowserUnsavedChangesGuard {
  StreamSubscription<html.Event>? _beforeUnloadSubscription;

  void register(bool Function() hasUnsavedChanges) {
    _beforeUnloadSubscription?.cancel();
    _beforeUnloadSubscription = html.window.onBeforeUnload.listen((event) {
      if (!hasUnsavedChanges()) {
        return;
      }

      event.preventDefault();
      if (event is html.BeforeUnloadEvent) {
        event.returnValue = '';
      }
    });
  }

  void dispose() {
    _beforeUnloadSubscription?.cancel();
    _beforeUnloadSubscription = null;
  }
}

BrowserUnsavedChangesGuard createBrowserUnsavedChangesGuard() {
  return BrowserUnsavedChangesGuard();
}
