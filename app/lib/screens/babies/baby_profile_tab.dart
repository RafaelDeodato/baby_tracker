import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import 'baby_form_dialog.dart';
import 'manage_access_screen.dart';

class BabyProfileTab extends StatefulWidget {
  final Map<String, dynamic> baby;
  final void Function(Map<String, dynamic> updatedBaby) onUpdated;

  const BabyProfileTab({super.key, required this.baby, required this.onUpdated});

  @override
  State<BabyProfileTab> createState() => _BabyProfileTabState();
}

class _BabyProfileTabState extends State<BabyProfileTab> {
  late Map<String, dynamic> _baby = widget.baby;
  bool _deleting = false;

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _editBaby() async {
    Map<String, dynamic>? updated;
    await showBabyFormDialog(
      context,
      title: 'Editar bebê',
      initialName: _baby['name'],
      initialDate: DateTime.parse(_baby['birth_date']),
      onSubmit: (name, birthDate) async {
        final result = await ApiService.updateBaby(_baby['id'], name, birthDate);
        if (result['status'] == 200) {
          updated = result['data'];
          return true;
        }
        return false;
      },
    );
    // Só mexe no estado depois que o dialog já fechou de vez — ver
    // manage_access_screen.dart pra mais contexto sobre o crash que
    // esse padrão evita.
    if (updated != null) {
      setState(() => _baby = updated!);
      widget.onUpdated(updated!);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text('Excluir ${_baby['name']}?', style: Theme.of(ctx).textTheme.titleMedium),
        content: Text(
          'Todas as mamadas e sonecas registradas serão excluídas junto. Essa ação não pode ser desfeita.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.primaryT)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.dangerT)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    final status = await ApiService.deleteBaby(_baby['id']);
    if (status == 204 && mounted) {
      Navigator.pop(context);
    } else {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _baby['role'] == 'adm';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sp6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
              border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👶', style: TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.sp4),
                Text(_baby['name'], style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sp2),
                Text(
                  'Nascimento: ${_formatDate(_baby['birth_date'])}',
                  style: AppTypography.bodyMedium,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.sp6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageAccessScreen(babyId: _baby['id'], babyName: _baby['name']),
                        ),
                      ),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Gerenciar acesso'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryT,
                        side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShapes.radiusMedium)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.sp8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _deleting ? null : _editBaby,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryT,
                        side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShapes.radiusMedium)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Editar bebê'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleting ? null : _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerS,
                        foregroundColor: AppColors.dangerT,
                        side: const BorderSide(color: AppColors.dangerB, width: AppShapes.borderRegular),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _deleting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Excluir bebê'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
