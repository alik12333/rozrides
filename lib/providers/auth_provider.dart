import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? currentUser;
  String? errorMessage;
  AuthStatus status = AuthStatus.idle;

  get firebaseUser => _authService.currentUser;

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? cnicNumber,
    File? cnicFront,
    File? cnicBack,
  }) async {
    try {
      status = AuthStatus.loading;
      notifyListeners();

      final cred = await _authService.signUpWithEmail(email: email, password: password);

      await _authService.createUserProfile(
        userId: cred.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        cnicNumber: cnicNumber,
        cnicFront: cnicFront,
        cnicBack: cnicBack,
      );

      await loadUserProfile(cred.user!.uid);

      status = AuthStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    try {
      status = AuthStatus.loading;
      notifyListeners();

      final cred = await _authService.signInWithEmail(email: email, password: password);
      await loadUserProfile(cred.user!.uid);

      status = AuthStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      currentUser = await _authService.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUser == null) return;
    await _authService.updateUserProfile(currentUser!.id, updates);
    await loadUserProfile(currentUser!.id);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    currentUser = null;
    notifyListeners();
  }
}
