#!/bin/bash

# Flutter APK 构建脚本
# 用法: ./build_apk.sh [debug|release] [version_type]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认参数
BUILD_TYPE=${1:-release}
VERSION_TYPE=${2:-build}

echo -e "${GREEN}🚀 开始构建 Flutter APK...${NC}"

# 检查Flutter是否可用
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter 命令未找到，请确保Flutter已安装并添加到PATH${NC}"
    exit 1
fi

# 更新版本号
if [ "$VERSION_TYPE" != "none" ]; then
    echo -e "${YELLOW}📝 更新版本号 ($VERSION_TYPE)...${NC}"
    dart scripts/version_update.dart $VERSION_TYPE
fi

# 清理项目
echo -e "${YELLOW}🧹 清理项目...${NC}"
flutter clean

# 获取依赖
echo -e "${YELLOW}📦 获取依赖...${NC}"
flutter pub get

# 生成图标
echo -e "${YELLOW}🎨 生成应用图标...${NC}"
flutter pub run flutter_launcher_icons:main

# 构建APK
echo -e "${YELLOW}🔨 构建 $BUILD_TYPE APK...${NC}"
if [ "$BUILD_TYPE" = "debug" ]; then
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
else
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
fi

# 检查构建结果
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ APK 构建成功！${NC}"
    echo -e "${GREEN}📱 APK 路径: $APK_PATH${NC}"
    echo -e "${GREEN}📏 APK 大小: $APK_SIZE${NC}"
    
    # 显示版本信息
    VERSION=$(grep "version:" pubspec.yaml | cut -d' ' -f2)
    echo -e "${GREEN}🏷️  版本号: $VERSION${NC}"
else
    echo -e "${RED}❌ APK 构建失败！${NC}"
    exit 1
fi
