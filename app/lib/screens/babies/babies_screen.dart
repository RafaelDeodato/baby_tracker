import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_top_bar.dart';
import 'baby_home_screen.dart';
import 'baby_form_dialog.dart';

class BabiesScreen extends StatefulWidget {
  const BabiesScreen({super.key});

  @override
  State<BabiesScreen> createState() => _BabiesScreenState();
}

class _BabiesScreenState extends State<BabiesScreen> {
  List<dynamic> _babies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBabies();
  }

  Future<void> _fetchBabies() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getBabies();
      if (result['status'] == 200) {
        setState(() => _babies = result['data']);
      } else {
        setState(() => _error = 'Não foi possível carregar os bebês.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddBabyDialog() {
    return showBabyFormDialog(
      context,
      title: 'Novo bebê',
      onSubmit: (name, birthDate) async {
        final result = await ApiService.createBaby(name, birthDate);
        if (result['status'] == 201) {
          await _fetchBabies();
          return true;
        }
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Meus Bebês'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _babies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👶', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: AppSpacing.sp3),
                          Text(
                            'Nenhum bebê cadastrado ainda.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.sp4),
                      itemCount: _babies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp3),
                      itemBuilder: (context, i) {
                        final baby = _babies[i];
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BabyHomeScreen(baby: baby)),
                            );
                            _fetchBabies();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sp4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
                              border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
                            ),
                            child: Row(
                              children: [
                                const Text('👶', style: TextStyle(fontSize: 32)),
                                const SizedBox(width: AppSpacing.sp3),
                                Expanded(
                                  child: Text(
                                    baby['name'],
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBabyDialog,
        backgroundColor: AppColors.primaryS,
        foregroundColor: AppColors.primaryT,
        label: Text('Novo bebê', style: Theme.of(context).textTheme.labelLarge),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
