import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _authToken;
  bool _isRemoteSession = false;
  bool _isLoggedIn = false;

  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get authToken => _authToken;
  bool get isRemoteSession => _isRemoteSession;
  bool get isLoggedIn => _isLoggedIn;

  void setUser(
    int id,
    String name,
    String email, {
    String? token,
    bool isRemoteSession = false,
  }) {
    _userId = id;
    _userName = name;
    _userEmail = email;
    _authToken = token;
    _isRemoteSession = isRemoteSession;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _userName = null;
    _userEmail = null;
    _authToken = null;
    _isRemoteSession = false;
    _isLoggedIn = false;
    notifyListeners();
  }
}
