import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_webview;

/// 浏览器标签页数据类
class BrowserTab {
  final String id;
  String url;
  String title;
  WebViewController? mobileController;
  win_webview.WebviewController? windowsController;
  bool isLoading = false;

  BrowserTab({required this.id, required this.url, this.title = '新标签页'});
}
