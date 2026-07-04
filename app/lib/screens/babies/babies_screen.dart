import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../profile/profile_screen.dart';
import 'baby_home_screen.dart';

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

  Future<void> _showAddBabyDialog() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;
    String dateLabel = 'Data nascimento';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
            side: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
          ),
          title: Text('Novo bebê', style: Theme.of(context).textTheme.titleMedium),
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
                    initialDate: DateTime(2024),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    final result = await ApiService.createBaby(
                      nameController.text.trim(),
                      birthDate,
                    );
                    if (result['status'] == 201 && ctx.mounted) {
                      Navigator.pop(ctx);
                      _fetchBabies();
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
    );

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Bebês', style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BabyHomeScreen(baby: baby)),
                          ),
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
