import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win_webview;
import '../../utils/logger.dart';
import 'browser_tab.dart';

/// 浏览器管理功能 Mixin
mixin BrowserManagerMixin<T extends StatefulWidget> on State<T> {
  // 浏览器相关状态
  final List<BrowserTab> tabs = [];
  int currentTabIndex = 0;
  final TextEditingController urlController = TextEditingController();
  bool canGoBack = false;
  bool canGoForward = false;

  bool get isWindows => !kIsWeb && Platform.isWindows;
  BrowserTab? get currentTab => tabs.isEmpty ? null : tabs[currentTabIndex];

  /// 添加新标签页
  void addNewTab(String url) {
    final tab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: '加载中...',
    );

    setState(() {
      tabs.add(tab);
      currentTabIndex = tabs.length - 1;
    });

    urlController.text = url;
    initializeWebViewForTab(tab);
  }

  /// 为标签页初始化WebView
  Future<void> initializeWebViewForTab(BrowserTab tab) async {
    if (isWindows) {
      await initializeWindowsWebView(tab);
    } else {
      initializeMobileWebView(tab);
    }
  }

  /// 初始化 Windows WebView
  Future<void> initializeWindowsWebView(BrowserTab tab) async {
    try {
      final controller = win_webview.WebviewController();
      await controller.initialize();

      controller.loadingState.listen((state) async {
        if (currentTab?.id == tab.id) {
          setState(() {
            tab.isLoading = state == win_webview.LoadingState.loading;
          });

          if (state == win_webview.LoadingState.navigationCompleted) {
            await injectWindowsNewWindowHandler(tab);
          }
        }
      });

      controller.url.listen((url) {
        if (currentTab?.id == tab.id) {
          setState(() {
            tab.url = url;
            urlController.text = url;
          });
        }
      });

      controller.title.listen((title) {
        setState(() {
          tab.title = title.isEmpty ? '新标签页' : title;
        });
      });

      tab.windowsController = controller;
      await controller.setZoomFactor(0.75);
      await controller.loadUrl(tab.url);

      if (currentTab?.id == tab.id) {
        setState(() {
          canGoBack = true;
          canGoForward = true;
        });
      }
    } catch (e) {
      logger.debug('⚠️ Windows WebView 初始化失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebView 初始化失败: $e\n\n提示：请确保系统已安装 WebView2 Runtime'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      tab.windowsController = null;
    }
  }

  /// 为 Windows WebView 注入新窗口拦截脚本
  Future<void> injectWindowsNewWindowHandler(BrowserTab tab) async {
    if (tab.windowsController == null) return;

    try {
      final script = '''
        (function() {
          document.body.style.overflowX = 'hidden';
          document.documentElement.style.overflowX = 'hidden';
          
          window._originalOpen = window.open;
          
          window.open = function(url, target, features) {
            console.log('Intercepted window.open: ' + url);
            if (url && url !== '') {
              var fullUrl = new URL(url, window.location.href).href;
              alert('检测到新窗口请求：' + fullUrl + '\\n\\n请使用右键菜单中的"在新标签页中打开"或手动复制URL到地址栏');
            }
            return { closed: false, close: function() {} };
          };
          
          document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target.tagName !== 'A') {
              target = target.parentElement;
            }
            if (target && target.tagName === 'A') {
              var href = target.getAttribute('href');
              var targetAttr = target.getAttribute('target');
              if (targetAttr === '_blank' && href) {
                e.preventDefault();
                window.location.href = href;
              }
            }
          }, true);
        })();
      ''';

      await tab.windowsController!.executeScript(script);
    } catch (e) {
      logger.debug('Failed to inject new window handler: $e');
    }
  }

  /// 初始化移动端 WebView
  void initializeMobileWebView(BrowserTab tab) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (currentTab?.id == tab.id) {
              setState(() {
                tab.isLoading = true;
                tab.url = url;
                urlController.text = url;
              });
            }
          },
          onPageFinished: (String url) async {
            if (currentTab?.id == tab.id) {
              setState(() {
                tab.isLoading = false;
              });
              updateNavigationState();

              try {
                final title = await tab.mobileController?.getTitle();
                setState(() {
                  tab.title = title ?? '新标签页';
                });
              } catch (e) {
                // 忽略错误
              }

              injectNewWindowHandler(tab);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted && currentTab?.id == tab.id) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('加载失败: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(tab.url));

    tab.mobileController = controller;
  }

  /// 注入 JavaScript 拦截 window.open
  void injectNewWindowHandler(BrowserTab tab) {
    if (tab.mobileController == null) return;

    final script = '''
      window._originalOpen = window.open;
      
      window.open = function(url, target, features) {
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('openNewTab', url || '');
        } else {
          window.parent.postMessage({type: 'openNewTab', url: url || ''}, '*');
        }
        return { closed: false, close: function() {} };
      };
      
      document.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        if (target && target.tagName === 'A') {
          var href = target.getAttribute('href');
          var targetAttr = target.getAttribute('target');
          if (targetAttr === '_blank' && href) {
            e.preventDefault();
            if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler('openNewTab', href);
            } else {
              window.parent.postMessage({type: 'openNewTab', url: href}, '*');
            }
          }
        }
      }, true);
    ''';

    tab.mobileController!.runJavaScript(script);

    tab.mobileController!.addJavaScriptChannel(
      'FlutterBrowser',
      onMessageReceived: (JavaScriptMessage message) {
        addNewTab(message.message);
      },
    );
  }

  /// 更新导航状态
  Future<void> updateNavigationState() async {
    if (currentTab == null) return;

    if (isWindows) {
      setState(() {
        canGoBack = true;
        canGoForward = true;
      });
    } else if (currentTab!.mobileController != null) {
      final back = await currentTab!.mobileController!.canGoBack();
      final forward = await currentTab!.mobileController!.canGoForward();
      setState(() {
        canGoBack = back;
        canGoForward = forward;
      });
    }
  }

  /// 加载 URL
  void loadUrl() {
    if (currentTab == null) return;

    String url = urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入网址'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      urlController.text = url;
    }

    try {
      currentTab!.url = url;
      if (isWindows && currentTab!.windowsController != null) {
        currentTab!.windowsController!.loadUrl(url);
      } else if (currentTab!.mobileController != null) {
        currentTab!.mobileController!.loadRequest(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无效的网址: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 后退
  void goBack() async {
    if (currentTab == null) return;

    if (isWindows && currentTab!.windowsController != null) {
      try {
        await currentTab!.windowsController!.goBack();
      } catch (e) {
        // 忽略错误
      }
    } else if (currentTab!.mobileController != null) {
      if (await currentTab!.mobileController!.canGoBack()) {
        await currentTab!.mobileController!.goBack();
        updateNavigationState();
      }
    }
  }

  /// 前进
  void goForward() async {
    if (currentTab == null) return;

    if (isWindows && currentTab!.windowsController != null) {
      try {
        await currentTab!.windowsController!.goForward();
      } catch (e) {
        // 忽略错误
      }
    } else if (currentTab!.mobileController != null) {
      if (await currentTab!.mobileController!.canGoForward()) {
        await currentTab!.mobileController!.goForward();
        updateNavigationState();
      }
    }
  }

  /// 刷新
  void reloadPage() {
    if (currentTab == null) return;

    if (isWindows && currentTab!.windowsController != null) {
      currentTab!.windowsController!.reload();
    } else if (currentTab!.mobileController != null) {
      currentTab!.mobileController!.reload();
    }
  }

  /// 切换标签
  void switchTab(int index) {
    setState(() {
      currentTabIndex = index;
      urlController.text = tabs[index].url;
    });
    updateNavigationState();
  }

  /// 关闭标签
  void closeTab(int index) {
    if (tabs.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('至少需要保留一个标签页'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tab = tabs[index];

    // 清理 WebView 控制器
    try {
      if (isWindows && tab.windowsController != null) {
        tab.windowsController!.dispose();
        tab.windowsController = null;
      }
      // 移动端的 WebViewController 会自动清理，但我们需要清空引用
      if (!isWindows && tab.mobileController != null) {
        tab.mobileController = null;
      }
    } catch (e) {
      logger.debug('⚠️ 关闭标签时清理 WebView 失败: $e');
    }

    setState(() {
      tabs.removeAt(index);
      if (currentTabIndex >= tabs.length) {
        currentTabIndex = tabs.length - 1;
      }
      urlController.text = currentTab?.url ?? '';
    });

    updateNavigationState();
  }

  /// 释放资源
  void disposeBrowser() {
    urlController.dispose();
    for (var tab in tabs) {
      try {
        if (isWindows && tab.windowsController != null) {
          tab.windowsController!.dispose();
          tab.windowsController = null;
        }
        // 清空移动端控制器引用
        if (!isWindows && tab.mobileController != null) {
          tab.mobileController = null;
        }
      } catch (e) {
        logger.debug('⚠️ 释放标签 WebView 资源失败: $e');
      }
    }
    tabs.clear();
  }
}
