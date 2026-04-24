// lib/screens/marketplace/create_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend_agricare/screens/marketplace/marketplace_profile_screen.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/marketplace_service.dart';
import '../../services/cloudinary_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  late final MarketplaceService _marketplaceService;
  late final CloudinaryService _cloudinaryService;
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isSubmitting = false;
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _selectedCondition = 'new';
  
  final Map<String, List<String>> _categories = {
    'Seeds': ['Vegetable Seeds', 'Fruit Seeds', 'Crop Seeds', 'Fodder Seeds'],
    'Fertilizers': ['Organic Fertilizer', 'Chemical Fertilizer', 'Liquid Fertilizer'],
    'Pesticides': ['Insecticides', 'Herbicides', 'Fungicides'],
    'Machinery': ['Tractors', 'Sprayers', 'Harvesters', 'Attachments'],
    'Livestock': ['Cows', 'Goats', 'Buffalo', 'Sheep', 'Poultry'],
  };

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _cloudinaryService = CloudinaryService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) {
      _marketplaceService.showError('Maximum 10 images allowed');
      return;
    }
    
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    
    if (images != null && images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;
    
    setState(() => _isUploading = true);
    
    try {
      _uploadedImageUrls.clear();
      
      for (var imageFile in _selectedImages) {
        final url = await _cloudinaryService.uploadImage(imageFile);
        _uploadedImageUrls.add(url);
      }
      
      _marketplaceService.showSuccess('Images uploaded successfully');
    } catch (e) {
      _marketplaceService.showError('Failed to upload images: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      _marketplaceService.showError('Please add at least one image');
      return;
    }
    
    if (_selectedCategory == null) {
      _marketplaceService.showError('Please select a category');
      return;
    }
    
    if (_selectedSubcategory == null) {
      _marketplaceService.showError('Please select a subcategory');
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      // Upload images first if not already uploaded
      if (_uploadedImageUrls.isEmpty) {
        await _uploadImages();
      }
      
      // Create listing
     await _marketplaceService.createNewListing(
      title: _titleController.text.trim(),
      category: _selectedCategory!,
      subcategory: _selectedSubcategory!,
      price: double.parse(_priceController.text),
      description: _descriptionController.text.trim(),
      images: _uploadedImageUrls,
      condition: _selectedCondition,
    );

    // After success → go to Profile screen
    Get.to(() => const MarketplaceProfileScreen());

    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New listing',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting || _isUploading ? null : _submitListing,
            child: Text(
              'Publish',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isSubmitting || _isUploading 
                    ? const Color(0xFFBCC0C4) 
                    : const Color(0xFF1877F2),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              
              // User Info
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE4E6EB),
                      child: const Icon(Icons.person, color: Color(0xFF65676B)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listing on Marketplace',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF050505),
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.public, size: 14, color: Color(0xFF65676B)),
                              SizedBox(width: 4),
                              Text(
                                'Public',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF65676B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Photos Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF050505),
                          ),
                        ),
                        Text(
                          '${_selectedImages.length}/10',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose your listing\'s main photo first.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Image Grid
                    if (_selectedImages.isEmpty)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E6EB)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFF65676B)),
                                SizedBox(height: 8),
                                Text(
                                  'Add photos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF050505),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE4E6EB)),
                                ),
                                child: const Icon(Icons.add, size: 32, color: Color(0xFF65676B)),
                              ),
                            );
                          }
                          
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      if (index < _uploadedImageUrls.length) {
                                        _uploadedImageUrls.removeAt(index);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Main',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    
                    if (_isUploading)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading images...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Form Fields
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What are you selling?',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Price
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '0',
                        prefixText: 'Rs ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.keys.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          _selectedSubcategory = null;
                        });
                      },
                    ),
                    
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 16),
                      
                      // Subcategory
                      DropdownButtonFormField<String>(
                        value: _selectedSubcategory,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories[_selectedCategory]!.map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubcategory = value);
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Condition
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New')),
                        DropdownMenuItem(value: 'used', child: Text('Used')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCondition = value);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Describe your item...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}