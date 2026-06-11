import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_spacing.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                      child: Text('Criar conta', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
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
                    const SizedBox(height: AppSpacing.sp6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryS,
                          foregroundColor: AppColors.primaryT,
                          side: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderRegular),
                        ),
                        child: const Text('Criar conta'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Já tem conta? Entrar',
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
