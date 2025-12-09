class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String imageUrl;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.imageUrl,
  });

  static String _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    const base = 'https://labs.anontech.info/cse489/t3/';
    final cleaned = raw.replaceFirst(RegExp(r'^/'), '');
    return '$base$cleaned';
  }

  static double _parseDoubleField(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Missing $fieldName');
    }

    if (value is num) return value.toDouble();

    var s = value.toString().trim();
    if (s.isEmpty) throw FormatException('Empty $fieldName');

    // Replace common comma decimal separator with dot
    s = s.replaceAll(',', '.');

    // Extract first numeric-looking token (handles trailing characters)
    final match = RegExp(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?').firstMatch(s);
    if (match == null) throw FormatException('Invalid $fieldName: $s');

    final token = match.group(0)!;
    final parsed = double.tryParse(token);
    if (parsed == null) throw FormatException('Invalid $fieldName: $s');
    return parsed;
  }

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      lat: _parseDoubleField(json['lat'], 'lat'),
      lon: _parseDoubleField(json['lon'], 'lon'),
      imageUrl: _resolveImageUrl(json['image'] as String?),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'imageUrl': imageUrl,
    };
  }

  factory Landmark.fromDbMap(Map<String, dynamic> map) {
    return Landmark(
      id: map['id'] as int,
      title: map['title'] as String,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      imageUrl: (map['imageUrl'] as String?) ?? '',
    );
  }
}
