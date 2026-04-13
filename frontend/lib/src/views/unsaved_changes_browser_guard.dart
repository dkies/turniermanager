class BrowserUnsavedChangesGuard {
  void register(
    bool Function() hasUnsavedChanges, {
    required String message,
  }) {}

  void dispose() {}
}

BrowserUnsavedChangesGuard createBrowserUnsavedChangesGuard() {
  return BrowserUnsavedChangesGuard();
}
