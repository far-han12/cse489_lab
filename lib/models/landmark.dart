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

  // Turn the raw "image" value from API into a full URL (if possible)
  static String _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    // If server already gives full URL, just use it
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    // Otherwise assume a relative path like "uploads/abc.jpg"
    const base = 'https://labs.anontech.info/cse489/t3/';
    final cleaned = raw.replaceFirst(RegExp(r'^/'), ''); // remove leading /
    return '$base$cleaned';
  }

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
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
