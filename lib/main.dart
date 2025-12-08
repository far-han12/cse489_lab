import 'package:flutter/material.dart';

import 'models/landmark.dart';
import 'services/api_service.dart';
import 'services/local_db_service.dart';
import 'pages/overview_page.dart';
import 'pages/records_page.dart';
import 'pages/edit_landmark_page.dart';

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
      // Pass the global theme state to the map page
      OverviewPage(
        landmarks: _landmarks,
        apiService: _api,
        onUpdated: _onLandmarkUpdated,
        onDeleted: _onLandmarkDeleted,
        isDarkMode: _isDarkMode, // <--- Added this parameter
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
      // Define Light Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Define Dark Theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Switch theme based on boolean
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bangladesh Landmarks'),
          actions: [
            // Theme Toggle Icon
            IconButton(
              // Show Sun icon if currently Dark (to switch to Light)
              // Show Moon icon if currently Light (to switch to Dark)
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Records'),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New Entry'),
          ],
        ),
      ),
    );
  }
}