import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HeadfulWebviewWidget extends StatefulWidget {
  const HeadfulWebviewWidget({
    required this.initialSettings,
    required this.shouldInterceptAjaxRequest,
    required this.onAjaxReadyStateChange,
    required this.onWebViewCreated,
    required this.onDispose,
    this.webViewKey,
    this.initialUrl,
    this.onLoadStop,
    this.onLoadResource,
    super.key,
  });

  final String? initialUrl;
  final InAppWebViewSettings initialSettings;
  final GlobalKey<HeadfulWebviewWidgetState>? webViewKey;
  final void Function(InAppWebViewController controller) onWebViewCreated;
  final void Function(InAppWebViewController controller, WebUri? url)?
      onLoadStop;
  final Future<AjaxRequest?> Function(AjaxRequest originalRequest)
      shouldInterceptAjaxRequest;
  final Future<AjaxRequestAction?> Function(AjaxRequest request)
      onAjaxReadyStateChange;
  final VoidCallback onDispose;
  final void Function(
          InAppWebViewController controller, LoadedResource resource)?
      onLoadResource;

  @override
  State<HeadfulWebviewWidget> createState() => HeadfulWebviewWidgetState();
}

class HeadfulWebviewWidgetState extends State<HeadfulWebviewWidget> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      key: widget.webViewKey,
      initialUrlRequest: widget.initialUrl != null
          ? URLRequest(url: WebUri(widget.initialUrl!))
          : null,
      initialSettings: widget.initialSettings,
      onWebViewCreated: (controller) {
        widget.onWebViewCreated(controller);
      },
      onLoadStart: (controller, url) {},
      onPermissionRequest: (controller, request) async {
        log("HeadfulWebviewWidget onPermissionRequest: ${request.origin.data?.uri.toString()}");
        return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        log("HeadfulWebviewWidget shouldOverrideUrlLoading: ${navigationAction.request.url.toString()}");
        return NavigationActionPolicy.ALLOW;
      },
      shouldInterceptAjaxRequest: (controller, ajaxRequest) =>
          widget.shouldInterceptAjaxRequest(ajaxRequest),
      onAjaxReadyStateChange: (controller, request) =>
          widget.onAjaxReadyStateChange(request),
      onLoadStop: (controller, url) {
        log("HeadfulWebviewWidget onLoadStop: ${url?.data?.uri}");
        widget.onLoadStop?.call(controller, url);
      },
      onReceivedError: (controller, request, error) {},
      onLoadResource: (controller, resource) {
        log('HeadfulWebviewWidget onLoadResource ${resource.url?.uriValue.toString()}');
        widget.onLoadResource?.call(controller, resource);
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {},
      onConsoleMessage: (controller, consoleMessage) {},
    );
  }
}
