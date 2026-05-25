const bool debugCategoryFlow = bool.fromEnvironment('DEBUG_CATEGORY_FLOW');

void logCategoryFlow(String message) {
  if (debugCategoryFlow) {
    // ignore: avoid_print
    print('[CategoryFlow] $message');
  }
}
