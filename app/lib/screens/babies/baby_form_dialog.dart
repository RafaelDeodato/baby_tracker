import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';

/// Dialog de cadastro/edição de bebê, compartilhado entre "Novo bebê"
/// (BabiesScreen) e "Editar bebê" (BabyProfileTab) — os dois formulários
/// são idênticos, só muda o título e o que acontece ao salvar.
///
/// Implementado como StatefulWidget (não StatefulBuilder + dispose
/// manual) de propósito: o TextEditingController só pode ser descartado
/// quando o Element do dialog é realmente desmontado — o que só
/// acontece depois da animação de saída terminar. Descartar manualmente
/// assim que o Future de showDialog resolve (no Navigator.pop, ANTES da
/// transição terminar) faz o Flutter tentar reconstruir o TextField por
/// mais alguns frames da animação com um controller já descartado,
/// derrubando com "TextEditingController was used after being disposed".
Future<void> showBabyFormDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  DateTime? initialDate,
  required Future<bool> Function(String name, String birthDateIso) onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _BabyFormDialog(
      title: title,
      initialName: initialName,
      initialDate: initialDate,
      onSubmit: onSubmit,
    ),
  );
}

class _BabyFormDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final DateTime? initialDate;
  final Future<bool> Function(String name, String birthDateIso) onSubmit;

  const _BabyFormDialog({
    required this.title,
    required this.initialName,
    required this.initialDate,
    required this.onSubmit,
  });

  @override
  State<_BabyFormDialog> createState() => _BabyFormDialogState();
}

class _BabyFormDialogState extends State<_BabyFormDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late DateTime? _selectedDate = widget.initialDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _dateLabel => _selectedDate == null
      ? 'Data nascimento'
      : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2024),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _selectedDate == null) return;
    final birthDate =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final ok = await widget.onSubmit(_nameController.text.trim(), birthDate);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      title: Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.sp4),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
                border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
              ),
              child: Text(
                _dateLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _selectedDate == null ? AppColors.inkSoft : AppColors.ink,
                  height: 1.0,
                ),
              ),
            ),
          ),
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
    );
  }
}
