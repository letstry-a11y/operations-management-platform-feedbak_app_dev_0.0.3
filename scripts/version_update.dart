#!/usr/bin/env dart

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('用法: dart scripts/version_update.dart [major|minor|patch|build]');
    print('示例:');
    print('  dart scripts/version_update.dart patch  # 更新补丁版本 1.0.0+1 -> 1.0.1+1');
    print('  dart scripts/version_update.dart build  # 更新构建号 1.0.0+1 -> 1.0.0+2');
    exit(1);
  }

  final type = args[0];
  final pubspecFile = File('pubspec.yaml');
  
  if (!pubspecFile.existsSync()) {
    print('错误: 找不到 pubspec.yaml 文件');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)');
  final match = versionRegex.firstMatch(content);
  
  if (match == null) {
    print('错误: 无法解析版本号');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
      patch++;
      break;
    case 'build':
      build++;
      break;
    default:
      print('错误: 无效的版本类型。使用 major, minor, patch 或 build');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch+$build';
  final newContent = content.replaceFirst(versionRegex, 'version: $newVersion');
  
  pubspecFile.writeAsStringSync(newContent);
  print('版本已更新为: $newVersion');
}
