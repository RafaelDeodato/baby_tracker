import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';
import 'register_screen.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../babies/babies_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
  setState(() { _loading = true; _error = null; });
  try {
    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (result['status'] == 200) {
      final data = result['data'];
      await StorageService.saveTokens(data['access_token'], data['refresh_token']);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BabiesScreen()),
        );
      }
    } else {
      setState(() => _error = result['data']['message'] ?? 'Credenciais inválidas.');
    }
  } catch (e) {
    print('ERRO LOGIN: $e');
    setState(() => _error = 'Erro de conexão. Verifique se a API está rodando.');
  } finally {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                    const Text('🍼', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: AppSpacing.sp3),
                    Text('Baby Tracker', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryT)),
                    const SizedBox(height: AppSpacing.sp8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Entrar', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sp4),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sp3),
                        decoration: BoxDecoration(
                          color: AppColors.dangerS,
                          borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                          border: Border.all(color: AppColors.dangerB),
                        ),
                        child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.dangerT)),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sp6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin, // ATUALIZADO
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryS,
                          foregroundColor: AppColors.primaryT,
                          side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                        ),
                        child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      ),
                      child: Text(
                        'Não tem conta? Criar conta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryT,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
