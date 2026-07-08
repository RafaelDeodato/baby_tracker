import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'event_details_fields.dart';

const roleOptions = <(String, String)>[
  ('adm', 'Admin'),
  ('tutor', 'Tutor'),
  ('visualizador', 'Visualizador'),
];

/// Dialog de convite de acesso a um bebê por @username — usado na tela
/// de Gerenciar acesso. onSubmit devolve uma mensagem de erro (pra
/// mostrar no próprio dialog) ou null quando dá certo.
Future<void> showInviteDialog(
  BuildContext context, {
  required Future<String?> Function(String username, String role, String? title) onSubmit,
}) async {
  final usernameController = TextEditingController();
  final titleController = TextEditingController();
  String role = 'tutor';
  String? errorText;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text('Convidar pessoa', style: Theme.of(ctx).textTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Nome de usuário', prefixText: '@'),
              ),
              const SizedBox(height: AppSpacing.sp4),
              ChipSelector(
                label: 'Nível de permissão',
                options: roleOptions,
                selected: role,
                onSelected: (value) => setDialogState(() => role = value),
                familyBorder: AppColors.primaryB,
                familySurface: AppColors.primaryS,
                familyText: AppColors.primaryT,
              ),
              const SizedBox(height: AppSpacing.sp4),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título (opcional)', hintText: 'Ex: Vovó, Tio, Amiga'),
              ),
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
                    final username = usernameController.text.trim();
                    if (username.isEmpty) {
                      setDialogState(() => errorText = 'Informe o nome de usuário.');
                      return;
                    }
                    final title = titleController.text.trim();
                    final error = await onSubmit(username, role, title.isEmpty ? null : title);
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
                  child: const Text('Enviar convite'),
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

  usernameController.dispose();
  titleController.dispose();
}

/// Dialog de edição de papel/título de quem já tem acesso ao bebê.
Future<void> showEditAccessDialog(
  BuildContext context, {
  required String name,
  required String username,
  required String initialRole,
  String? initialTitle,
  required Future<String?> Function(String role, String? title) onSubmit,
}) async {
  final titleController = TextEditingController(text: initialTitle ?? '');
  String role = initialRole;
  String? errorText;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text('$name (@$username)', style: Theme.of(ctx).textTheme.titleMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChipSelector(
                label: 'Nível de permissão',
                options: roleOptions,
                selected: role,
                onSelected: (value) => setDialogState(() => role = value),
                familyBorder: AppColors.primaryB,
                familySurface: AppColors.primaryS,
                familyText: AppColors.primaryT,
              ),
              const SizedBox(height: AppSpacing.sp4),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título (opcional)', hintText: 'Ex: Vovó, Tio, Amiga'),
              ),
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
                    final title = titleController.text.trim();
                    final error = await onSubmit(role, title.isEmpty ? null : title);
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

  titleController.dispose();
}
