import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsProvider extends ChangeNotifier {
  Map<String, dynamic>? _contact;

  Map<String, dynamic>? get contact => _contact;
  bool get hasContact => _contact != null;

  EmergencyContactsProvider() {
    _loadContact();
  }

  // 从本地存储加载联系人
  Future<void> _loadContact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('emergencyContactName');
      final phone = prefs.getString('emergencyContactPhone');
      final avatarPath = prefs.getString('emergencyContactAvatar');
      
      if (name != null && phone != null) {
        _contact = {
          'name': name,
          'phone': phone,
          'avatarPath': avatarPath,
        };
        notifyListeners();
      }
    } catch (e) {
      print('Failed to load emergency contact: $e');
    }
  }

  // 保存联系人到本地存储
  Future<void> saveContact(String name, String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergencyContactName', name);
      await prefs.setString('emergencyContactPhone', phone);
      
      _contact = {
        'name': name,
        'phone': phone,
        'avatarPath': _contact?['avatarPath'],
      };
      notifyListeners();
    } catch (e) {
      print('Failed to save emergency contact: $e');
    }
  }
  
  // 保存头像路径到本地存储
  Future<void> saveAvatar(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergencyContactAvatar', path);
      
      if (_contact != null) {
        _contact = {
          ..._contact!,
          'avatarPath': path,
        };
        notifyListeners();
      }
    } catch (e) {
      print('Failed to save avatar: $e');
    }
  }

  // 删除联系人
  Future<void> deleteContact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('emergencyContactName');
      await prefs.remove('emergencyContactPhone');
      await prefs.remove('emergencyContactAvatar');
      
      _contact = null;
      notifyListeners();
    } catch (e) {
      print('Failed to delete emergency contact: $e');
    }
  }

  // 格式化手机号显示
  String formatPhone(String phone) {
    if (phone.length != 11) {
      return phone;
    }
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }
}