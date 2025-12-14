import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum StopLoadWaitType {
  navigation,
  exactUri,
  startsWithUri,
}

abstract class StopLoadWait {
  static const defaultTimeout = Duration(seconds: 60);

  final StopLoadWaitType type;
  final Uri? uri;
  final Duration timeout;
  final Completer completer = Completer();

  StopLoadWait({
    required this.type,
    this.timeout = const Duration(seconds: 60),
    this.uri,
  });
}

class StopLoadWaitNavigation extends StopLoadWait {
  StopLoadWaitNavigation() : super(type: StopLoadWaitType.navigation);
}

class StopLoadWaitExactUri extends StopLoadWait {
  StopLoadWaitExactUri(Uri uri)
      : super(type: StopLoadWaitType.exactUri, uri: uri);
}

class StopLoadWaitStartsWithUri extends StopLoadWait {
  StopLoadWaitStartsWithUri(Uri uri)
      : super(type: StopLoadWaitType.startsWithUri, uri: uri);
}

/// Builds JavaScript code to check if an element is ready based on visibility and stability
String buildIsReadyJS({
  required String selector,
  required bool visible,
  required bool stable,
  required bool scrollIntoView,
}) {
  final sel = jsonEncode(selector); // evita comillas rotas e inyección
  final vis = visible ? 'true' : 'false';
  final stb = stable ? 'true' : 'false';
  final siv = scrollIntoView ? 'true' : 'false';

  return '''
(() => {
  const selector = $sel;
  const options = { visible: $vis, stable: $stb, scrollIntoView: $siv };

  function isVisible(el) {
    const cs = window.getComputedStyle(el);
    const r  = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 &&
           cs.display !== 'none' &&
           cs.visibility !== 'hidden' &&
           parseFloat(cs.opacity || '1') > 0;
  }

  function rectOf(el) {
    const r = el.getBoundingClientRect();
    return [Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height)];
  }

  const el = document.querySelector(selector);
  if (!el) return false;

  if (options.scrollIntoView) {
    try { el.scrollIntoView({block:'center', inline:'center'}); } catch (_) {}
  }

  if (options.visible && !isVisible(el)) return false;

  if (options.stable) {
    const nowRect = rectOf(el);
    const key = '__pan_last_rect__' + selector;
    const last = (window[key] || null);
    window[key] = nowRect;
    if (!last) return false; // primera lectura: aún no "estable"
    const same = last[0] === nowRect[0] && last[1] === nowRect[1] &&
                 last[2] === nowRect[2] && last[3] === nowRect[3];
    return same;
  }

  return true;
})()
''';
}

/// Builds JavaScript code to click an element using simple click() method
String buildClickJS(String selector) {
  final sel = jsonEncode(selector);
  return '''
(() => {
  const el = document.querySelector($sel);
  if (!el) throw 'Element not found';
  el.click();
  return true;
})()
''';
}

/// Builds JavaScript code to click an element by dispatching real mouse events
String buildClickWithMouseEventsJS(String selector) {
  final sel = jsonEncode(selector);
  return '''
(() => {
  const el = document.querySelector($sel);
  if (!el) throw 'Element not found';

  const rect = el.getBoundingClientRect();
  const clientX = rect.left + Math.max(1, rect.width / 2);
  const clientY = rect.top + Math.max(1, rect.height / 2);

  const init = { bubbles: true, cancelable: true, clientX, clientY, view: window };
  el.dispatchEvent(new MouseEvent('mousedown', init));
  el.dispatchEvent(new MouseEvent('mouseup', init));
  el.dispatchEvent(new MouseEvent('click', init));
  return true;
})()
''';
}

String buildTapEventsJS(String selector) {
  final sel = jsonEncode(selector);
  return '''
    (() => {
      const el = document.querySelector($sel);
      if (!el) throw 'Element not found';

      const rect = el.getBoundingClientRect();
      const clientX = rect.left + Math.max(1, rect.width / 2);
      const clientY = rect.top + Math.max(1, rect.height / 2);

      const touchObj = new Touch({
        identifier: Date.now(),
        target: el,
        clientX, clientY,
        pageX: clientX, pageY: clientY,
        radiusX: 1, radiusY: 1, rotationAngle: 0, force: 1,
      });

      const touchList = [touchObj];
      const init = { bubbles: true, cancelable: true, touches: touchList, targetTouches: touchList, changedTouches: touchList };

      el.dispatchEvent(new TouchEvent('touchstart', init));
      el.dispatchEvent(new TouchEvent('touchend', init));
      el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, clientX, clientY }));
      el.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, clientX, clientY }));
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, clientX, clientY }));

      return true;
    })()
    ''';
}

String buildTypeEventsJS({
  required String selector,
  required String text,
  int delay = 0,
  int variationMin = 0,
  int variationMax = 0,
}) {
  final sel = jsonEncode(selector);
  final txt = jsonEncode(text);
  final dly = delay;
  final vmin = variationMin;
  final vmax = variationMax;

  return '''
(() => {
  const selector = $sel;
  const text = $txt;
  const baseDelay = ${dly.isNegative ? 0 : dly};
  const varMin = ${vmin.isNegative ? 0 : vmin};
  const varMax = ${vmax.isNegative ? 0 : vmax};

  const el = document.querySelector(selector);
  if (!el) throw 'Element not found';

  // Asegurar foco
  try { el.focus && el.focus(); } catch (_) {}

  // Helpers
  const sleep = (ms) => {
    // Busy-wait síncrono (porque no usamos Promises aquí)
    const end = performance.now() + Math.max(0, ms|0);
    while (performance.now() < end) {}
  };
  const randExtra = (min, max) => {
    if (!Number.isFinite(min) || !Number.isFinite(max) || max < min) return 0;
    return Math.floor(min + Math.random() * (max - min + 1));
  };
  const isTextInput = (node) => {
    if (!node || node.disabled || node.readOnly) return false;
    const tag = (node.tagName || '').toUpperCase();
    if (tag === 'TEXTAREA') return true;
    if (tag === 'INPUT') {
      const t = (node.type || 'text').toLowerCase();
      return [
        'text','search','email','url','tel','password','number',
        'date','time','datetime-local','month','week'
      ].includes(t);
    }
    return false;
  };
  const isCE = (node) => !!(node && node.isContentEditable);

  const pressChar = (ch) => {
    const isEnter = (ch === '\\n' || ch === '\\r');
    const key = isEnter ? 'Enter' : ch;
    const code = (() => {
      if (isEnter) return 'Enter';
      const u = ch.toUpperCase();
      if (u.length === 1 && u >= 'A' && u <= 'Z') return 'Key' + u;
      if (ch >= '0' && ch <= '9') return 'Digit' + ch;
      return ''; // otros símbolos
    })();

    const kbInit = { key, code, bubbles: true, cancelable: true };

    // keydown
    el.dispatchEvent(new KeyboardEvent('keydown', kbInit));
    // keypress (aún hay sitios que lo escuchan)
    el.dispatchEvent(new KeyboardEvent('keypress', kbInit));

    let didChange = false;

    if (isTextInput(el)) {
      if (!isEnter || el.tagName === 'TEXTAREA') {
        // Insertar texto en caret
        const start = (el.selectionStart != null) ? el.selectionStart : el.value.length;
        const end   = (el.selectionEnd   != null) ? el.selectionEnd   : start;
        if (typeof el.setRangeText === 'function') {
          el.setRangeText(ch, start, end, 'end');
        } else {
          el.value = (el.value ?? '').slice(0, start) + ch + (el.value ?? '').slice(end);
          try { el.selectionStart = el.selectionEnd = start + ch.length; } catch (_) {}
        }
        didChange = true;
      }
    } else if (isCE(el)) {
      // contenteditable
      try {
        document.execCommand('insertText', false, ch);
        didChange = true;
      } catch (_) {
        const sel = window.getSelection && window.getSelection();
        if (sel && sel.rangeCount > 0) {
          const range = sel.getRangeAt(0);
          range.deleteContents();
          range.insertNode(document.createTextNode(ch));
          range.collapse(false);
          sel.removeAllRanges(); sel.addRange(range);
          didChange = true;
        }
      }
    } else {
      // Elemento no editable: solo eventos
    }

    // input event si cambió el contenido
    if (didChange) {
      try {
        el.dispatchEvent(new InputEvent('input', {
          data: isEnter && isTextInput(el) && el.tagName !== 'TEXTAREA' ? null : ch,
          inputType: 'insertText',
          bubbles: true,
          cancelable: true
        }));
      } catch (_) {
        const ev = document.createEvent('Event');
        ev.initEvent('input', true, true);
        el.dispatchEvent(ev);
      }
    }

    // keyup
    el.dispatchEvent(new KeyboardEvent('keyup', kbInit));

    // Espera entre teclas
    const waitMs = Math.max(0, baseDelay + randExtra(varMin, varMax));
    if (waitMs > 0) sleep(waitMs);
  };

  // Si el selector apunta a algo no enfocable, intenta mover el foco a inputs hijos
  if (document.activeElement !== el && (isTextInput(el) || isCE(el))) {
    try { el.focus && el.focus(); } catch (_) {}
  }

  // Escribir por code points (soporta emojis y surrogates)
  for (const ch of Array.from(text)) {
    pressChar(ch);
  }

  return true;
})()
''';
}

Future<AjaxRequest?> shouldInterceptAjaxRequest(
  AjaxRequest originalRequest, {
  Map<RegExp, Future<AjaxRequest> Function(AjaxRequest)> requestInterceptors =
      const {},
  Map<RegExp, Future<AjaxRequestAction> Function(AjaxRequest)>
      responseInterceptors = const {},
}) async {
  final uriString = originalRequest.url?.uriValue.toString();
  log('WebViewHelpers shouldInterceptAjaxRequest uriString $uriString');
  if (uriString == null) return null;

  var previousRequest = originalRequest;
  var hasRequestInterceptorMatch = false;

  for (final requestInterceptorEntry in requestInterceptors.entries) {
    final regExp = requestInterceptorEntry.key;

    if (regExp.hasMatch(uriString)) {
      final callback = requestInterceptorEntry.value;

      final newRequest = await callback(previousRequest);
      previousRequest = newRequest;
      hasRequestInterceptorMatch = true;
    }
  }

  if (hasRequestInterceptorMatch) return previousRequest;

  final responseInterceptorsMatches =
      responseInterceptors.keys.map((key) => key.hasMatch(uriString));

  if (responseInterceptorsMatches.contains(true)) {
    return previousRequest;
  }

  return null;
}

Future<AjaxRequestAction?> onAjaxReadyStateChange(
  AjaxRequest request, {
  Map<RegExp, Future<AjaxRequest> Function(AjaxRequest)> requestInterceptors =
      const {},
  Map<RegExp, Future<AjaxRequestAction> Function(AjaxRequest)>
      responseInterceptors = const {},
}) async {
  final uriString = request.url?.uriValue.toString();
  log('WebViewHelpers onAjaxReadyStateChange uriString $uriString');
  if (uriString == null) return AjaxRequestAction.PROCEED;

  for (final responseInterceptorEntry in responseInterceptors.entries) {
    final regExp = responseInterceptorEntry.key;

    if (regExp.hasMatch(uriString)) {
      final callback = responseInterceptorEntry.value;

      final result = await callback(request);
      if (result == AjaxRequestAction.ABORT) return AjaxRequestAction.ABORT;
    }
  }

  return AjaxRequestAction.PROCEED;
}

void onLoadResource(
  LoadedResource resource, {
  Map<RegExp, VoidCallback> loadResourceListeners = const {},
}) {
  final uriString = resource.url?.uriValue.toString();
  log('WebViewHelpers onLoadResource uriString $uriString');
  if (uriString == null) return;

  for (final listenerEntry in loadResourceListeners.entries) {
    final regExp = listenerEntry.key;

    if (regExp.hasMatch(uriString)) {
      final callback = listenerEntry.value;
      callback();
    }
  }
}

Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
  NavigationAction navigationAction, {
  Map<RegExp, Future<NavigationActionPolicy?> Function(NavigationAction)>
      shouldOverrideUrlLoadingListeners = const {},
}) async {
  final uriString = navigationAction.request.url?.uriValue.toString();
  log('WebViewHelpers shouldOverrideUrlLoading uriString $uriString');
  if (uriString == null) return NavigationActionPolicy.ALLOW;

  for (final listenerEntry in shouldOverrideUrlLoadingListeners.entries) {
    final regExp = listenerEntry.key;

    if (regExp.hasMatch(uriString)) {
      final callback = listenerEntry.value;
      final result = await callback(navigationAction);
      if (result != null) return result;
    }
  }

  return NavigationActionPolicy.ALLOW;
}
