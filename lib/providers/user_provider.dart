import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class UserProvider extends ChangeNotifier {
  String? _name;
  final HiveService _hiveService = HiveService();

  UserProvider() {
    _loadName();
  }

  String? get name => _name;

  void _loadName() {
    _name = _hiveService.getUserName();
    notifyListeners();
  }

  Future<void> setName(String name) async {
    _name = name;
    await _hiveService.saveUserName(name);
    notifyListeners();
  }
}
