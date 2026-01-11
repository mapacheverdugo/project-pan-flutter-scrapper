import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/services/connection/webview/headful_webview.dart';
import 'package:pan_scrapper/services/connection/webview/headless_webview.dart';

abstract class WebviewInstance {
  Future<void> navigate(URLRequest request, {Duration? timeout});
  Future<List<Cookie>> cookies({List<Uri>? urls});
  Future<void> deleteCookies({Uri? url});
  FutureOr<dynamic> evaluate(String source);
  Future<String?> screenshot({Duration? timeout});

  /// Waits for a DOM element matching [selector] to be ready.
  /// - Presence in DOM
  /// - If [visible] is true: non-zero size, visible/opacity checks
  /// - If [stable] is true: bounding rect remains stable for two consecutive polls
  ///
  Future<void> waitForSelector(
    String selector, {
    Duration pollInterval = const Duration(milliseconds: 100),
    bool visible = true,
    bool stable = true,
    Duration? timeout,
  });

  Future<void> click(
    String selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = true,
    bool dispatchRealMouseEvents = false,
  });
  Future<void> tap(
    String selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 150),
    bool visible = true,
    bool stable = true,
    bool scrollIntoView = true,
  });
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
  });

  void addAjaxRequestListener(
    RegExp regex,
    Future<AjaxRequest> Function(AjaxRequest) callback,
  );
  void addAjaxResponseListener(
    RegExp regex,
    Future<AjaxRequestAction> Function(AjaxRequest) callback,
  );
  void removeAjaxRequestListener(RegExp regex);
  void removeAjaxResponseListener(RegExp regex);
  void addLoadResourceListener(RegExp regex, VoidCallback callback);
  void removeLoadResourceListener(RegExp regex);
  void addShouldOverrideUrlLoadingListener(
    RegExp regex,
    Future<NavigationActionPolicy?> Function(NavigationAction) callback,
  );
  void removeShouldOverrideUrlLoadingListener(RegExp regex);
  void removeAllListeners();
  Future<void> close();
}

class Webview {
  static Future<WebviewInstance> run({
    bool headless = true,
    BuildContext? context,
    Widget Function(BuildContext context, Widget webview)? builder,
    String? initialUrl,
    Future<FetchRequest?> Function(FetchRequest request)?
    fetchRequestInterceptor,
    Duration? timeout,
  }) async {
    if (headless) {
      final headlessWebview = HeadlessWebview();
      await headlessWebview.init(
        initialUrl: initialUrl,
        fetchRequestInterceptor: fetchRequestInterceptor,
        timeout: timeout,
      );
      return headlessWebview;
    } else {
      if (context == null) {
        throw Exception("Context is required for headful webview");
      }

      final headfulWebview = HeadfulWebview();
      await headfulWebview.init(
        context: context,
        builder: builder,
        initialUrl: initialUrl,
        fetchRequestInterceptor: fetchRequestInterceptor,
        timeout: timeout,
      );

      return headfulWebview;
    }
  }
}
