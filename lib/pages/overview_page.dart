import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/landmark.dart';
import '../services/api_service.dart';
import 'edit_landmark_page.dart';

class OverviewPage extends StatefulWidget {
  final List<Landmark> landmarks;
  final ApiService apiService;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;
  final bool isDarkMode;

  const OverviewPage({
    super.key,
    required this.landmarks,
    required this.apiService,
    required this.onUpdated,
    required this.onDeleted,
    required this.isDarkMode,
  });

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  GoogleMapController? _controller;
  
  static const _bangladeshCenter = LatLng(23.6850, 90.3563);

  // UPDATED: Changed administrative.country color to a light gray (#9e9e9e)
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#9e9e9e"
      },
      {
        "weight": 1.5
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _applyMapStyle();
    }
  }

  void _applyMapStyle() {
    if (widget.isDarkMode) {
      _controller?.setMapStyle(_darkMapStyle);
    } else {
      _controller?.setMapStyle('[]');
    }
  }

  double _getMarkerHue(int id) {
    const hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueMagenta,
      BitmapDescriptor.hueRose,
      BitmapDescriptor.hueCyan,
      BitmapDescriptor.hueAzure,
    ];
    return hues[id % hues.length];
  }

  Set<Marker> _buildMarkers() {
    return widget.landmarks.map((lm) {
      return Marker(
        markerId: MarkerId(lm.id.toString()),
        position: LatLng(lm.lat, lm.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(lm.id)),
        infoWindow: InfoWindow(title: lm.title),
        onTap: () => _showLandmarkBottomSheet(lm),
      );
    }).toSet();
  }

  void _showLandmarkBottomSheet(Landmark lm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lm.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (lm.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    lm.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${lm.lat.toStringAsFixed(4)}, '
                'Lon: ${lm.lon.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditLandmarkPage(
                              apiService: widget.apiService,
                              existing: lm,
                              onSaved: widget.onUpdated,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _deleteLandmark(lm);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLandmark(Landmark lm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete landmark'),
        content: Text('Delete "${lm.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.apiService.deleteLandmark(lm.id);
      widget.onDeleted();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to delete: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

 @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _bangladeshCenter,
            zoom: 6.5,
          ),
          markers: _buildMarkers(),
          onMapCreated: (controller) {
            _controller = controller;
            _applyMapStyle();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false, 
        ),

        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: "zoom_in", 
                onPressed: () {
                  _controller?.animateCamera(CameraUpdate.zoomIn());
                },
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                tooltip: 'Zoom In',
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.small(
                heroTag: "zoom_out",
                onPressed: () {
                  _controller?.animateCamera(CameraUpdate.zoomOut());
                },
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                tooltip: 'Zoom Out',
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}