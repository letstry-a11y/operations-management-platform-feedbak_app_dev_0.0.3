import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? id;
  String? email;
  String? username;
  String? fullName;
  String? role;
  String? organization;
  String? country;
  String? whatsapp;
  Map<String, dynamic>? _profile;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get profile => _profile;

  bool get isLoggedIn => _token != null;
  // 更新用户信息
  void updateFromMap(Map<String, dynamic> data) async {
    id = data['id'];
    email = data['email'];
    username = data['username'];
    fullName = data['full_name'];
    role = data['role'];
    organization = data['organization'];
    country = data['country'];
    whatsapp = data['whatsapp'];

    _profile = toMap(); // 保持 profile 一致

    notifyListeners();

    // 更新本地缓存中的 user 字符串
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(toMap()));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'role': role,
    'organization': organization,
    'country': country,
    'whatsapp': whatsapp,
  };

  Future<void> setToken(String token) async {
    _token = token;
    HttpService().setToken(token);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    HttpService().setRefreshToken(token);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refreshToken', token);
  }

  Future<void> setAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    HttpService().setToken(accessToken);
    HttpService().setRefreshToken(refreshToken);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<void> setProfile(Map<String, dynamic> profile) async {
    _profile = profile;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(profile));
  }

  Future<void> setUser(String token, Map<String, dynamic> profile) async {
    _token = token;
    _profile = profile;
    HttpService().setToken(token);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(profile));
  }

  void clearUser() async {
    _token = null;
    _refreshToken = null;
    _profile = null;
    id = null;
    email = null;
    username = null;
    fullName = null;
    role = null;
    organization = null;
    country = null;
    whatsapp = null;
    HttpService().clearToken();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('refreshToken');
    prefs.remove('user');
  }

  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refreshToken');
    final userStr = prefs.getString('user');

    var changed = false;

    if (token != null && token.isNotEmpty) {
      _token = token;
      HttpService().setToken(token);
      changed = true;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      HttpService().setRefreshToken(refreshToken);
      changed = true;
    }

    if (userStr != null && userStr.isNotEmpty) {
      _profile = jsonDecode(userStr);
      changed = true;
    }

    if (changed) notifyListeners();
  }
}
