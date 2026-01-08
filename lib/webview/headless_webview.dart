import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/webview/helpers.dart';
import 'package:pan_scrapper/webview/webview.dart';

class HeadlessWebview implements WebviewInstance {
  HeadlessInAppWebView? _headlessInAppWebView;
  final CookieManager _cookieManager = CookieManager.instance();
  StopLoadWait? _task;
  final Map<RegExp, Future<AjaxRequest> Function(AjaxRequest originalRequest)>
  _ajaxRequestInterceptors = {};
  final Map<RegExp, Future<AjaxRequestAction> Function(AjaxRequest request)>
  _ajaxResponseInterceptor = {};
  final Map<RegExp, VoidCallback> _loadResourceListeners = {};
  final Map<RegExp, Future<NavigationActionPolicy?> Function(NavigationAction)>
  _shouldOverrideUrlLoadingListeners = {};
  bool _isInitialized = false;

  HeadlessWebview();

  Future<void> init({
    String? initialUrl,
    String? cookies,
    Future<FetchRequest?> Function(FetchRequest request)?
    fetchRequestInterceptor,
    Future<AjaxRequestAction?> Function(AjaxRequest request)?
    ajaxRequestInterceptor,
    Duration? timeout,
  }) async {
    if (_isInitialized) {
      throw Exception("HeadlessWebview is already initialized");
    }

    _headlessInAppWebView = HeadlessInAppWebView(
      initialUrlRequest: initialUrl != null
          ? URLRequest(
              url: WebUri(initialUrl),
              headers: cookies != null ? {'Cookie': cookies} : null,
            )
          : null,

      onLoadResource: (controller, resource) => onLoadResource(
        resource,
        loadResourceListeners: _loadResourceListeners,
      ),
      shouldInterceptAjaxRequest: (controller, originalRequest) =>
          shouldInterceptAjaxRequest(
            originalRequest,
            requestInterceptors: _ajaxRequestInterceptors,
            responseInterceptors: _ajaxResponseInterceptor,
          ),
      onAjaxReadyStateChange: (controller, request) => onAjaxReadyStateChange(
        request,
        requestInterceptors: _ajaxRequestInterceptors,
        responseInterceptors: _ajaxResponseInterceptor,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) =>
          shouldOverrideUrlLoading(
            navigationAction,
            shouldOverrideUrlLoadingListeners:
                _shouldOverrideUrlLoadingListeners,
          ),
      onLoadStop: (controller, url) {
        log("onLoadStop: $url");

        _checkAndComplete(controller, url);
      },
    );
    _cookieManager.deleteAllCookies();
    _task = StopLoadWaitNavigation();

    await _headlessInAppWebView?.run();

    _isInitialized = true;
  }

  @override
  Future<void> close() async {
    _task = null;
    _cookieManager.deleteAllCookies();
    if (_headlessInAppWebView != null) {
      return _headlessInAppWebView!.dispose();
    }
  }

  void _checkAndComplete(InAppWebViewController controller, Uri? url) {
    final task = _task;
    if (task != null && !task.completer.isCompleted) {
      log("Checking task: $task");
      switch (task.type) {
        case StopLoadWaitType.exactUri:
          if (task.uri.toString() == url.toString()) {
            task.completer.complete();
          }
          break;
        case StopLoadWaitType.startsWithUri:
          if (url.toString().startsWith(task.uri.toString())) {
            task.completer.complete();
          }
          break;
        case StopLoadWaitType.navigation:
          task.completer.complete();
          break;
      }
    }
  }

  @override
  Future<List<Cookie>> cookies({List<Uri>? urls}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    if (urls == null) {
      final currentUrl = await _headlessInAppWebView!.webViewController
          ?.getUrl();
      final currentUrlUri = currentUrl?.data?.uri;
      if (currentUrlUri != null) {
        urls = [currentUrlUri];
      }
    }

    final cookies = await Future.wait(
      urls!.map((url) => _cookieManager.getCookies(url: WebUri.uri(url))),
    );

    return cookies.expand((e) => e).toList();
  }

  @override
  Future<void> deleteCookies({Uri? url}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    url ??=
        (await _headlessInAppWebView!.webViewController?.getUrl())?.data?.uri;

    if (url != null) {
      _cookieManager.deleteCookies(url: WebUri.uri(url));
    }
  }

  @override
  FutureOr<dynamic> evaluate(String source) {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    return _headlessInAppWebView!.webViewController?.evaluateJavascript(
      source: source,
    );
  }

  @override
  Future<void> navigate(URLRequest request, {Duration? timeout}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    _task = StopLoadWaitNavigation();
    _headlessInAppWebView!.webViewController?.loadUrl(urlRequest: request);
    return await _task!.completer.future.timeout(
      timeout ?? StopLoadWait.defaultTimeout,
    );
  }

  Future<void> stopLoadWaitNavigation({Duration? timeout}) async {
    _task = StopLoadWaitNavigation();
    return await _task!.completer.future.timeout(
      timeout ?? StopLoadWait.defaultTimeout,
    );
  }

  Future<void> stopLoadWaitExactUri(Uri uri, {Duration? timeout}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    final currentUrl = await _headlessInAppWebView!.webViewController?.getUrl();
    if (currentUrl != null && currentUrl.toString() == uri.toString()) {
      return;
    }

    _task = StopLoadWaitExactUri(uri);
    return await _task!.completer.future.timeout(
      timeout ?? StopLoadWait.defaultTimeout,
    );
  }

  Future<void> stopLoadWaitStartsWithUri(Uri uri, {Duration? timeout}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    final currentUrl = await _headlessInAppWebView!.webViewController?.getUrl();
    if (currentUrl != null &&
        currentUrl.toString().startsWith(uri.toString())) {
      return;
    }

    _task = StopLoadWaitStartsWithUri(uri);
    return await _task!.completer.future.timeout(
      timeout ?? StopLoadWait.defaultTimeout,
    );
  }

  Future<String?> getHtml({Duration? timeout}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    return await _headlessInAppWebView!.webViewController?.getHtml();
  }

  @override
  Future<String?> screenshot({Duration? timeout}) async {
    if (_headlessInAppWebView == null) {
      throw Exception("HeadlessWebview is not running");
    }

    final screenshotUint8List = await _headlessInAppWebView!.webViewController
        ?.takeScreenshot();
    if (screenshotUint8List != null) {
      final screenshotBase64 = base64Encode(screenshotUint8List);
      return screenshotBase64;
    }
    return null;
  }

  Future<bool> _pollIsReady({
    required InAppWebViewController controller,
    required String selector,
    required Duration timeout,
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = false,
  }) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      final js = buildIsReadyJS(
        selector: selector,
        visible: visible,
        stable: stable,
        scrollIntoView: scrollIntoView,
      );
      final res = await controller.evaluateJavascript(source: js);
      if (res == true) return true;
      await Future.delayed(pollInterval);
    }
    return false;
  }

  @override
  Future<void> waitForSelector(
    String selector, {
    Duration? timeout,
    Duration pollInterval = const Duration(milliseconds: 100),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = false,
  }) async {
    final c = _headlessInAppWebView?.webViewController;
    if (c == null) throw Exception("HeadlessWebview is not running");

    final finalTimeout = timeout ?? const Duration(seconds: 30);

    final ok = await _pollIsReady(
      controller: c,
      selector: selector,
      timeout: finalTimeout,
      pollInterval: pollInterval,
      visible: visible,
      stable: stable,
      scrollIntoView: scrollIntoView,
    );
    if (!ok) {
      throw TimeoutException(
        'Timeout waiting for $selector after ${finalTimeout.inMilliseconds}ms',
      );
    }
  }

  @override
  Future<void> click(
    String selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = true,
    bool dispatchRealMouseEvents = false,
  }) async {
    final c = _headlessInAppWebView?.webViewController;
    if (c == null) throw Exception("HeadlessWebview is not running");

    await waitForSelector(
      selector,
      timeout: timeout,
      pollInterval: pollInterval,
      visible: visible,
      stable: stable,
      scrollIntoView: scrollIntoView,
    );

    final js = dispatchRealMouseEvents
        ? buildClickWithMouseEventsJS(selector)
        : buildClickJS(selector);

    final res = await c.evaluateJavascript(source: js);
    if (res != true) {
      throw Exception('Failed to click $selector');
    }
  }

  @override
  Future<void> tap(
    String selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = true,
  }) async {
    final c = _headlessInAppWebView?.webViewController;
    if (c == null) throw Exception("HeadlessWebview is not running");

    await waitForSelector(
      selector,
      timeout: timeout,
      pollInterval: pollInterval,
      visible: visible,
      stable: stable,
      scrollIntoView: scrollIntoView,
    );

    final js = buildTapEventsJS();

    var res = await c.callAsyncJavaScript(
      functionBody: js,
      arguments: {'selector': selector},
    );
    if (res?.value != true) {
      throw Exception('Failed to click $selector');
    }
  }

  @override
  Future<void> type(
    String selector,
    String text, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = true,
    Duration delay = Duration.zero,
    Duration minVariation = Duration.zero,
    Duration maxVariation = Duration.zero,
  }) async {
    final c = _headlessInAppWebView?.webViewController;
    if (c == null) throw Exception("HeadlessWebview is not running");

    // Asegura que el campo exista/esté listo antes de escribir
    await waitForSelector(
      selector,
      timeout: timeout,
      pollInterval: pollInterval,
      visible: visible,
      stable: stable,
      scrollIntoView: scrollIntoView,
    );

    final js = buildTypeEventsJS(
      selector: selector,
      text: text,
      delay: delay.inMilliseconds,
      variationMin: minVariation.inMilliseconds,
      variationMax: maxVariation.inMilliseconds,
    );

    var res = await c.callAsyncJavaScript(
      functionBody: js,
      arguments: {
        'selector': selector,
        'text': text,
        'baseDelay': delay.isNegative ? 0 : delay.inMilliseconds,
        'varMin': minVariation.isNegative ? 0 : minVariation.inMilliseconds,
        'varMax': maxVariation.isNegative ? 0 : maxVariation.inMilliseconds,
      },
    );
    if (res?.value != true) {
      throw Exception('type() failed for selector "$selector"');
    }
  }

  @override
  void addAjaxRequestListener(
    RegExp regex,
    Future<AjaxRequest> Function(AjaxRequest p1) callback,
  ) {
    _ajaxRequestInterceptors[regex] = callback;
  }

  @override
  void addAjaxResponseListener(
    RegExp regex,
    Future<AjaxRequestAction> Function(AjaxRequest p1) callback,
  ) {
    _ajaxResponseInterceptor[regex] = callback;
  }

  @override
  void removeAjaxRequestListener(RegExp regex) {
    _ajaxRequestInterceptors.remove(regex);
  }

  @override
  void removeAjaxResponseListener(RegExp regex) {
    _ajaxResponseInterceptor.remove(regex);
  }

  @override
  void addLoadResourceListener(RegExp regex, VoidCallback callback) {
    _loadResourceListeners[regex] = callback;
  }

  @override
  void removeLoadResourceListener(RegExp regex) {
    _loadResourceListeners.remove(regex);
  }

  @override
  void addShouldOverrideUrlLoadingListener(
    RegExp regex,
    Future<NavigationActionPolicy?> Function(NavigationAction) callback,
  ) {
    _shouldOverrideUrlLoadingListeners[regex] = callback;
  }

  @override
  void removeShouldOverrideUrlLoadingListener(RegExp regex) {
    _shouldOverrideUrlLoadingListeners.remove(regex);
  }

  @override
  void removeAllListeners() {
    _ajaxRequestInterceptors.clear();
    _ajaxResponseInterceptor.clear();
    _loadResourceListeners.clear();
    _shouldOverrideUrlLoadingListeners.clear();
  }
}
