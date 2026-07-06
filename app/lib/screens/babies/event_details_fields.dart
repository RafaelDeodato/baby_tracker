import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Seletor de opções em formato de chip, usado pelos campos de
/// complementação de dados (V3) — mesma família visual dos botões e
/// cards de evento (borda + preenchimento na cor da família quando
/// selecionado).
class ChipSelector extends StatelessWidget {
  final String label;
  final List<(String value, String text)> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color familyBorder;
  final Color familySurface;
  final Color familyText;

  const ChipSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.familyBorder,
    required this.familySurface,
    required this.familyText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.sp2),
        Wrap(
          spacing: AppSpacing.sp2,
          runSpacing: AppSpacing.sp2,
          children: options.map((opt) {
            final isSelected = selected == opt.$1;
            return GestureDetector(
              onTap: () => onSelected(opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? familySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppShapes.radiusFull),
                  border: Border.all(
                    color: isSelected ? familyBorder : AppColors.outline,
                    width: AppShapes.borderRegular,
                  ),
                ),
                child: Text(
                  opt.$2,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? familyText : AppColors.ink,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Campos de complementação de dados (V3) de mamada/soneca/fralda.
/// Usado tanto na tela de Status (evento em andamento, salva a cada
/// seleção) quanto no dialog de editar do Histórico (evento já
/// finalizado, salva ao confirmar) — o widget só desenha os campos e
/// avisa mudanças via [onChanged]; quem chama decide quando persistir.
class EventDetailsFields extends StatelessWidget {
  final String eventType; // 'feeding' | 'nap' | 'diaper'
  final Map<String, dynamic> values;
  final void Function(String field, dynamic value) onChanged;

  const EventDetailsFields({
    super.key,
    required this.eventType,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return switch (eventType) {
      'feeding' => _feedingFields(),
      'nap' => _napFields(),
      _ => _diaperFields(),
    };
  }

  Widget _noteField(String initial) {
    // Salva ao perder o foco (tocar fora) em vez de a cada tecla — evita
    // uma chamada de API por caractere digitado.
    String draft = initial;
    return TextFormField(
      initialValue: initial,
      decoration: const InputDecoration(labelText: 'Observação (opcional)'),
      maxLines: 2,
      onChanged: (v) => draft = v,
      onFieldSubmitted: (v) => onChanged('note', v),
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        onChanged('note', draft);
      },
    );
  }

  Widget _volumeField(String initial) {
    String draft = initial;
    return TextFormField(
      initialValue: initial,
      decoration: const InputDecoration(labelText: 'Volume (ml)'),
      keyboardType: TextInputType.number,
      onChanged: (v) => draft = v,
      onFieldSubmitted: (v) => onChanged('volume_ml', int.tryParse(v)),
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        onChanged('volume_ml', int.tryParse(draft));
      },
    );
  }

  Widget _feedingFields() {
    final feedingType = values['type'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipSelector(
          label: 'Tipo',
          options: const [
            ('peito', 'Peito'),
            ('formula', 'Mamadeira (fórmula)'),
            ('ordenhado', 'Mamadeira (leite ordenhado)'),
          ],
          selected: feedingType,
          onSelected: (v) => onChanged('type', v),
          familyBorder: AppColors.feedB,
          familySurface: AppColors.feedS,
          familyText: AppColors.feedT,
        ),
        if (feedingType == 'peito') ...[
          const SizedBox(height: AppSpacing.sp4),
          ChipSelector(
            label: 'Lado',
            options: const [('esquerdo', 'Esquerdo'), ('direito', 'Direito'), ('ambos', 'Ambos')],
            selected: values['side'],
            onSelected: (v) => onChanged('side', v),
            familyBorder: AppColors.feedB,
            familySurface: AppColors.feedS,
            familyText: AppColors.feedT,
          ),
        ],
        if (feedingType == 'formula' || feedingType == 'ordenhado') ...[
          const SizedBox(height: AppSpacing.sp4),
          _volumeField(values['volume_ml']?.toString() ?? ''),
        ],
        const SizedBox(height: AppSpacing.sp4),
        _noteField(values['note'] ?? ''),
      ],
    );
  }

  Widget _napFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipSelector(
          label: 'Local do sono',
          options: const [
            ('berco', 'Berço'),
            ('colo', 'Colo'),
            ('carrinho', 'Carrinho'),
            ('cama_dos_pais', 'Cama dos pais'),
            ('carro', 'Carro (bebê conforto)'),
          ],
          selected: values['location'],
          onSelected: (v) => onChanged('location', v),
          familyBorder: AppColors.napB,
          familySurface: AppColors.napS,
          familyText: AppColors.napT,
        ),
        const SizedBox(height: AppSpacing.sp4),
        ChipSelector(
          label: 'Ambiente',
          options: const [('claro', 'Claro'), ('escuro', 'Escuro')],
          selected: values['light_environment'],
          onSelected: (v) => onChanged('light_environment', v),
          familyBorder: AppColors.napB,
          familySurface: AppColors.napS,
          familyText: AppColors.napT,
        ),
        const SizedBox(height: AppSpacing.sp4),
        ChipSelector(
          label: 'Ruído branco',
          options: const [('true', 'Sim'), ('false', 'Não')],
          selected: values['white_noise']?.toString(),
          onSelected: (v) => onChanged('white_noise', v == 'true'),
          familyBorder: AppColors.napB,
          familySurface: AppColors.napS,
          familyText: AppColors.napT,
        ),
        const SizedBox(height: AppSpacing.sp4),
        _noteField(values['note'] ?? ''),
      ],
    );
  }

  Widget _diaperFields() {
    final diaperType = values['type'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipSelector(
          label: 'Tipo',
          options: const [('urina', 'Só urina'), ('fezes', 'Só fezes'), ('ambos', 'Ambos')],
          selected: diaperType,
          onSelected: (v) => onChanged('type', v),
          familyBorder: AppColors.diaperB,
          familySurface: AppColors.diaperS,
          familyText: AppColors.diaperT,
        ),
        if (diaperType == 'fezes' || diaperType == 'ambos') ...[
          const SizedBox(height: AppSpacing.sp4),
          ChipSelector(
            label: 'Consistência',
            options: const [('liquida', 'Líquida'), ('pastosa', 'Pastosa'), ('solida', 'Sólida')],
            selected: values['consistency'],
            onSelected: (v) => onChanged('consistency', v),
            familyBorder: AppColors.diaperB,
            familySurface: AppColors.diaperS,
            familyText: AppColors.diaperT,
          ),
        ],
        const SizedBox(height: AppSpacing.sp4),
        _noteField(values['note'] ?? ''),
      ],
    );
  }
}
