// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

class AssessmentBrowserGuard {
  Future<bool> enterFullscreen() async {
    final element = html.document.documentElement;
    if (element == null) return false;
    try {
      await element.requestFullscreen();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> exitFullscreen() async {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  }

  Future<void> lockEscape() async {
    try {
      final keyboard = (html.window.navigator as dynamic).keyboard;
      await keyboard?.lock(['Escape']);
    } on Object {
      // Browser support is intentionally best effort.
    }
  }

  Future<void> unlockKeyboard() async {
    try {
      (html.window.navigator as dynamic).keyboard?.unlock();
    } on Object {
      // Browser support is intentionally best effort.
    }
  }

  bool get isFullscreen => html.document.fullscreenElement != null;

  AssessmentGuardHandle watch({
    required void Function(String type, String message) onIncident,
    required void Function() onFullscreenExit,
  }) {
    final subscriptions = <StreamSubscription<html.Event>>[
      html.document.onFullscreenChange.listen((_) {
        if (!isFullscreen) onFullscreenExit();
      }),
      html.document.onVisibilityChange.listen((_) {
        if (html.document.hidden == true) {
          onIncident('visibility_hidden', 'Cambió de pestaña o minimizó.');
        }
      }),
      html.window.onBlur.listen((_) {
        onIncident('focus_lost', 'La ventana perdió el foco.');
      }),
      html.window.onPageHide.listen((_) {
        onIncident('pagehide', 'Abandonó o recargó la página.');
      }),
      html.document.onKeyDown.listen((event) {
        final key = event.key?.toLowerCase() ?? '';
        final meta = event.ctrlKey || event.metaKey;
        final blocked =
            event.key == 'F12' ||
            (meta &&
                ['c', 'v', 'x', 'a', 's', 'p', 'u', 'f', 'g'].contains(key)) ||
            (meta && event.shiftKey && ['i', 'j', 'c'].contains(key));
        if (!blocked) return;
        event.preventDefault();
        onIncident('blocked_key', 'Usó una combinación de teclas bloqueada.');
      }),
    ];
    return AssessmentGuardHandle(subscriptions);
  }
}

class AssessmentGuardHandle {
  const AssessmentGuardHandle([this._subscriptions = const []]);

  final List<StreamSubscription<html.Event>> _subscriptions;

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
