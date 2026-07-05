import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

Widget _pill(BuildContext ctx, {required String text, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
        border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      alignment: Alignment.center,
      child: Text(text, style: Theme.of(ctx).textTheme.bodyLarge),
    ),
  );
}

/// Dialog de edição de horário de mamada/soneca — usado no Histórico.
/// Data e hora são pílulas independentes (edita só o que precisa, sem
/// reconfirmar os dois toda vez). Se [initialEndedAt] for null (evento
/// ainda em andamento), só o horário de início fica editável.
Future<void> showEventEditDialog(
  BuildContext context, {
  required String title,
  String startLabel = 'Início',
  required DateTime initialStartedAt,
  DateTime? initialEndedAt,
  required Future<String?> Function(DateTime startedAt, DateTime? endedAt) onSubmit,
}) async {
  DateTime startedAt = initialStartedAt;
  DateTime? endedAt = initialEndedAt;
  final canEditEnd = initialEndedAt != null;
  String? errorText;

  Future<void> pickDate(StateSetter setDialogState, BuildContext ctx, bool isStart) async {
    final current = isStart ? startedAt : endedAt!;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setDialogState(() {
      final updated = DateTime(picked.year, picked.month, picked.day, current.hour, current.minute);
      if (isStart) {
        startedAt = updated;
      } else {
        endedAt = updated;
      }
    });
  }

  Future<void> pickTime(StateSetter setDialogState, BuildContext ctx, bool isStart) async {
    final current = isStart ? startedAt : endedAt!;
    final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(current));
    if (picked == null) return;
    setDialogState(() {
      final updated = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
      if (isStart) {
        startedAt = updated;
      } else {
        endedAt = updated;
      }
    });
  }

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(startLabel, style: AppTypography.labelSmall),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _pill(ctx, text: _formatDate(startedAt), onTap: () => pickDate(setDialogState, ctx, true)),
                  ),
                  const SizedBox(width: AppSpacing.sp2),
                  Expanded(
                    flex: 2,
                    child: _pill(ctx, text: _formatTime(startedAt), onTap: () => pickTime(setDialogState, ctx, true)),
                  ),
                ],
              ),
              if (canEditEnd) ...[
                const SizedBox(height: AppSpacing.sp4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Fim', style: AppTypography.labelSmall),
                ),
                const SizedBox(height: AppSpacing.sp2),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _pill(ctx, text: _formatDate(endedAt!), onTap: () => pickDate(setDialogState, ctx, false)),
                    ),
                    const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      flex: 2,
                      child: _pill(ctx, text: _formatTime(endedAt!), onTap: () => pickTime(setDialogState, ctx, false)),
                    ),
                  ],
                ),
              ],
              if (errorText != null) ...[
                const SizedBox(height: AppSpacing.sp4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sp3),
                  decoration: BoxDecoration(
                    color: AppColors.dangerS,
                    borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                    border: Border.all(color: AppColors.dangerB),
                  ),
                  child: Text(errorText!, style: AppTypography.bodyMedium.copyWith(color: AppColors.dangerT)),
                ),
              ],
              const SizedBox(height: AppSpacing.sp6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final error = await onSubmit(startedAt, endedAt);
                    if (error == null && ctx.mounted) {
                      Navigator.pop(ctx);
                    } else {
                      setDialogState(() => errorText = error);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryS,
                    foregroundColor: AppColors.primaryT,
                    side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                    elevation: 0,
                  ),
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sp3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryT,
                    side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShapes.radiusFull)),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
