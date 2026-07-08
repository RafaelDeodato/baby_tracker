import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import 'event_details_fields.dart';

class StatusTab extends StatefulWidget {
  final int babyId;
  final String role;

  const StatusTab({super.key, required this.babyId, required this.role});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  Map<String, dynamic>? _status;

  bool get _canEdit => widget.role == 'adm' || widget.role == 'tutor';

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getBabyStatus(widget.babyId);
      if (result['status'] == 200) {
        setState(() => _status = result['data']);
      } else {
        setState(() => _error = 'Não foi possível carregar o status.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _runAction(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      final result = await action();
      final ok = result['status'] == 200 || result['status'] == 201;
      if (ok) {
        final warning = result['data'] is Map ? result['data']['warning'] : null;
        await _fetchStatus();
        if (warning != null) _showWarningDialog(warning);
      } else {
        final message = result['data'] is Map ? result['data']['message'] : null;
        _showSnack(message ?? 'Não foi possível completar a ação.');
      }
    } catch (e) {
      _showSnack('Erro de conexão.');
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.dangerS,
        content: Text(message, style: const TextStyle(color: AppColors.dangerT)),
      ),
    );
  }

  Future<void> _showWarningDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
          side: const BorderSide(color: AppColors.warnB, width: AppShapes.borderRegular),
        ),
        title: Text('Atenção', style: AppTypography.titleMedium),
        content: Text(message, style: AppTypography.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: AppColors.warnT)),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStartTime({
    required String startedAt,
    required Future<Map<String, dynamic>> Function(String iso) onSave,
  }) async {
    final current = DateTime.parse(startedAt).toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryB,
            onPrimary: AppColors.ink,
            onSurface: AppColors.ink,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    final adjusted = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
    await _runAction(() => onSave(adjusted.toUtc().toIso8601String()));
  }

  /// Salva um campo de complementação de dados (V3) do evento em andamento.
  /// Cada seleção de chip (ou saída de foco num campo de texto) chama isso
  /// direto — sem botão de salvar separado.
  Future<void> _saveEventDetail(String eventType, int eventId, String field, dynamic value) {
    return _runAction(() => eventType == 'feeding'
        ? ApiService.updateFeeding(
            eventId,
            type: field == 'type' ? value : null,
            side: field == 'side' ? value : null,
            volumeMl: field == 'volume_ml' ? value : null,
            note: field == 'note' ? value : null,
          )
        : ApiService.updateNap(
            eventId,
            location: field == 'location' ? value : null,
            lightEnvironment: field == 'light_environment' ? value : null,
            whiteNoise: field == 'white_noise' ? value : null,
            note: field == 'note' ? value : null,
          ));
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

    final status = _status!;
    final currentFeeding = status['current_feeding'];
    final currentNap = status['current_nap'];
    final lastFeeding = status['last_feeding'];
    final lastNap = status['last_nap'];
    final lastDiaper = status['last_diaper'];
    final awakeMinutes = status['awake_minutes'];

    return RefreshIndicator(
      onRefresh: _fetchStatus,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        children: [
          _buildCurrentStateCard(currentFeeding, currentNap, awakeMinutes),
          const SizedBox(height: AppSpacing.sp6),
          if (lastFeeding != null) ...[
            _buildLastEventCard(
              emoji: '🍼',
              title: 'Última mamada',
              familyBorder: AppColors.feedB,
              familySurface: AppColors.feedS,
              valueText: _formatDuration(lastFeeding['duration_minutes']),
              minutesSince: lastFeeding['minutes_since_end'],
            ),
            const SizedBox(height: AppSpacing.sp3),
          ],
          if (lastNap != null) ...[
            _buildLastEventCard(
              emoji: '😴',
              title: 'Última soneca',
              familyBorder: AppColors.napB,
              familySurface: AppColors.napS,
              valueText: _formatDuration(lastNap['duration_minutes']),
              minutesSince: currentNap == null ? awakeMinutes : null,
            ),
            const SizedBox(height: AppSpacing.sp3),
          ],
          if (lastDiaper != null)
            _buildLastEventCard(
              emoji: '🧷',
              title: 'Última troca de fralda',
              familyBorder: AppColors.diaperB,
              familySurface: AppColors.diaperS,
              valueText: _formatClock(lastDiaper['changed_at']),
              minutesSince: lastDiaper['minutes_since'],
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStateCard(dynamic currentFeeding, dynamic currentNap, dynamic awakeMinutes) {
    if (currentFeeding != null) {
      return _eventHeroCard(
        emoji: '🍼',
        label: 'Mamando',
        familyBorder: AppColors.feedB,
        familySurface: AppColors.feedS,
        elapsedMinutes: currentFeeding['elapsed_minutes'],
        startedAt: currentFeeding['started_at'],
        actionLabel: 'Finalizar mamada',
        onAction: () => _runAction(() => ApiService.finishFeeding(currentFeeding['id'])),
        onAdjustStartTime: () => _adjustStartTime(
          startedAt: currentFeeding['started_at'],
          onSave: (iso) => ApiService.updateFeeding(currentFeeding['id'], startedAt: iso),
        ),
        showDiaperButton: false,
        eventType: 'feeding',
        eventId: currentFeeding['id'],
        detailsValues: currentFeeding,
      );
    }

    if (currentNap != null) {
      return _eventHeroCard(
        emoji: '😴',
        label: 'Dormindo',
        familyBorder: AppColors.napB,
        familySurface: AppColors.napS,
        elapsedMinutes: currentNap['elapsed_minutes'],
        startedAt: currentNap['started_at'],
        actionLabel: 'Finalizar soneca',
        onAction: () => _runAction(() => ApiService.finishNap(currentNap['id'])),
        onAdjustStartTime: () => _adjustStartTime(
          startedAt: currentNap['started_at'],
          onSave: (iso) => ApiService.updateNap(currentNap['id'], startedAt: iso),
        ),
        showDiaperButton: true,
        eventType: 'nap',
        eventId: currentNap['id'],
        detailsValues: currentNap,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
      ),
      child: Column(
        children: [
          const Text('😊', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.sp3),
          Text('Acordado', style: AppTypography.titleMedium),
          if (awakeMinutes != null) ...[
            const SizedBox(height: AppSpacing.sp2),
            Text('há ${_formatDuration(awakeMinutes)}', style: AppTypography.displayLarge),
          ],
          if (_canEdit) ...[
            const SizedBox(height: AppSpacing.sp6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionLoading
                    ? null
                    : () => _runAction(() => ApiService.startFeeding(widget.babyId)),
                icon: const Text('🍼'),
                label: const Text('Iniciar mamada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.feedS,
                  foregroundColor: AppColors.feedT,
                  side: const BorderSide(color: AppColors.feedB, width: AppShapes.borderRegular),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp3),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionLoading
                    ? null
                    : () => _runAction(() => ApiService.startNap(widget.babyId)),
                icon: const Text('😴'),
                label: const Text('Iniciar soneca'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.napS,
                  foregroundColor: AppColors.napT,
                  side: const BorderSide(color: AppColors.napB, width: AppShapes.borderRegular),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp3),
            _diaperButton(),
          ],
        ],
      ),
    );
  }

  Widget _diaperButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _actionLoading ? null : _showRegisterDiaperDialog,
        icon: const Text('🧷'),
        label: const Text('Registrar fralda'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.diaperS,
          foregroundColor: AppColors.diaperT,
          side: const BorderSide(color: AppColors.diaperB, width: AppShapes.borderRegular),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }

  Future<void> _showRegisterDiaperDialog() async {
    final values = <String, dynamic>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final hasAnyValue = values.values.any((v) => v != null && v != '');
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
              side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
            ),
            title: Text('Registrar fralda', style: Theme.of(ctx).textTheme.titleMedium),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EventDetailsFields(
                    eventType: 'diaper',
                    values: values,
                    onChanged: (field, value) => setDialogState(() => values[field] = value),
                  ),
                  const SizedBox(height: AppSpacing.sp6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _runAction(() => ApiService.registerDiaper(
                              widget.babyId,
                              type: values['type'],
                              consistency: values['consistency'],
                              note: values['note'],
                            ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.diaperS,
                        foregroundColor: AppColors.diaperT,
                        side: const BorderSide(color: AppColors.diaperB, width: AppShapes.borderRegular),
                        elevation: 0,
                      ),
                      child: Text(hasAnyValue ? 'Salvar' : 'Preencher depois'),
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
          );
        },
      ),
    );
  }

  Widget _eventHeroCard({
    required String emoji,
    required String label,
    required Color familyBorder,
    required Color familySurface,
    required int elapsedMinutes,
    required String startedAt,
    required String actionLabel,
    required VoidCallback onAction,
    required VoidCallback onAdjustStartTime,
    required bool showDiaperButton,
    required String eventType,
    required int eventId,
    required Map<String, dynamic> detailsValues,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
        border: Border.all(color: familyBorder, width: AppShapes.borderRegular),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: familySurface,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: AppSpacing.sp3),
          Text(label, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sp2),
          Text('há ${_formatDuration(elapsedMinutes)}', style: AppTypography.displayLarge),
          const SizedBox(height: AppSpacing.sp2),
          GestureDetector(
            onTap: (_canEdit && !_actionLoading) ? onAdjustStartTime : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppShapes.radiusFull),
                border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canEdit) ...[
                    Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                    const SizedBox(width: 6),
                  ],
                  Text('desde ${_formatClock(startedAt)}', style: AppTypography.bodyMedium.copyWith(color: AppColors.ink)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp6),
          SizedBox(
            width: double.infinity,
            child: IgnorePointer(
              ignoring: !_canEdit,
              child: EventDetailsFields(
                key: ValueKey('$eventType-$eventId'),
                eventType: eventType,
                values: detailsValues,
                onChanged: (field, value) => _saveEventDetail(eventType, eventId, field, value),
              ),
            ),
          ),
          if (_canEdit) ...[
            const SizedBox(height: AppSpacing.sp6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _actionLoading ? null : onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successS,
                  foregroundColor: AppColors.successT,
                  side: const BorderSide(color: AppColors.successB, width: AppShapes.borderRegular),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _actionLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(actionLabel),
              ),
            ),
          ],
          if (showDiaperButton && _canEdit) ...[
            const SizedBox(height: AppSpacing.sp3),
            _diaperButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLastEventCard({
    required String emoji,
    required String title,
    required Color familyBorder,
    required Color familySurface,
    required String valueText,
    required int? minutesSince,
  }) {
    return Container(
      width: double.infinity,
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
                Text(title, style: AppTypography.bodyMedium),
                Text(valueText, style: AppTypography.titleMedium),
              ],
            ),
          ),
          if (minutesSince != null)
            Text('há ${_formatDuration(minutesSince)}', style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
