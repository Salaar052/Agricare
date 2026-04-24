// ============================================
// lib/screens/marketplace/marketplace_register_screen.dart
// Registration form with image upload using Cloudinary
// ============================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/marketplace_service.dart';
import '../../services/cloudinary_service.dart';

class MarketplaceRegisterScreen extends StatefulWidget {
  const MarketplaceRegisterScreen({super.key});

  @override
  State<MarketplaceRegisterScreen> createState() => _MarketplaceRegisterScreenState();
}

class _MarketplaceRegisterScreenState extends State<MarketplaceRegisterScreen> {
  late final MarketplaceService _marketplaceService;
  late final CloudinaryService _cloudinaryService;
  
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _shopImageUrl = '';
  File? _selectedImage;
  
  final _imagePicker = ImagePicker();
  
  // Focus nodes for better UX
  final _shopNameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _addressFocus = FocusNode();

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
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _addressController.dispose();
    _shopNameFocus.dispose();
    _descriptionFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingImage = true;
        });

        // Upload to Cloudinary
        try {
          final imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
          
          setState(() {
            _shopImageUrl = imageUrl;
            _isUploadingImage = false;
          });

          _marketplaceService.showSuccess('Image uploaded successfully!');
        } catch (e) {
          setState(() {
            _selectedImage = null;
            _isUploadingImage = false;
          });
          _marketplaceService.showError('Failed to upload image: ${e.toString()}');
        }
      }
    } catch (e) {
      _marketplaceService.showError('Failed to pick image: ${e.toString()}');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C2C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF4A7C2C)),
                  ),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C2C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Color(0xFF4A7C2C)),
                  ),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent double submission
    if (_isLoading || _isUploadingImage) {
      if (_isUploadingImage) {
        _marketplaceService.showError('Please wait for image upload to complete');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _marketplaceService.registerMarketplaceAccount(
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        shopDescription: _shopDescriptionController.text.trim(),
        shopImage: _shopImageUrl,
      );

      if (!mounted) return;

      // Show success message
      _marketplaceService.showSuccess('Marketplace account created successfully!');

      // Navigate back to marketplace (will now show products screen)
      Get.back();
      Get.back(); // Go back twice to refresh marketplace screen
      Get.toNamed('/marketplace');
      
    } catch (e) {
      if (!mounted) return;
      
      _marketplaceService.showError(
        e.toString().replaceAll('Exception: ', '')
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateShopName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Shop name is required';
    }
    if (value.trim().length < 3) {
      return 'Shop name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Shop name must be less than 50 characters';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading || _isUploadingImage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isUploadingImage 
                ? 'Please wait while we upload your image'
                : 'Please wait while we create your account'),
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
            onPressed: (_isLoading || _isUploadingImage) ? null : () => Get.back(),
          ),
          title: const Text(
            'Setup Marketplace',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE0E0E0),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  
                  const SizedBox(height: 28),

                  // Profile Image Section
                  Center(child: _buildImageUploadSection()),
                  
                  const SizedBox(height: 28),

                  // Form Section Header
                  const Text(
                    'Shop Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Shop Name
                  _buildTextField(
                    controller: _shopNameController,
                    focusNode: _shopNameFocus,
                    nextFocus: _descriptionFocus,
                    label: 'Shop Name',
                    hint: 'e.g., GreenGrow Agro Store',
                    icon: Icons.store,
                    validator: _validateShopName,
                    textInputAction: TextInputAction.next,
                  ),
                  
                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _shopDescriptionController,
                    focusNode: _descriptionFocus,
                    nextFocus: _addressFocus,
                    label: 'Description (Optional)',
                    hint: 'Tell customers about your products and services',
                    icon: Icons.description,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),
                  
                  const SizedBox(height: 16),

                  // Address
                  _buildTextField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    label: 'Address',
                    hint: 'Enter your complete address',
                    icon: Icons.location_on,
                    validator: _validateAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  const SizedBox(height: 24),

                  // Info Banner
                  _buildInfoBanner(),

                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5016), Color(0xFF4A7C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5016).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Your Shop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start selling your agricultural products to the community',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        const Text(
          'Shop Logo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            // Image Circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF4A7C2C),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D5016).withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: _isUploadingImage
                    ? Container(
                        color: const Color(0xFFF5F9F3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C2C)),
                          ),
                        ),
                      )
                    : _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : _shopImageUrl.isNotEmpty
                            ? Image.network(
                                _shopImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color(0xFFF5F9F3),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C2C)),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderIcon();
                                },
                              )
                            : _buildPlaceholderIcon(),
              ),
            ),
            
            // Upload Button
            if (!_isUploadingImage)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A7C2C), Color(0xFF2D5016)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5016).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _shopImageUrl.isEmpty ? 'Tap to add shop logo' : 'Tap to change logo',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF666666),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: const Color(0xFFF5F9F3),
      child: Center(
        child: Icon(
          Icons.store,
          size: 60,
          color: const Color(0xFF4A7C2C).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted ?? (nextFocus != null 
          ? (_) => FocusScope.of(context).requestFocus(nextFocus)
          : null),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF4A7C2C), size: 22),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A7C2C), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 18,
          ),
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
          hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your contact information (name, email) will be automatically added from your profile.',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF663C00),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_isLoading || _isUploadingImage) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A7C2C),
          disabledBackgroundColor: const Color(0xFF4A7C2C).withOpacity(0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Create Marketplace Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}