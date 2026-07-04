import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';

class StatusTab extends StatefulWidget {
  final int babyId;

  const StatusTab({super.key, required this.babyId});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  Map<String, dynamic>? _status;

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
              familyBorder: AppColors.primaryB,
              familySurface: AppColors.primaryS,
              duration: lastFeeding['duration_minutes'],
              minutesSince: lastFeeding['minutes_since_end'],
            ),
            const SizedBox(height: AppSpacing.sp3),
          ],
          if (lastNap != null)
            _buildLastEventCard(
              emoji: '😴',
              title: 'Última soneca',
              familyBorder: AppColors.napB,
              familySurface: AppColors.napS,
              duration: lastNap['duration_minutes'],
              minutesSince: currentNap == null ? awakeMinutes : null,
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
        familyBorder: AppColors.primaryB,
        familySurface: AppColors.primaryS,
        elapsedMinutes: currentFeeding['elapsed_minutes'],
        startedAt: currentFeeding['started_at'],
        actionLabel: 'Finalizar mamada',
        onAction: () => _runAction(() => ApiService.finishFeeding(currentFeeding['id'])),
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
                backgroundColor: AppColors.primaryS,
                foregroundColor: AppColors.primaryT,
                side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
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
        ],
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
          Text('desde ${_formatClock(startedAt)}', style: AppTypography.bodyMedium),
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
      ),
    );
  }

  Widget _buildLastEventCard({
    required String emoji,
    required String title,
    required Color familyBorder,
    required Color familySurface,
    required int duration,
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
                Text(_formatDuration(duration), style: AppTypography.titleMedium),
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
