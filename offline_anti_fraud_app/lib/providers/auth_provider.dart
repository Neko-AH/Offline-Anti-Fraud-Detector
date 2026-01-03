import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userId = '';
  String _phoneNumber = '123****56'; // 默认手机号

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get phoneNumber => _phoneNumber;

  // 格式化手机号显示（中间4位用*替换）
  String get formattedPhoneNumber {
    if (_phoneNumber.isEmpty || _phoneNumber.length != 11) {
      return _phoneNumber;
    }
    return '${_phoneNumber.substring(0, 3)}****${_phoneNumber.substring(7)}';
  }

  // 获取完整手机号（用于设置页面显示）
  String get fullPhoneNumber => _phoneNumber;

  // 初始化登录状态
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // 默认设置为未登录状态
      _userId = prefs.getString('userId') ?? '123456';
      _phoneNumber = prefs.getString('phoneNumber') ?? '123****56';
      notifyListeners();
    } catch (e) {
      print('Failed to initialize auth provider: $e');
    }
  }

  // 登录
  Future<bool> login(String phoneNumber, String password) async {
    try {
      // 固定的手机号和密码组合验证
      // 只有手机号为"123456"，密码为"123456"才能登录
      print('Login attempt: phone=$phoneNumber, password=$password');
      
      if (phoneNumber == '123456' && password == '123456') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', phoneNumber);
        await prefs.setString('phoneNumber', '123****56');
        
        _isLoggedIn = true;
        _userId = phoneNumber;
        _phoneNumber = '123****56';
        notifyListeners();
        print('Login successful');
        return true;
      } else {
        print('Login failed: invalid credentials');
        return false;
      }
    } catch (e) {
      print('Failed to login: $e');
      return false;
    }
  }

  // 退出登录
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('phoneNumber');
      
      _isLoggedIn = false;
      _userId = '';
      _phoneNumber = '123****56';
      notifyListeners();
    } catch (e) {
      print('Failed to logout: $e');
    }
  }

  // 更新手机号
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phoneNumber', phoneNumber);
      await prefs.setString('userId', phoneNumber); // 同时更新用户ID
      _phoneNumber = phoneNumber;
      _userId = phoneNumber; // 同时更新用户ID
      notifyListeners();
    } catch (e) {
      print('Failed to update phone number: $e');
    }
  }
}
