import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';

/// Dialog de cadastro/edição de bebê, compartilhado entre "Novo bebê"
/// (BabiesScreen) e "Editar bebê" (BabyProfileTab) — os dois formulários
/// são idênticos, só muda o título e o que acontece ao salvar.
Future<void> showBabyFormDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  DateTime? initialDate,
  required Future<bool> Function(String name, String birthDateIso) onSubmit,
}) async {
  final nameController = TextEditingController(text: initialName);
  DateTime? selectedDate = initialDate;
  String dateLabel = initialDate == null
      ? 'Data nascimento'
      : '${initialDate.day.toString().padLeft(2, '0')}/${initialDate.month.toString().padLeft(2, '0')}/${initialDate.year}';

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: AppSpacing.sp4),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate ?? DateTime(2024),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.primaryB,
                        onPrimary: AppColors.ink,
                        onSurface: AppColors.ink,
                        surface: AppColors.surface,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: AppColors.primaryT),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setDialogState(() {
                    selectedDate = picked;
                    dateLabel = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
                  border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
                ),
                child: Text(
                  dateLabel,
                  style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: selectedDate == null ? AppColors.inkSoft : AppColors.ink,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || selectedDate == null) return;
                  final birthDate =
                      '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                  final ok = await onSubmit(nameController.text.trim(), birthDate);
                  if (ok && ctx.mounted) Navigator.pop(ctx);
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
  );

  nameController.dispose();
}
