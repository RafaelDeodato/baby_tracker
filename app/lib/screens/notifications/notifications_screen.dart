import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_top_bar.dart';

const _roleLabels = {
  'adm': 'administrador(a)',
  'tutor': 'tutor(a)',
  'visualizador': 'visualizador(a)',
};

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = [];
  final Set<int> _resolving = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getNotifications();
      if (result['status'] == 200) {
        setState(() => _notifications = result['data']);
      } else {
        setState(() => _error = 'Não foi possível carregar as notificações.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true) return;
    await ApiService.markNotificationRead(notification['id']);
    if (mounted) setState(() => notification['read'] = true);
  }

  Future<void> _respondToInvite(Map<String, dynamic> notification, bool accept) async {
    final invite = notification['invite'];
    final inviteId = invite['id'] as int;
    setState(() => _resolving.add(inviteId));
    try {
      final result = accept
          ? await ApiService.acceptInvite(inviteId)
          : await ApiService.declineInvite(inviteId);
      if (result['status'] == 200) {
        await _markRead(notification);
        setState(() => notification['invite']['status'] = accept ? 'accepted' : 'declined');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(accept ? 'Convite aceito!' : 'Convite recusado.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['data']['message'] ?? 'Não foi possível responder ao convite.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão.')),
        );
      }
    } finally {
      setState(() => _resolving.remove(inviteId));
    }
  }

  String _describe(Map<String, dynamic> notification) {
    final invite = notification['invite'];
    final babyName = invite?['baby']?['name'] ?? 'um bebê';
    final role = _roleLabels[invite?['role']] ?? invite?['role'] ?? '';

    switch (notification['type']) {
      case 'baby_invite_received':
        final inviter = invite?['invited_by']?['name'] ?? 'Alguém';
        return '$inviter te convidou pra $babyName como $role.';
      case 'baby_invite_accepted':
        final invited = invite?['invited_user']?['name'] ?? 'A pessoa';
        return '$invited aceitou seu convite pra $babyName como $role.';
      case 'baby_invite_declined':
        final invited = invite?['invited_user']?['name'] ?? 'A pessoa';
        return '$invited recusou seu convite pra $babyName.';
      case 'baby_access_updated':
        final access = notification['access'];
        final accessBabyName = access?['baby']?['name'] ?? 'um bebê';
        final accessRole = _roleLabels[access?['role']] ?? access?['role'] ?? '';
        return 'Seu acesso a $accessBabyName agora é $accessRole.';
      default:
        return 'Notificação.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Notificações'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: _notifications.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: Text(
                                  'Nenhuma notificação por aqui.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.sp4),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sp3),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index] as Map<String, dynamic>;
                          final invite = notification['invite'];
                          final isPendingInvite = notification['type'] == 'baby_invite_received' &&
                              invite != null &&
                              invite['status'] == 'pending';
                          final resolving = invite != null && _resolving.contains(invite['id']);
                          final isUnread = notification['read'] == false;

                          return InkWell(
                            onTap: () => _markRead(notification),
                            borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sp4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
                                border: Border.all(
                                  color: isUnread ? AppColors.primaryB : AppColors.outline,
                                  width: AppShapes.borderRegular,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _describe(notification),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                                    ),
                                  ),
                                  if (invite?['title'] != null) ...[
                                    const SizedBox(height: AppSpacing.sp2),
                                    Text(
                                      'Título sugerido: "${invite['title']}"',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                                    ),
                                  ],
                                  if (isPendingInvite) ...[
                                    const SizedBox(height: AppSpacing.sp3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: resolving ? null : () => _respondToInvite(notification, false),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.dangerT,
                                              side: const BorderSide(color: AppColors.dangerB),
                                              minimumSize: const Size.fromHeight(44),
                                            ),
                                            child: const Text('Recusar'),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sp3),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: resolving ? null : () => _respondToInvite(notification, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.successS,
                                              foregroundColor: AppColors.successT,
                                              side: const BorderSide(color: AppColors.successB),
                                              minimumSize: const Size.fromHeight(44),
                                            ),
                                            child: resolving
                                                ? const SizedBox(
                                                    height: 16, width: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Text('Aceitar'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (invite != null && invite['status'] != 'pending') ...[
                                    const SizedBox(height: AppSpacing.sp2),
                                    Text(
                                      invite['status'] == 'accepted' ? 'Aceito' : 'Recusado',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
