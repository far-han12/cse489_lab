import 'package:flutter/material.dart';

import '../models/landmark.dart';
import '../services/api_service.dart';
import '../widgets/landmark_card.dart';
import 'edit_landmark_page.dart';

class RecordsPage extends StatelessWidget {
  final List<Landmark> landmarks;
  final ApiService apiService;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  const RecordsPage({
    super.key,
    required this.landmarks,
    required this.apiService,
    required this.onUpdated,
    required this.onDeleted,
  });

  void _edit(BuildContext context, Landmark lm) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditLandmarkPage(
          apiService: apiService,
          existing: lm,
          onSaved: onUpdated,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Landmark lm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete landmark'),
        content: Text('Are you sure you want to delete "${lm.title}"?'),
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
      await apiService.deleteLandmark(lm.id);
      onDeleted();
    } catch (e) {
      // FIX: Check if the widget is still mounted before using context
      if (!context.mounted) return;
      
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
    if (landmarks.isEmpty) {
      return const Center(child: Text('No landmarks yet.'));
    }

    return ListView.builder(
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        final lm = landmarks[index];
        return Dismissible(
          key: ValueKey(lm.id),
          background: Container(
            color: Colors.blue,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _edit(context, lm);
              return false;
            } else {
              await _delete(context, lm);
              return false;
            }
          },
          child: LandmarkCard(
            landmark: lm,
            onTap: () => _edit(context, lm),
          ),
        );
      },
    );
  }
}