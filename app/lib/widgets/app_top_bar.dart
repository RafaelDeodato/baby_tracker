import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';

/// Barra superior padrão do app: título sempre centralizado, seta de
/// voltar automática (o Flutter já mostra sozinho quando a tela pode
/// voltar) e ícone de perfil à direita, pra acesso rápido de qualquer
/// tela. Usado em todas as telas depois do login — as telas de
/// autenticação (login/registro) têm layout próprio, sem barra.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileAction;

  const AppTopBar({super.key, required this.title, this.showProfileAction = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: showProfileAction
          ? [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
