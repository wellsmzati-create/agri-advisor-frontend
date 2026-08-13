import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmer_provider.dart';
import 'dashboard_screen.dart';
import '../crops/crop_list_screen.dart';
import '../tips/tips_screen.dart';
import '../chat/advisors_screen.dart';
import '../notifications/notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const _workspaceSyncInterval = Duration(seconds: 6);

  int _currentIndex = 0;
  Timer? _syncTimer;

  final _screens = const [
    DashboardScreen(),
    CropListScreen(),
    TipsScreen(),
    AdvisorsScreen(),
    NotificationsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWorkspace();
    });
    _syncTimer = Timer.periodic(
      _workspaceSyncInterval,
      (_) {
        if (!mounted) return;
        _syncWorkspace();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _syncWorkspace();
    }
  }

  void _syncWorkspace() {
    context.read<FarmerProvider>().syncFromBackend(
          includeConversations: _currentIndex == 3,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmerProvider>(
      builder: (_, farmerProvider, __) => Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              _syncWorkspace();
            },
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), activeIcon: Icon(Icons.eco), label: 'Crops'),
              const BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), activeIcon: Icon(Icons.lightbulb), label: 'Tips'),
              const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Advisors'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: farmerProvider.unreadCount > 0,
                  label: Text('${farmerProvider.unreadCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: const Icon(Icons.notifications),
                label: 'Alerts',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    context.read<FarmerProvider>().reset();
    await context.read<AuthProvider>().logout();
  }
}
