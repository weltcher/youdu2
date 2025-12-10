@echo off
echo 清理构建缓存...
flutter clean

echo 获取依赖...
flutter pub get

echo 完成！
pause
