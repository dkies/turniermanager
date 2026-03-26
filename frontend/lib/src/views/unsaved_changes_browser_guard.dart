class BrowserUnsavedChangesGuard {
  void register(bool Function() hasUnsavedChanges) {}

  void dispose() {}
}

BrowserUnsavedChangesGuard createBrowserUnsavedChangesGuard() {
  return BrowserUnsavedChangesGuard();
}
