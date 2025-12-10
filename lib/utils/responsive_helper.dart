import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 响应式布局助手
class ResponsiveHelper {
  /// 平板电脑断点
  static const double tabletBreakpoint = 768.0;

  /// 手机断点
  static const double mobileBreakpoint = 600.0;

  /// 大屏手机断点（用于调整布局）
  static const double largeMobileBreakpoint = 414.0;

  /// 判断是否为移动设备（物理设备）
  static bool get isMobileDevice {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 判断是否为桌面设备（物理设备）
  static bool get isDesktopDevice {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 根据屏幕尺寸判断是否为手机布局
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < mobileBreakpoint ||
        (isMobileDevice && width < tabletBreakpoint);
  }

  /// 根据屏幕尺寸判断是否为平板布局
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint &&
        width < tabletBreakpoint &&
        isMobileDevice;
  }

  /// 根据屏幕尺寸判断是否为桌面布局
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint || isDesktopDevice;
  }

  /// 获取当前设备类型
  static DeviceType getDeviceType(BuildContext context) {
    if (isMobile(context)) return DeviceType.mobile;
    if (isTablet(context)) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 获取自适应的内边距
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(20.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(24.0);
    }
  }

  /// 获取自适应的字体大小
  static double getAdaptiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.1;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.2;
    }
  }

  /// 获取自适应的图标大小
  static double getAdaptiveIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.15;
      case DeviceType.desktop:
        return desktop ?? mobile * 1.3;
    }
  }

  /// 获取自适应的按钮高度
  static double getAdaptiveButtonHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 48.0;
      case DeviceType.tablet:
        return 52.0;
      case DeviceType.desktop:
        return 44.0; // 桌面端可以稍小，因为使用鼠标点击
    }
  }

  /// 获取对话框的自适应宽度
  static double? getAdaptiveDialogWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth * 0.9; // 90%的屏幕宽度
      case DeviceType.tablet:
        return screenWidth * 0.7; // 70%的屏幕宽度
      case DeviceType.desktop:
        return 600.0; // 固定宽度
    }
  }

  /// 构建响应式布局
  static Widget buildResponsive(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// 设备类型枚举
enum DeviceType { mobile, tablet, desktop }

/// 响应式布局构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getDeviceType(context));
  }
}

/// 响应式布局Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.buildResponsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
