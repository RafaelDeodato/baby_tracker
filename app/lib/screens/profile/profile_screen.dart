import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchMe();
  }

  Future<void> _fetchMe() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.getMe();
      if (result['status'] == 200) {
        setState(() {
          _name = result['data']['name'];
          _email = result['data']['email'];
        });
      } else {
        setState(() => _error = 'Não foi possível carregar o perfil.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil', style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.sp4),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sp6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppShapes.radiusLarge),
                          border: Border.all(color: AppColors.outline, width: AppShapes.borderRegular),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👤', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: AppSpacing.sp4),
                            Text(_name ?? '', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.sp2),
                            Text(
                              _email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                            ),
                            const SizedBox(height: AppSpacing.sp8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.dangerS,
                                  foregroundColor: AppColors.dangerT,
                                  side: const BorderSide(color: AppColors.dangerB, width: AppShapes.borderRegular),
                                ),
                                child: const Text('Sair'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
