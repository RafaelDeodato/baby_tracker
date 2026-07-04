import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'status_tab.dart';
import 'history_tab.dart';

class BabyHomeScreen extends StatefulWidget {
  final Map<String, dynamic> baby;

  const BabyHomeScreen({super.key, required this.baby});

  @override
  State<BabyHomeScreen> createState() => _BabyHomeScreenState();
}

class _BabyHomeScreenState extends State<BabyHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      StatusTab(babyId: widget.baby['id']),
      HistoryTab(babyId: widget.baby['id']),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.baby['name'], style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        ],
      ),
    );
  }
}
