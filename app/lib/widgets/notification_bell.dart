import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../screens/notifications/notifications_screen.dart';

/// Sino de notificações da AppTopBar — mostra um indicador quando há
/// notificação não lida e abre a caixa de entrada ao tocar.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final result = await ApiService.getNotifications();
      if (result['status'] == 200 && mounted) {
        final notifications = result['data'] as List<dynamic>;
        setState(() => _hasUnread = notifications.any((n) => n['read'] == false));
      }
    } catch (_) {
      // Falha silenciosa — o sino simplesmente não mostra indicador.
    }
  }

  Future<void> _openInbox() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    _fetchUnread();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        isLabelVisible: _hasUnread,
        backgroundColor: AppColors.dangerB,
        smallSize: 10,
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: _openInbox,
    );
  }
}
