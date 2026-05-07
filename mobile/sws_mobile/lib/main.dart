import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:badges/badges.dart' as badges;
import 'dart:convert';
import 'screens/upload_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/notifications_screen.dart';
import 'api/api_service.dart';
import 'theme.dart';

void main() => runApp(const SWSApp());

class SWSApp extends StatelessWidget {
  const SWSApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SWS Document Manager',
    theme: AppTheme.theme,
    home: const MainNav(),
    debugShowCheckedModeBanner: false,
  );
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  final ApiService _api = ApiService();
  late WebSocketChannel _channel;

  final List<Widget> _screens = [
    const UploadScreen(),
    const DocumentsScreen(),
    const NotificationsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(ApiService.wsUrl));
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'upload_complete') {
        _loadUnreadCount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await _api.getUnreadCount();
    setState(() => _unreadCount = count);
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 2) _loadUnreadCount();
        },
        selectedItemColor: AppTheme.primary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            label: 'Notifications',
            icon: badges.Badge(
              showBadge: _unreadCount > 0,
              badgeContent: Text(
                '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
    );
  }
}
