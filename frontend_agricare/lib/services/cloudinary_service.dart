// lib/services/cloudinary_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // ⚠️ REPLACE THESE WITH YOUR CLOUDINARY CREDENTIALS
  static const String cloudName = 'dpg2pftny';
  static const String uploadPreset = 'AgriCareProject';
  
  // Upload single image
  Future<String> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      
      // Add upload preset
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'marketplace';
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonData = json.decode(responseString);
        
        // Return secure URL
        return jsonData['secure_url'];
      } else {
        throw Exception('Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Upload multiple images
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> urls = [];
    
    for (var imageFile in imageFiles) {
      final url = await uploadImage(imageFile);
      urls.add(url);
    }
    
    return urls;
  }
}