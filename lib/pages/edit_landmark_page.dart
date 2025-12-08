import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../models/landmark.dart';
import '../services/api_service.dart';

class EditLandmarkPage extends StatefulWidget {
  final ApiService apiService;
  final Landmark? existing;
  final VoidCallback onSaved;

  const EditLandmarkPage({
    super.key,
    required this.apiService,
    this.existing,
    required this.onSaved,
  });

  @override
  State<EditLandmarkPage> createState() => _EditLandmarkPageState();
}

class _EditLandmarkPageState extends State<EditLandmarkPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  
  File? _selectedImage;
  bool _loading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _titleController.text = widget.existing!.title;
      _latController.text = widget.existing!.lat.toString();
      _lonController.text = widget.existing!.lon.toString();
    } else {
      _detectLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latController.text = pos.latitude.toString();
      _lonController.text = pos.longitude.toString();
    } catch (_) {
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      try {
        final bytes = await picked.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 800, height: 600);
          final jpeg = img.encodeJpg(resized, quality: 85);
          final tmp = File(
            '${Directory.systemTemp.path}/lm_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tmp.writeAsBytes(jpeg);
          setState(() => _selectedImage = tmp);
        } else {
          setState(() => _selectedImage = File(picked.path));
        }
      } catch (e) {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  void _showImagePreview({required bool isFile}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: isFile
                ? Image.file(_selectedImage!, fit: BoxFit.contain)
                : Image.network(widget.existing!.imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      _showError('Latitude and longitude must be valid numbers');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isEditing) {
        await widget.apiService.updateLandmark(
          id: widget.existing!.id,
          title: title,
          lat: lat,
          lon: lon,
          imageFile: _selectedImage,
        );
      } else {
        await widget.apiService.createLandmark(
          title: title,
          lat: lat,
          lon: lon,
          imageFile: _selectedImage, 
        );
      }

      widget.onSaved();

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        _titleController.clear();
        _latController.clear();
        _lonController.clear();
        setState(() {
          _selectedImage = null;
        });
      }
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = _isEditing ? 'Edit Landmark' : 'New Landmark';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[400]!;
    final iconColor = isDark ? Colors.grey[500] : Colors.grey[600];

    final bool hasLocalImage = _selectedImage != null;
    final bool hasNetworkImage = _isEditing && widget.existing!.imageUrl.isNotEmpty;
    final bool showPlaceholder = !hasLocalImage && !hasNetworkImage;

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Title is required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lonController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                         onPressed: _detectLocation,
                         icon: const Icon(Icons.my_location),
                         tooltip: 'Detect Location',
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  GestureDetector(
                    onTap: () {
                      if (hasLocalImage) {
                         _showImagePreview(isFile: true);
                      } else if (hasNetworkImage) {
                         _showImagePreview(isFile: false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: showPlaceholder ? boxColor : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (hasLocalImage)
                              Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else if (hasNetworkImage)
                              Image.network(
                                widget.existing!.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: iconColor),
                                    const Text('Image not found', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_outlined, size: 48, color: iconColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(color: iconColor),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: Text(
                          (hasLocalImage || hasNetworkImage) 
                            ? 'Change Image' 
                            : 'Select Image',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing && hasLocalImage) 
                    TextButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text('Undo Changes (Revert to original image)'),
                    ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _submit,
                      icon: _loading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _loading ? ' Saving...' : (_isEditing ? 'Update Landmark' : 'Create Landmark'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}