import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_config.dart';
import '../../routes/app_routes.dart';
import '../../services/news_service.dart';

class AdminCreateNewsScreen extends StatefulWidget {
  const AdminCreateNewsScreen({super.key});

  @override
  State<AdminCreateNewsScreen> createState() => _AdminCreateNewsScreenState();
}

class _AdminCreateNewsScreenState extends State<AdminCreateNewsScreen> {
  late final NewsService _service;
  final _picker = ImagePicker();

  final _headlineEn = TextEditingController();
  final _headlineUr = TextEditingController();
  final _descEn = TextEditingController();
  final _descUr = TextEditingController();

  List<File> _images = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = NewsService(baseUrl: ApiConfig.apiV1Base);
  }

  @override
  void dispose() {
    _headlineEn.dispose();
    _headlineUr.dispose();
    _descEn.dispose();
    _descUr.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;

    setState(() {
      _images = picked.map((x) => File(x.path)).toList(growable: false);
    });
  }

  Future<void> _submit() async {
    final he = _headlineEn.text.trim();
    final hu = _headlineUr.text.trim();
    final de = _descEn.text.trim();
    final du = _descUr.text.trim();

    if (he.isEmpty && hu.isEmpty) {
      _service.showError('Headline is required (English or Urdu)');
      return;
    }
    if (de.isEmpty && du.isEmpty) {
      _service.showError('Description is required (English or Urdu)');
      return;
    }

    if (_images.isEmpty) {
      _service.showError('Please select at least 1 image');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.createNews(
        headlineEn: he,
        headlineUr: hu,
        descriptionEn: de,
        descriptionUr: du,
        imageFiles: _images,
        isPublished: true,
        language: 'both',
      );

      if (!mounted) return;
      Get.snackbar(
        'Success',
        'News published',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      Get.offAllNamed(AppRoutes.adminDashboard);
    } catch (e) {
      _service.showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      appBar: AppBar(
        title: const Text('Create News'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E6D25), Color(0xFF5D8F3F)],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Image',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2D1F)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4E5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCEE2C5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _images.isEmpty
                            ? const Icon(Icons.image_rounded, color: Color(0xFF4A7C2C))
                            : Image.file(_images.first, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _pickImages,
                        icon: const Icon(Icons.upload_rounded),
                        label: Text(_images.isEmpty ? 'Pick images' : 'Change images'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7C2C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Selected: ${_images.length} image${_images.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2D1F)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Headline (English)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2D1F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _headlineEn,
                  textInputAction: TextInputAction.next,
                  decoration: _input('Enter headline in English'),
                ),
                const SizedBox(height: 12),
                const Text('Headline (Urdu)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2D1F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _headlineUr,
                  textInputAction: TextInputAction.next,
                  decoration: _input('اردو میں ہیڈلائن لکھیں'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description (English)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2D1F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _descEn,
                  maxLines: 5,
                  decoration: _input('Write the full news description...'),
                ),
                const SizedBox(height: 12),
                const Text('Description (Urdu)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2D1F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _descUr,
                  maxLines: 5,
                  decoration: _input('خبر کی مکمل تفصیل لکھیں...'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7C2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Publish News', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCEE2C5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7C2C).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6FBF4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
