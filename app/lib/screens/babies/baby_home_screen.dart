import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_top_bar.dart';
import 'status_tab.dart';
import 'history_tab.dart';
import 'baby_profile_tab.dart';

class BabyHomeScreen extends StatefulWidget {
  final Map<String, dynamic> baby;

  const BabyHomeScreen({super.key, required this.baby});

  @override
  State<BabyHomeScreen> createState() => _BabyHomeScreenState();
}

class _BabyHomeScreenState extends State<BabyHomeScreen> {
  int _currentIndex = 0;
  late Map<String, dynamic> _baby = widget.baby;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      StatusTab(babyId: _baby['id']),
      HistoryTab(babyId: _baby['id']),
      BabyProfileTab(
        baby: _baby,
        onUpdated: (updated) => setState(() => _baby = updated),
      ),
    ];

    return Scaffold(
      appBar: AppTopBar(title: _baby['name']),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primaryT,
        unselectedItemColor: AppColors.inkSoft,
        backgroundColor: AppColors.surface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.child_care), label: 'Perfil'),
        ],
      ),
    );
  }
}
