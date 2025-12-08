import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/landmark.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'landmarks.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE landmarks (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            imageUrl TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> saveLandmarks(List<Landmark> items) async {
    final db = await _database;
    final batch = db.batch();

    batch.delete('landmarks');

    for (final lm in items) {
      batch.insert(
        'landmarks',
        lm.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Landmark>> getLandmarks() async {
    final db = await _database;
    final maps = await db.query(
      'landmarks',
      orderBy: 'id DESC',
    );
    return maps.map((m) => Landmark.fromDbMap(m)).toList();
  }
}
