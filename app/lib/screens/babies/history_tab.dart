import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import 'event_edit_dialog.dart';

class HistoryTab extends StatefulWidget {
  final int babyId;
  final String role;

  const HistoryTab({super.key, required this.babyId, required this.role});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const double _railWidth = 40;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];

  bool get _canEdit => widget.role == 'adm' || widget.role == 'tutor';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getFeedings(widget.babyId),
        ApiService.getNaps(widget.babyId),
        ApiService.getDiapers(widget.babyId),
      ]);
      final feedingsResult = results[0];
      final napsResult = results[1];
      final diapersResult = results[2];

      if (feedingsResult['status'] == 200 && napsResult['status'] == 200 && diapersResult['status'] == 200) {
        // 'type' já era usado aqui como discriminador de tipo de evento
        // (feeding/nap/diaper) antes do V3 existir. Mamada e fralda agora
        // também têm seu próprio campo de domínio chamado 'type' (peito/
        // fórmula/ordenhado; urina/fezes/ambos) — teria colidido e
        // sobrescrito silenciosamente um pelo outro. Renomeado pra
        // feeding_type/diaper_type antes de aplicar o discriminador.
        final events = <Map<String, dynamic>>[
          for (final f in feedingsResult['data']) {...f, 'feeding_type': f['type'], 'type': 'feeding'},
          for (final n in napsResult['data']) {...n, 'type': 'nap'},
          for (final d in diapersResult['data']) {...d, 'diaper_type': d['type'], 'type': 'diaper', 'started_at': d['changed_at']},
        ];
        events.sort((a, b) =>
            DateTime.parse(b['started_at']).compareTo(DateTime.parse(a['started_at'])));
        setState(() => _events = events);
      } else {
        setState(() => _error = 'Não foi possível carregar o histórico.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> event) async {
    final type = event['type'];
    final label = type == 'feeding' ? 'mamada' : type == 'nap' ? 'soneca' : 'troca de fralda';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
        ),
        title: Text('Excluir registro?', style: Theme.of(ctx).textTheme.titleMedium),
        content: Text(
          'Este registro de $label será excluído permanentemente.',
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

    final status = switch (type) {
      'feeding' => await ApiService.deleteFeeding(event['id']),
      'nap' => await ApiService.deleteNap(event['id']),
      _ => await ApiService.deleteDiaper(event['id']),
    };

    if (status == 204) {
      setState(() => _events.removeWhere((e) => e['id'] == event['id'] && e['type'] == event['type']));
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final type = event['type'];
    final startedAt = DateTime.parse(event['started_at']).toLocal();
    final endedAt = event['ended_at'] != null ? DateTime.parse(event['ended_at']).toLocal() : null;

    // 'type' no mapa mesclado é o discriminador (feeding/nap/diaper) — o
    // campo de domínio de mamada/fralda foi renomeado pra feeding_type/
    // diaper_type em _fetchHistory pra evitar colisão. Traduz de volta
    // pro nome que a API espera antes de abrir o dialog.
    final initialDetails = switch (type) {
      'feeding' => {
          'type': event['feeding_type'],
          'side': event['side'],
          'volume_ml': event['volume_ml'],
          'note': event['note'],
        },
      'nap' => {
          'location': event['location'],
          'light_environment': event['light_environment'],
          'white_noise': event['white_noise'],
          'note': event['note'],
        },
      _ => {
          'type': event['diaper_type'],
          'consistency': event['consistency'],
          'note': event['note'],
        },
    };

    await showEventEditDialog(
      context,
      title: switch (type) { 'feeding' => 'Editar mamada', 'nap' => 'Editar soneca', _ => 'Editar fralda' },
      startLabel: type == 'diaper' ? 'Horário' : 'Início',
      initialStartedAt: startedAt,
      initialEndedAt: type == 'diaper' ? null : endedAt,
      eventType: type,
      initialDetailsValues: initialDetails,
      onSubmit: (newStartedAt, newEndedAt, details) async {
        final result = switch (type) {
          'feeding' => await ApiService.updateFeeding(
              event['id'],
              startedAt: newStartedAt.toUtc().toIso8601String(),
              endedAt: newEndedAt?.toUtc().toIso8601String(),
              type: details['type'],
              side: details['side'],
              volumeMl: details['volume_ml'],
              note: details['note'],
            ),
          'nap' => await ApiService.updateNap(
              event['id'],
              startedAt: newStartedAt.toUtc().toIso8601String(),
              endedAt: newEndedAt?.toUtc().toIso8601String(),
              location: details['location'],
              lightEnvironment: details['light_environment'],
              whiteNoise: details['white_noise'],
              note: details['note'],
            ),
          _ => await ApiService.updateDiaper(
              event['id'],
              changedAt: newStartedAt.toUtc().toIso8601String(),
              type: details['type'],
              consistency: details['consistency'],
              note: details['note'],
            ),
        };
        if (result['status'] == 200) {
          return null;
        }
        return result['data'] is Map
            ? result['data']['message'] ?? 'Não foi possível salvar.'
            : 'Não foi possível salvar.';
      },
    );
    // Só busca de novo depois que o dialog já fechou de vez — ver
    // manage_access_screen.dart pra mais contexto sobre o crash que
    // esse padrão evita.
    _fetchHistory();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours == 0) return '${minutes}min';
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}min';
  }

  String _formatClock(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Cor da linha do tempo ───────────────────────────
  //
  // Derivada dos eventos já carregados, não armazenada em lugar nenhum.
  // Mamada e soneca nunca coexistem (regra já garantida pelo backend), então
  // o trecho entre dois eventos consecutivos está inteiramente dentro ou
  // inteiramente fora de uma soneca — nunca dividido — e checar o ponto
  // médio do trecho é suficiente.
  List<Color> _computeSegmentColors() {
    final naps = _events.where((e) => e['type'] == 'nap');
    final napIntervals = naps.map((n) {
      final start = DateTime.parse(n['started_at']);
      final end = n['ended_at'] != null ? DateTime.parse(n['ended_at']) : DateTime.now();
      return (start: start, end: end);
    }).toList();

    bool isAsleep(DateTime t) =>
        napIntervals.any((iv) => !t.isBefore(iv.start) && t.isBefore(iv.end));

    final hasOpenNap = naps.any((n) => n['ended_at'] == null);
    final colors = <Color>[hasOpenNap ? AppColors.napB : AppColors.primaryB];

    for (var i = 0; i < _events.length - 1; i++) {
      final newer = DateTime.parse(_events[i]['started_at']);
      final older = DateTime.parse(_events[i + 1]['started_at']);
      final mid = older.add(newer.difference(older) ~/ 2);
      colors.add(isAsleep(mid) ? AppColors.napB : AppColors.primaryB);
    }

    return colors;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    if (_isSameDay(date, today)) return 'Hoje';
    if (_isSameDay(date, today.subtract(const Duration(days: 1)))) return 'Ontem';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍼😴🧷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sp3),
            Text('Nenhum registro ainda.', style: AppTypography.bodyLarge),
          ],
        ),
      );
    }

    final segmentColors = _computeSegmentColors();
    final groups = _groupByDay();
    final slivers = <Widget>[const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sp4))];
    var globalIndex = 0;

    for (final group in groups) {
      final headerColor = segmentColors[globalIndex];
      final firstDay = DateTime.parse(group.first['started_at']).toLocal();

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyDateHeaderDelegate(
            label: _dateLabel(firstDay),
            lineColor: headerColor,
            railWidth: _railWidth,
          ),
        ),
      );

      final rows = <Widget>[];
      for (final event in group) {
        final topColor = segmentColors[globalIndex];
        final bottomColor = globalIndex + 1 < segmentColors.length ? segmentColors[globalIndex + 1] : null;
        rows.add(_buildTimelineRow(event, topColor, bottomColor));
        globalIndex++;
      }
      slivers.add(SliverList(delegate: SliverChildListDelegate(rows)));
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sp4)));

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  /// Eventos já vêm ordenados do mais recente pro mais antigo — só precisa
  /// agrupar mantendo essa ordem, sem reordenar nada.
  List<List<Map<String, dynamic>>> _groupByDay() {
    final groups = <List<Map<String, dynamic>>>[];
    for (final event in _events) {
      final day = DateTime.parse(event['started_at']).toLocal();
      if (groups.isNotEmpty) {
        final lastDay = DateTime.parse(groups.last.last['started_at']).toLocal();
        if (_isSameDay(day, lastDay)) {
          groups.last.add(event);
          continue;
        }
      }
      groups.add([event]);
    }
    return groups;
  }

  /// Um evento é incompleto quando o campo "estrutural" daquele tipo está
  /// nulo (mamada sem type, soneca sem location, fralda sem type). Campos
  /// de refinamento ausentes nunca disparam esse estado sozinhos.
  bool _isIncomplete(Map<String, dynamic> event) {
    return switch (event['type']) {
      'feeding' => event['feeding_type'] == null,
      'nap' => event['location'] == null,
      _ => event['diaper_type'] == null,
    };
  }

  Widget _buildTimelineRow(Map<String, dynamic> event, Color topColor, Color? bottomColor) {
    final type = event['type'];
    final incomplete = _isIncomplete(event);
    final familyBorder = incomplete
        ? AppColors.warnB
        : switch (type) { 'feeding' => AppColors.feedB, 'nap' => AppColors.napB, _ => AppColors.diaperB };
    final familySurface = switch (type) { 'feeding' => AppColors.feedS, 'nap' => AppColors.napS, _ => AppColors.diaperS };
    final emoji = switch (type) { 'feeding' => '🍼', 'nap' => '😴', _ => '🧷' };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _railWidth,
              child: Column(
                children: [
                  Expanded(child: Center(child: Container(width: 2, color: topColor))),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: familySurface,
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                      if (incomplete)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                            child: const Icon(Icons.error, size: 14, color: AppColors.warnB),
                          ),
                        ),
                    ],
                  ),
                  Expanded(child: Center(child: Container(width: 2, color: bottomColor ?? Colors.transparent))),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: GestureDetector(
                onTap: _canEdit ? () => _editEvent(event) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
                  padding: const EdgeInsets.all(AppSpacing.sp4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
                    border: Border.all(color: familyBorder, width: AppShapes.borderRegular),
                  ),
                  child: _buildCardContent(event),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> event) {
    final isDiaper = event['type'] == 'diaper';
    final inProgress = !isDiaper && event['ended_at'] == null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDiaper
                    ? 'Troca de fralda'
                    : (inProgress ? 'Em andamento' : _formatDuration(event['duration_minutes'])),
                style: AppTypography.titleMedium,
              ),
              Text(
                isDiaper
                    ? _formatClock(event['started_at'])
                    : (inProgress
                        ? 'início ${_formatClock(event['started_at'])}'
                        : '${_formatClock(event['started_at'])} – ${_formatClock(event['ended_at'])}'),
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        if (_canEdit) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.inkSoft),
            onPressed: () => _editEvent(event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.dangerT),
            onPressed: () => _confirmDelete(event),
          ),
        ],
      ],
    );
  }
}

/// Cabeçalho de data fixo no topo enquanto a seção daquele dia estiver na
/// tela — some só quando o próximo dia "empurra" ele pra fora, padrão nativo
/// de SliverPersistentHeader com pinned:true (sem depender de pacote extra).
class _StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final Color lineColor;
  final double railWidth;

  _StickyDateHeaderDelegate({
    required this.label,
    required this.lineColor,
    required this.railWidth,
  });

  static const double _height = 40;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
      child: Stack(
        children: [
          Positioned(
            left: railWidth / 2 - 1,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: lineColor),
          ),
          Positioned(
            left: railWidth / 2,
            top: 0,
            bottom: 0,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppShapes.radiusFull),
                    border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
                  ),
                  child: Text(label, style: AppTypography.labelSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyDateHeaderDelegate oldDelegate) {
    return label != oldDelegate.label || lineColor != oldDelegate.lineColor;
  }
}
