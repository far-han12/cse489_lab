import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image/image.dart' as img;

import '../models/landmark.dart';

class ApiService {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3/api.php';

  Future<List<Landmark>> getLandmarks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Landmark.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load landmarks (code ${response.statusCode})');
    }
  }

  /// Resize image to 800x600 and return bytes
  Future<Uint8List> _resizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('Unable to decode image');
    }
    final img.Image resized =
        img.copyResize(original, width: 800, height: 600);
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
    
    // 1. If we have an image, we cannot use PUT. 
    // We must Create a new entry and Delete the old one.
    if (imageFile != null) {
      try {
        // Step A: Create the new landmark with the new image
        await createLandmark(
          title: title, 
          lat: lat, 
          lon: lon, 
          imageFile: imageFile
        );

        // Step B: If Step A worked, delete the old landmark
        await deleteLandmark(id);
        
        return; // Stop here, we are done.
      } catch (e) {
        throw Exception('Failed to update image (Workaround failed): $e');
      }
    }

    // 2. If NO image, we use the standard PUT request (Text only updates work fine)
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
  /// DELETE (DELETE)
  Future<void> deleteLandmark(int id) async {
    final uri = Uri.parse('$baseUrl?id=$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete landmark: ${response.body}');
    }
  }
}
