import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';

/// Permite navegar a partir de código sem BuildContext (ex: dentro do
/// ApiService, quando a sessão expira no meio de uma chamada). O
/// MaterialApp registra este navigatorKey; a partir daí, qualquer lugar
/// do app pode empurrar uma rota usando a raiz do Navigator, sem precisar
/// receber um context local.
class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void goToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
