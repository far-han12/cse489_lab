import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import '../models/landmark.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  Future<List<Landmark>> getLandmarks() async {
    final uri = Uri.parse(baseUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final List<Landmark> out = [];
          for (var i = 0; i < decoded.length; i++) {
            final item = decoded[i];
            try {
              if (item is Map<String, dynamic>) {
                out.add(Landmark.fromJson(item));
              } else if (item is Map) {
                out.add(Landmark.fromJson(Map<String, dynamic>.from(item)));
              } else {
                debugPrint(
                  'Skipped landmark: unexpected item type at index $i: ${item.runtimeType}',
                );
              }
            } catch (e) {
              debugPrint('Skipped invalid landmark at index $i: $e');
            }
          }
          if (out.isEmpty) {
            throw Exception('No valid landmarks parsed from response');
          }
          return out;
        } else {
          throw Exception('Unexpected JSON structure (not a List)');
        }
      } catch (e) {
        final snippet = response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body;
        throw Exception(
          'Failed to parse landmarks JSON: $e\nResponse snippet: $snippet',
        );
      }
    } else {
      final snippet = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      throw Exception(
        'Failed to load landmarks (HTTP ${response.statusCode}). Response snippet: $snippet',
      );
    }
  }

  Future<Uint8List> _resizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('Unable to decode image');
    }
    final img.Image resized = img.copyResize(original, width: 800, height: 600);
    final resizedBytes = img.encodeJpg(resized, quality: 85);
    return Uint8List.fromList(resizedBytes);
  }

  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();

    if (imageFile != null) {
      final resizedBytes = await _resizeImage(imageFile);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          resizedBytes,
          filename: 'image.jpg',
          contentType: http_parser.MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return int.parse(data['id'].toString());
    } else {
      throw Exception('Failed to create landmark: ${response.body}');
    }
  }

  Future<void> updateLandmark({
    required int id,
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    if (imageFile != null) {
      try {
        await createLandmark(
          title: title,
          lat: lat,
          lon: lon,
          imageFile: imageFile,
        );

        await deleteLandmark(id);

        return;
      } catch (e) {
        throw Exception('Failed to update image (Workaround failed): $e');
      }
    }

    final uri = Uri.parse(baseUrl);
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'id': id.toString(),
        'title': title,
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update landmark: ${response.body}');
    }
  }

  Future<void> deleteLandmark(int id) async {
    final uri = Uri.parse('$baseUrl?id=$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark: ${response.body}');
    }
  }
}
