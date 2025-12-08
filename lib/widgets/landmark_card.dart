import 'package:flutter/material.dart';

import '../models/landmark.dart';

class LandmarkCard extends StatelessWidget {
  final Landmark landmark;
  final VoidCallback? onTap;

  const LandmarkCard({
    super.key,
    required this.landmark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortLocation =
        'Lat: ${landmark.lat.toStringAsFixed(3)}, Lon: ${landmark.lon.toStringAsFixed(3)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: landmark.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  landmark.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported),
                ),
              )
            : const Icon(Icons.image),
        title: Text(landmark.title),
        subtitle: Text(shortLocation),
      ),
    );
  }
}
