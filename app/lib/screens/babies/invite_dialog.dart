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
///
/// Implementado como StatefulWidget (não como StatefulBuilder + dispose
/// manual) de propósito: o TextEditingController precisa ser descartado
/// só quando o Element do dialog é realmente desmontado — o que só
/// acontece depois da animação de saída terminar. Se a gente descarta
/// manualmente assim que o Future de showDialog resolve (que acontece
/// no Navigator.pop, ANTES da transição terminar), o Flutter ainda tenta
/// reconstruir o TextField por mais alguns frames da animação e quebra
/// com "TextEditingController was used after being disposed".
Future<void> showInviteDialog(
  BuildContext context, {
  required Future<String?> Function(String username, String role, String? title) onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _InviteDialog(onSubmit: onSubmit),
  );
}

class _InviteDialog extends StatefulWidget {
  final Future<String?> Function(String username, String role, String? title) onSubmit;

  const _InviteDialog({required this.onSubmit});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _usernameController = TextEditingController();
  final _titleController = TextEditingController();
  String _role = 'tutor';
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorText = 'Informe o nome de usuário.');
      return;
    }
    final title = _titleController.text.trim();
    final error = await widget.onSubmit(username, _role, title.isEmpty ? null : title);
    if (error == null && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      title: Text('Convidar pessoa', style: Theme.of(context).textTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nome de usuário', prefixText: '@'),
            ),
            const SizedBox(height: AppSpacing.sp4),
            ChipSelector(
              label: 'Nível de permissão',
              options: roleOptions,
              selected: _role,
              onSelected: (value) => setState(() => _role = value),
              familyBorder: AppColors.primaryB,
              familySurface: AppColors.primaryS,
              familyText: AppColors.primaryT,
            ),
            const SizedBox(height: AppSpacing.sp4),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título (opcional)', hintText: 'Ex: Vovó, Tio, Amiga'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sp4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp3),
                decoration: BoxDecoration(
                  color: AppColors.dangerS,
                  borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                  border: Border.all(color: AppColors.dangerB),
                ),
                child: Text(_errorText!, style: AppTypography.bodyMedium.copyWith(color: AppColors.dangerT)),
              ),
            ],
            const SizedBox(height: AppSpacing.sp6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
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
                onPressed: () => Navigator.pop(context),
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
    );
  }
}

/// Dialog de edição de papel/título de quem já tem acesso ao bebê.
/// Mesmo motivo de ser StatefulWidget descrito em [showInviteDialog].
Future<void> showEditAccessDialog(
  BuildContext context, {
  required String name,
  required String username,
  required String initialRole,
  String? initialTitle,
  required Future<String?> Function(String role, String? title) onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _EditAccessDialog(
      name: name,
      username: username,
      initialRole: initialRole,
      initialTitle: initialTitle,
      onSubmit: onSubmit,
    ),
  );
}

class _EditAccessDialog extends StatefulWidget {
  final String name;
  final String username;
  final String initialRole;
  final String? initialTitle;
  final Future<String?> Function(String role, String? title) onSubmit;

  const _EditAccessDialog({
    required this.name,
    required this.username,
    required this.initialRole,
    required this.initialTitle,
    required this.onSubmit,
  });

  @override
  State<_EditAccessDialog> createState() => _EditAccessDialogState();
}

class _EditAccessDialogState extends State<_EditAccessDialog> {
  late final _titleController = TextEditingController(text: widget.initialTitle ?? '');
  late String _role = widget.initialRole;
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final error = await widget.onSubmit(_role, title.isEmpty ? null : title);
    if (error == null && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      title: Text('${widget.name} (@${widget.username})', style: Theme.of(context).textTheme.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChipSelector(
              label: 'Nível de permissão',
              options: roleOptions,
              selected: _role,
              onSelected: (value) => setState(() => _role = value),
              familyBorder: AppColors.primaryB,
              familySurface: AppColors.primaryS,
              familyText: AppColors.primaryT,
            ),
            const SizedBox(height: AppSpacing.sp4),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título (opcional)', hintText: 'Ex: Vovó, Tio, Amiga'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppSpacing.sp4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp3),
                decoration: BoxDecoration(
                  color: AppColors.dangerS,
                  borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                  border: Border.all(color: AppColors.dangerB),
                ),
                child: Text(_errorText!, style: AppTypography.bodyMedium.copyWith(color: AppColors.dangerT)),
              ),
            ],
            const SizedBox(height: AppSpacing.sp6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
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
                onPressed: () => Navigator.pop(context),
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
    );
  }
}
