import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../widgets/app_top_bar.dart';
import 'invite_dialog.dart';

const _roleLabels = {
  'adm': 'Admin',
  'tutor': 'Tutor',
  'visualizador': 'Visualizador',
};

class ManageAccessScreen extends StatefulWidget {
  final int babyId;
  final String babyName;

  const ManageAccessScreen({super.key, required this.babyId, required this.babyName});

  @override
  State<ManageAccessScreen> createState() => _ManageAccessScreenState();
}

class _ManageAccessScreenState extends State<ManageAccessScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getBabyUsers(widget.babyId);
      if (result['status'] == 200) {
        setState(() => _users = result['data']);
      } else {
        setState(() => _error = result['data']['message'] ?? 'Não foi possível carregar o acesso.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _invite() {
    return showInviteDialog(
      context,
      onSubmit: (username, role, title) async {
        final result = await ApiService.createInvite(widget.babyId, username, role, title: title);
        if (result['status'] == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Convite enviado pra @$username!')),
            );
          }
          return null;
        }
        return result['data']['message'] ?? 'Não foi possível enviar o convite.';
      },
    );
  }

  Future<void> _editAccess(Map<String, dynamic> user) {
    return showEditAccessDialog(
      context,
      name: user['name'],
      username: user['username'],
      initialRole: user['role'],
      initialTitle: user['title'],
      onSubmit: (role, title) async {
        final result = await ApiService.updateBabyUser(widget.babyId, user['user_id'], role: role, title: title);
        if (result['status'] == 200) {
          await _fetchUsers();
          return null;
        }
        return result['data']['message'] ?? 'Não foi possível salvar.';
      },
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text('Remover ${user['name']}?', style: Theme.of(ctx).textTheme.titleMedium),
        content: Text(
          'Essa pessoa perde o acesso a ${widget.babyName} imediatamente.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.primaryT)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: AppColors.dangerT)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final status = await ApiService.removeBabyUser(widget.babyId, user['user_id']);
    if (status == 204) {
      _fetchUsers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o acesso dessa pessoa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Acesso a ${widget.babyName}', showProfileAction: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.sp4),
                    children: [
                      for (final user in _users) _buildUserCard(user),
                      const SizedBox(height: AppSpacing.sp4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _invite,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Convidar pessoa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryS,
                            foregroundColor: AppColors.primaryT,
                            side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], style: AppTypography.bodyMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
                Text('@${user['username']}', style: AppTypography.labelSmall),
                const SizedBox(height: AppSpacing.sp2),
                Wrap(
                  spacing: AppSpacing.sp2,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryS,
                        borderRadius: BorderRadius.circular(AppShapes.radiusFull),
                        border: Border.all(color: AppColors.primaryB),
                      ),
                      child: Text(
                        _roleLabels[user['role']] ?? user['role'],
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primaryT),
                      ),
                    ),
                    if (user['title'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppShapes.radiusFull),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Text(user['title'], style: AppTypography.labelSmall),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.inkSoft),
            onPressed: () => _editAccess(user),
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined, color: AppColors.dangerT),
            onPressed: () => _confirmRemove(user),
          ),
        ],
      ),
    );
  }
}
