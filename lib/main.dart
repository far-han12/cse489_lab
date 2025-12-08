import 'package:flutter/material.dart';

import 'models/landmark.dart';
import 'services/api_service.dart';
import 'services/local_db_service.dart';
import 'pages/overview_page.dart';
import 'pages/records_page.dart';
import 'pages/edit_landmark_page.dart';

import 'utils/app_theme.dart'; 

void main() {
  runApp(const LandmarkApp());
}

class LandmarkApp extends StatefulWidget {
  const LandmarkApp({super.key});

  @override
  State<LandmarkApp> createState() => _LandmarkAppState();
}

class _LandmarkAppState extends State<LandmarkApp> {
  final ApiService _api = ApiService();
  final LocalDbService _localDb = LocalDbService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isDarkMode = false; 

  int _currentIndex = 0;
  bool _loading = false;
  bool _offline = false;

  List<Landmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    setState(() {
      _loading = true;
      _offline = false;
    });

    try {
      final data = await _api.getLandmarks();
      setState(() {
        _landmarks = data;
        _offline = false;
      });
      await _localDb.saveLandmarks(data);
    } catch (e) {
      final cached = await _localDb.getLandmarks();
      if (cached.isNotEmpty) {
        setState(() {
          _landmarks = cached;
          _offline = true;
        });
        _showSnack('Offline – showing cached landmarks');
      } else {
        _showErrorDialog('Failed to load landmarks and no cached data.\n$e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    final messenger = _scaffoldMessengerKey.currentState;
    messenger?.clearSnackBars();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _onLandmarkCreated() async {
    await _loadLandmarks();
    _showSnack('Landmark created');
  }

  void _onLandmarkUpdated() async {
    await _loadLandmarks();
    _showSnack('Landmark updated');
  }

  void _onLandmarkDeleted() async {
    await _loadLandmarks();
    _showSnack('Landmark deleted');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OverviewPage(
        landmarks: _landmarks,
        apiService: _api,
        onUpdated: _onLandmarkUpdated,
        onDeleted: _onLandmarkDeleted,
        isDarkMode: _isDarkMode,
      ),
      RecordsPage(
        landmarks: _landmarks,
        apiService: _api,
        onUpdated: _onLandmarkUpdated,
        onDeleted: _onLandmarkDeleted,
      ),
      EditLandmarkPage(apiService: _api, onSaved: _onLandmarkCreated),
    ];

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Bangladesh Landmarks',
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bangladesh Landmarks'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: tabs[_currentIndex]),
            if (_offline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.amber.shade800,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: const SafeArea(
                    bottom: false,
                    child: Text(
                      'Offline mode – showing cached landmarks',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map), 
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_outlined),
              selectedIcon: Icon(Icons.list),
              label: 'Records',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'New Entry',
            ),
          ],
        ),
      ),
    );
  }
}