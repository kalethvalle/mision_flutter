class AssessmentBrowserGuard {
  Future<bool> enterFullscreen() async => false;

  Future<void> exitFullscreen() async {}

  Future<void> lockEscape() async {}

  Future<void> unlockKeyboard() async {}

  bool get isFullscreen => false;

  AssessmentGuardHandle watch({
    required void Function(String type, String message) onIncident,
    required void Function() onFullscreenExit,
  }) => const AssessmentGuardHandle();
}

class AssessmentGuardHandle {
  const AssessmentGuardHandle();

  void dispose() {}
}
