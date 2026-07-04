import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import 'event_edit_dialog.dart';

class HistoryTab extends StatefulWidget {
  final int babyId;

  const HistoryTab({super.key, required this.babyId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];

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
      ]);
      final feedingsResult = results[0];
      final napsResult = results[1];

      if (feedingsResult['status'] == 200 && napsResult['status'] == 200) {
        final events = <Map<String, dynamic>>[
          for (final f in feedingsResult['data']) {...f, 'type': 'feeding'},
          for (final n in napsResult['data']) {...n, 'type': 'nap'},
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
    final isFeeding = event['type'] == 'feeding';
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
          isFeeding ? 'Esta mamada será excluída permanentemente.' : 'Esta soneca será excluída permanentemente.',
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

    final status = isFeeding
        ? await ApiService.deleteFeeding(event['id'])
        : await ApiService.deleteNap(event['id']);

    if (status == 204) {
      setState(() => _events.removeWhere((e) => e['id'] == event['id'] && e['type'] == event['type']));
    }
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final isFeeding = event['type'] == 'feeding';
    final startedAt = DateTime.parse(event['started_at']).toLocal();
    final endedAt = event['ended_at'] != null ? DateTime.parse(event['ended_at']).toLocal() : null;

    await showEventEditDialog(
      context,
      title: isFeeding ? 'Editar mamada' : 'Editar soneca',
      initialStartedAt: startedAt,
      initialEndedAt: endedAt,
      onSubmit: (newStartedAt, newEndedAt) async {
        final result = isFeeding
            ? await ApiService.updateFeeding(
                event['id'],
                startedAt: newStartedAt.toUtc().toIso8601String(),
                endedAt: newEndedAt?.toUtc().toIso8601String(),
              )
            : await ApiService.updateNap(
                event['id'],
                startedAt: newStartedAt.toUtc().toIso8601String(),
                endedAt: newEndedAt?.toUtc().toIso8601String(),
              );
        if (result['status'] == 200) {
          await _fetchHistory();
          return null;
        }
        return result['data'] is Map
            ? result['data']['message'] ?? 'Não foi possível salvar.'
            : 'Não foi possível salvar.';
      },
    );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍼😴', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sp3),
            Text('Nenhum registro ainda.', style: AppTypography.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp3),
        itemBuilder: (context, i) {
          final event = _events[i];
          final isFeeding = event['type'] == 'feeding';
          final inProgress = event['ended_at'] == null;
          final familyBorder = isFeeding ? AppColors.primaryB : AppColors.napB;
          final familySurface = isFeeding ? AppColors.primaryS : AppColors.napS;
          final emoji = isFeeding ? '🍼' : '😴';

          return Container(
            padding: const EdgeInsets.all(AppSpacing.sp4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
              border: Border.all(color: familyBorder, width: AppShapes.borderRegular),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: familySurface,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: AppSpacing.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inProgress ? 'Em andamento' : _formatDuration(event['duration_minutes']),
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        inProgress
                            ? 'início ${_formatClock(event['started_at'])}'
                            : '${_formatClock(event['started_at'])} – ${_formatClock(event['ended_at'])}',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.inkSoft),
                  onPressed: () => _editEvent(event),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.dangerT),
                  onPressed: () => _confirmDelete(event),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
