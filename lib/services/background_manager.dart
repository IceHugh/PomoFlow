import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/background_image.dart';

/// Manager for background images
class BackgroundManager {
  static const int maxImages = 10; // Maximum number of images to prevent memory issues
  
  List<BackgroundImage> _backgroundImages = [];
  
  List<BackgroundImage> get backgroundImages => _backgroundImages;
  List<BackgroundImage> get selectedImages => 
      _backgroundImages.where((img) => img.isSelected).toList();

  // Load background images from storage
  Future<void> loadBackgroundImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getString('backgroundImages');
      
      if (imagesJson != null) {
        final List<dynamic> imagesList = jsonDecode(imagesJson);
        _backgroundImages = imagesList
            .map((json) => BackgroundImage.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading background images: $e');
      _backgroundImages = [];
    }
  }

  // Save background images to storage
  Future<void> _saveBackgroundImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = jsonEncode(_backgroundImages.map((img) => img.toJson()).toList());
      await prefs.setString('backgroundImages', imagesJson);
    } catch (e) {
      if (kDebugMode) print('Error saving background images: $e');
    }
  }

  // Add a new background image from local file
  Future<void> addBackgroundImage(String sourcePath) async {
    try {
      // Check if we've reached the limit
      if (_backgroundImages.length >= maxImages) {
        throw Exception('Maximum of $maxImages images allowed');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${appDir.path}/backgrounds');
      
      // Create backgrounds directory if not exists
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }

      // Get file name and extension
      final sourceFile = File(sourcePath);
      final fileName = sourcePath.split('/').last;
      
      // Generate unique ID and file name
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newFileName = 'bg_$id.jpg'; // Always save as JPG for compression
      final newPath = '${bgDir.path}/$newFileName';

      // Compress and save image
      await _compressAndSaveImage(sourceFile, newPath);

      // Create background image object (selected by default if it's the first one)
      final backgroundImage = BackgroundImage(
        id: id,
        name: fileName,
        filePath: newPath,
        isSelected: _backgroundImages.isEmpty, // Auto-select if first image
      );

      // Add to list and save
      _backgroundImages.add(backgroundImage);
      await _saveBackgroundImages();
    } catch (e) {
      if (kDebugMode) print('Error adding background image: $e');
      rethrow;
    }
  }

  // Compress image to reduce file size and memory usage
  Future<void> _compressAndSaveImage(File sourceFile, String targetPath) async {
    try {
      // Read source image
      final bytes = await sourceFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Determine if image is portrait or landscape
      final isPortrait = image.height > image.width;
      
      // Resize based on orientation
      img.Image resized = image;
      if (isPortrait) {
        // Portrait image (e.g., phone photos): limit height to 1920px
        // Common ratios: 3:4 (1440x1920), 9:16 (1080x1920)
        if (image.height > 1920) {
          resized = img.copyResize(
            image,
            height: 1920,
            interpolation: img.Interpolation.average,
          );
        }
      } else {
        // Landscape image: limit width to 1920px
        if (image.width > 1920) {
          resized = img.copyResize(
            image,
            width: 1920,
            interpolation: img.Interpolation.average,
          );
        }
      }

      // Compress as JPEG with 85% quality (good balance between quality and size)
      final compressed = img.encodeJpg(resized, quality: 85);

      // Save compressed image
      await File(targetPath).writeAsBytes(compressed);

      if (kDebugMode) {
        final originalSize = bytes.length / 1024 / 1024; // MB
        final compressedSize = compressed.length / 1024 / 1024; // MB
        final orientation = isPortrait ? 'Portrait' : 'Landscape';
        print('Image compressed [$orientation ${resized.width}x${resized.height}]: '
              '${originalSize.toStringAsFixed(2)}MB -> ${compressedSize.toStringAsFixed(2)}MB');
      }
    } catch (e) {
      if (kDebugMode) print('Error compressing image: $e');
      // Fallback: just copy the file if compression fails
      await sourceFile.copy(targetPath);
    }
  }

  // Delete a background image
  Future<void> deleteBackgroundImage(String id) async {
    try {
      // Find the image
      final image = _backgroundImages.firstWhere((img) => img.id == id);
      
      // Delete the file
      final file = File(image.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from list and save
      _backgroundImages.removeWhere((img) => img.id == id);
      await _saveBackgroundImages();
    } catch (e) {
      if (kDebugMode) print('Error deleting background image: $e');
      rethrow;
    }
  }

  // Toggle selection state of an image
  Future<void> toggleImageSelection(String id) async {
    try {
      final index = _backgroundImages.indexWhere((img) => img.id == id);
      if (index != -1) {
        _backgroundImages[index] = _backgroundImages[index].copyWith(
          isSelected: !_backgroundImages[index].isSelected,
        );
        await _saveBackgroundImages();
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling image selection: $e');
      rethrow;
    }
  }

  // Select all images
  Future<void> selectAllImages() async {
    try {
      _backgroundImages = _backgroundImages
          .map((img) => img.copyWith(isSelected: true))
          .toList();
      await _saveBackgroundImages();
    } catch (e) {
      if (kDebugMode) print('Error selecting all images: $e');
      rethrow;
    }
  }

  // Deselect all images
  Future<void> deselectAllImages() async {
    try {
      _backgroundImages = _backgroundImages
          .map((img) => img.copyWith(isSelected: false))
          .toList();
      await _saveBackgroundImages();
    } catch (e) {
      if (kDebugMode) print('Error deselecting all images: $e');
      rethrow;
    }
  }
}
