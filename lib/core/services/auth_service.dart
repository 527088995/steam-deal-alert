import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants.dart';
import '../storage_service.dart';

/// 登录服务：Google Sign-In，不强制登录；登录后可收藏愿望单
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StorageService _storage = StorageService.instance;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google {
    _googleSignIn ??= () {
      final id = AppConstants.googleSignInClientId;
      if (kDebugMode) {
        // 便于排查：确认 App 使用的 Web Client ID 与 Cloud 一致
        debugPrint('GoogleSignIn serverClientId(前30字符): ${id.length >= 30 ? id.substring(0, 30) : id}...');
      }
      return GoogleSignIn(
        serverClientId: id,
        scopes: ['email', 'profile'],
      );
    }();
    return _googleSignIn!;
  }

  Future<bool> isLoggedIn() async => await _storage.isLoggedIn();

  /// 返回当前用户 { userId, email, photoUrl }，未登录返回 null
  Future<Map<String, String>?> getCurrentUser() async {
    final ok = await _storage.isLoggedIn();
    if (!ok) return null;
    final map = await _storage.getAuthUser();
    return map.isEmpty ? null : map;
  }

  /// 最近一次登录失败原因（供 UI 提示）
  static String? lastSignInError;

  /// Google 登录：成功后写入 Storage；失败时 lastSignInError 有说明
  Future<Map<String, String>?> signInWithGoogle() async {
    lastSignInError = null;
    try {
      final account = await _google.signIn();
      if (account == null) return null;
      final userId = account.id;
      final email = account.email;
      final photoUrl = account.photoUrl;
      if (userId == null || userId.isEmpty) return null;
      await _storage.setAuthUser(
        userId: userId,
        email: email,
        photoUrl: photoUrl,
      );
      return await _storage.getAuthUser();
    } catch (e) {
      lastSignInError = _messageForSignInError(e);
      rethrow;
    }
  }

  static String _messageForSignInError(dynamic e) {
    final s = e.toString();
    // 提取错误码便于确认（10=开发者配置错误）
    final code10 = RegExp(r'ApiException:\s*10');
    final code7 = RegExp(r'ApiException:\s*7');
    if (code10.hasMatch(s) || (s.contains('sign_in_failed') && s.contains('10'))) {
      return '登录失败（错误码 10）：本机 SHA-1 与控制台不一致。请在项目运行 signingReport 核对，见 docs/GOOGLE_SIGNIN_SETUP.md';
    }
    if (code7.hasMatch(s)) return '登录失败（错误码 7）：网络或 Play 服务异常，请检查网络后重试';
    if (s.contains('12501') || s.contains('canceled')) return '已取消登录';
    return s.length > 80 ? '${s.substring(0, 80)}…' : s;
  }

  /// 登出：清除本地用户信息并调用 Google signOut
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _storage.clearAuthUser();
  }
}
