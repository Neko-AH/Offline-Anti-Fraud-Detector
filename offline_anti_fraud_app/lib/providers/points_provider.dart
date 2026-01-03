import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PointsProvider extends ChangeNotifier {
  int _points = 0;

  int get points => _points;

  PointsProvider() {
    _loadPoints();
  }

  // 从本地存储加载积分
  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('points') ?? 0;
    notifyListeners();
  }

  // 增加积分
  Future<void> addPoints(int points) async {
    _points += points;
    notifyListeners();
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', _points);
  }

  // 设置积分
  Future<void> setPoints(int points) async {
    _points = points;
    notifyListeners();
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', _points);
  }
}
