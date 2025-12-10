import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_webview;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Video Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 平台检测
  final bool _isWindows = !kIsWeb && Platform.isWindows;

  // 移动端 WebView
  WebViewController? _mobileWebViewController;

  // Windows WebView
  win_webview.WebviewController? _windowsWebViewController;

  // 视频 URL
  final String _videoUrl =
      'https://chat-youdu-2.oss-cn-hongkong.aliyuncs.com/videos/1762769596_1762768330_123.mp4';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (_isWindows) {
      // Windows 平台使用 webview_windows
      try {
        _windowsWebViewController = win_webview.WebviewController();
        await _windowsWebViewController!.initialize();
        // 初始状态不加载任何内容
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'WebView 初始化失败: $e\n\n提示：请确保系统已安装 WebView2 Runtime',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      // 移动端使用 webview_flutter
      _mobileWebViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      // 初始状态不加载任何内容
    }
    setState(() {});
  }

  // 创建播放视频的 HTML 内容
  String _createVideoHtml(String videoUrl) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 0;
      background: black;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
    }
    video {
      max-width: 100%;
      max-height: 100%;
      width: auto;
      height: auto;
    }
  </style>
</head>
<body>
  <video controls autoplay preload="auto" playsinline muted>
    <source src="$videoUrl" type="video/mp4">
    <source src="$videoUrl" type="video/webm">
    <source src="$videoUrl" type="video/ogg">
    您的浏览器不支持视频播放。
  </video>
  <script>
    const video = document.querySelector('video');
    // 确保视频自动播放
    video.addEventListener('loadeddata', function() {
      video.play().catch(function(error) {
        console.log('自动播放失败，可能需要用户交互:', error);
      });
    });
    video.addEventListener('error', function(e) {
      console.error('视频加载错误:', e);
    });
    video.addEventListener('loadstart', function() {
      console.log('开始加载视频');
    });
    video.addEventListener('canplay', function() {
      console.log('视频可以播放');
      // 再次尝试播放，确保自动播放
      video.play().catch(function(error) {
        console.log('自动播放失败:', error);
      });
    });
  </script>
</body>
</html>
''';
  }

  // 在 WebView 中播放视频
  void _playVideo() {
    final htmlContent = _createVideoHtml(_videoUrl);

    if (_isWindows) {
      // Windows 平台使用 data URI 加载 HTML 内容
      final dataUri =
          'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
      _windowsWebViewController?.loadUrl(dataUri);
    } else {
      // 移动端加载 HTML 内容
      _mobileWebViewController?.loadHtmlString(htmlContent);
    }
  }

  @override
  void dispose() {
    _windowsWebViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('WebView 视频播放示例'),
      ),
      body: Column(
        children: [
          // WebView 区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isWindows
                    ? (_windowsWebViewController != null
                          ? win_webview.Webview(_windowsWebViewController!)
                          : const Center(child: Text('WebView 初始化中...')))
                    : (_mobileWebViewController != null
                          ? WebViewWidget(controller: _mobileWebViewController!)
                          : const Center(child: Text('WebView 初始化中...'))),
              ),
            ),
          ),

          // 按钮区域
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _playVideo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('播放视频', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
