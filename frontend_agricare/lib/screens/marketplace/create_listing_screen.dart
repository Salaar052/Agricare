// lib/screens/marketplace/create_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/marketplace_service.dart';
import '../../services/cloudinary_service.dart';
import '../../api/api_config.dart';

class CreateListingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialListing;

  const CreateListingScreen({super.key, this.initialListing});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;
  late final CloudinaryService _cloudinaryService;

  bool get _isEdit => widget.initialListing != null;
  String get _editingItemId => widget.initialListing?['_id']?.toString() ?? '';

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Existing remote images (kept/removed by user) + newly selected images.
  // When uploading completes, newly selected images are converted into URLs and
  // appended into `_imageUrls`.
  final List<String> _imageUrls = [];
  final List<File> _newImages = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  String? _selectedCategory;
  String? _selectedSubcategory;
  String _selectedCondition = 'new';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final Map<String, List<String>> _categories = {
    'Seeds': ['Vegetable Seeds', 'Fruit Seeds', 'Crop Seeds', 'Fodder Seeds'],
    'Fertilizers': ['Organic Fertilizer', 'Chemical Fertilizer', 'Liquid Fertilizer'],
    'Pesticides': ['Insecticides', 'Herbicides', 'Fungicides'],
    'Machinery': ['Tractors', 'Sprayers', 'Harvesters', 'Attachments'],
    'Livestock': ['Cows', 'Goats', 'Buffalo', 'Sheep', 'Poultry'],
  };

  final Map<String, IconData> _categoryIcons = {
    'Seeds': Icons.grass_rounded,
    'Fertilizers': Icons.science_rounded,
    'Pesticides': Icons.pest_control_rounded,
    'Machinery': Icons.agriculture_rounded,
    'Livestock': Icons.pets_rounded,
  };

  // Theme colors
  static const Color _primary = Color(0xFF1B3A0F);
  static const Color _secondary = Color(0xFF3A6B1E);
  static const Color _accent = Color(0xFF5A9E30);
  static const Color _surface = Color(0xFFF2F7EF);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF152B09);
  static const Color _textMid = Color(0xFF4A5E3A);
  static const Color _textLight = Color(0xFF8FA882);
  static const Color _divider = Color(0xFFE2EDD9);
  static const Color _gold = Color(0xFFC8932A);

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _cloudinaryService = CloudinaryService();

    // Prefill fields when editing an existing listing
    final listing = widget.initialListing;
    if (listing != null) {
      _titleController.text = (listing['title'] ?? '').toString();
      _priceController.text = (listing['price'] ?? '').toString();
      _descriptionController.text = (listing['description'] ?? '').toString();

      _selectedCategory = listing['category']?.toString();
      _selectedSubcategory = listing['subcategory']?.toString();
      _selectedCondition = (listing['condition'] ?? 'new').toString();

      final imgs = listing['images'];
      if (imgs is List) {
        _imageUrls
          ..clear()
          ..addAll(imgs.whereType<String>().where((e) => e.trim().isNotEmpty));
      }
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final total = _imageUrls.length + _newImages.length;
    if (total >= 10) {
      _marketplaceService.showError('Maximum 10 images allowed');
      return;
    }
    HapticFeedback.lightImpact();
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if ((_imageUrls.length + _newImages.length) < 10) {
            _newImages.add(File(image.path));
          }
        }
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_newImages.isEmpty) return;
    setState(() => _isUploading = true);
    try {
      for (var imageFile in _newImages) {
        final url = await _cloudinaryService.uploadImage(imageFile);
        _imageUrls.add(url);
      }
      _newImages.clear();
      _marketplaceService.showSuccess('Images uploaded successfully');
    } catch (e) {
      _marketplaceService.showError('Failed to upload images: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty && _newImages.isEmpty) {
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
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      if (_newImages.isNotEmpty) {
        await _uploadImages();
      }

      if (_isEdit) {
        final itemId = _editingItemId;
        if (itemId.isEmpty) {
          throw Exception('Invalid listing id');
        }

        await _marketplaceService.updateMyListing(
          itemId: itemId,
          title: _titleController.text.trim(),
          category: _selectedCategory!,
          subcategory: _selectedSubcategory!,
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          images: List<String>.from(_imageUrls),
          condition: _selectedCondition,
        );
      } else {
        await _marketplaceService.createNewListing(
          title: _titleController.text.trim(),
          category: _selectedCategory!,
          subcategory: _selectedSubcategory!,
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          images: List<String>.from(_imageUrls),
          condition: _selectedCondition,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  // ──────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4EC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(),
            ],
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildUserBadge(),
                  const SizedBox(height: 12),
                  _buildPhotosSection(),
                  const SizedBox(height: 12),
                  _buildFormSection(),
                  const SizedBox(height: 32),
                  _buildPublishButton(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // SLIVER APP BAR
  // ──────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _cardBg,
      surfaceTintColor: Colors.transparent,
      // ✅ Fixed: proper back navigation with arrow icon
      leading: _AnimatedIconButton(
        onTap: () => Navigator.of(context).maybePop(),
        icon: Icons.arrow_back_ios_new_rounded,
        color: _primary,
      ),
      title: Column(
        children: [
          Text(
            _isEdit ? 'Edit Listing' : 'New Listing',
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'AgriCare Marketplace',
            style: TextStyle(
              color: _textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _divider),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _isSubmitting || _isUploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: _secondary,
                    ),
                  ),
                )
              : _AnimatedIconButton(
                  onTap: _submitListing,
                  label: 'Publish',
                  color: _secondary,
                  filled: true,
                ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // USER BADGE
  // ──────────────────────────────────────────
  Widget _buildUserBadge() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_secondary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listing on Marketplace',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded, size: 12, color: _secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Visible to everyone',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: _gold),
                const SizedBox(width: 5),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // PHOTOS SECTION
  // ──────────────────────────────────────────
  Widget _buildPhotosSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: _secondary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (_imageUrls.isEmpty && _newImages.isEmpty)
                      ? _surface
                      : _secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_imageUrls.isEmpty && _newImages.isEmpty)
                        ? _divider
                        : _secondary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_imageUrls.length + _newImages.length}/10',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: (_imageUrls.isEmpty && _newImages.isEmpty)
                        ? _textLight
                        : _secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'First photo will be your main listing image.',
            style: TextStyle(fontSize: 12.5, color: _textLight, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          if (_imageUrls.isEmpty && _newImages.isEmpty)
            _buildEmptyImageArea()
          else
            _buildImageGrid(),
          if (_isUploading) ...[
            const SizedBox(height: 14),
            _buildUploadProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyImageArea() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _secondary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_secondary, _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _secondary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_photo_alternate_rounded, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Photos',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Tap to browse your gallery',
                style: TextStyle(fontSize: 12.5, color: _textLight, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final total = _imageUrls.length + _newImages.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: total + (total < 10 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == total) return _buildAddMoreButton();
        return _buildImageTile(index);
      },
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _secondary.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 26, color: _secondary),
            const SizedBox(height: 3),
            Text(
              'Add',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final isRemote = index < _imageUrls.length;
    final remoteUrl = isRemote ? _imageUrls[index] : null;
    final localIndex = isRemote ? null : (index - _imageUrls.length);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isRemote
              ? Image.network(
                  remoteUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, prog) {
                    if (prog == null) return child;
                    return Container(
                      color: _surface,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _secondary,
                          value: prog.expectedTotalBytes != null
                              ? prog.cumulativeBytesLoaded /
                                  prog.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: _surface,
                    child: const Icon(
                      Icons.image_rounded,
                      color: _textLight,
                      size: 28,
                    ),
                  ),
                )
              : Image.file(_newImages[localIndex!], fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.55), Colors.transparent],
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_secondary, _accent]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MAIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isRemote) {
                  _imageUrls.removeAt(index);
                } else {
                  _newImages.removeAt(localIndex!);
                }
              });
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _secondary),
          ),
          const SizedBox(width: 12),
          Text(
            'Uploading photos…',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMid),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // FORM SECTION
  // ──────────────────────────────────────────
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Item Details', Icons.inventory_2_rounded),
          const SizedBox(height: 18),

          // Title
          _buildPremiumField(
            controller: _titleController,
            label: 'Title',
            hint: 'What are you selling?',
            icon: Icons.edit_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),

          const SizedBox(height: 14),

          // ✅ Fixed: Pakistani Rupees — no Indian rupee icon, using text prefix "PKR"
          _buildPriceField(),

          const SizedBox(height: 22),
          _buildSectionHeader('Classification', Icons.category_rounded),
          const SizedBox(height: 16),

          _buildCategoryPicker(),

          if (_selectedCategory != null) ...[
            const SizedBox(height: 14),
            _buildPremiumDropdown<String>(
              label: 'Subcategory',
              icon: Icons.subdirectory_arrow_right_rounded,
              value: _selectedSubcategory,
              items: _categories[_selectedCategory]!
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubcategory = v),
            ),
          ],

          const SizedBox(height: 14),
          _buildConditionToggle(),

          const SizedBox(height: 22),
          _buildSectionHeader('Description', Icons.notes_rounded),
          const SizedBox(height: 14),

          _buildPremiumField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'Describe condition, age, quantity…',
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ✅ Dedicated price field using PKR currency
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
      decoration: InputDecoration(
        labelText: 'Price',
        hintText: '0.00',
        // PKR prefix as text widget — no Indian rupee icon
        prefix: const Text(
          'PKR  ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _secondary,
          ),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const Icon(Icons.sell_rounded, color: _secondary, size: 20),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textMid,
        ),
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: _textLight,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Price is required';
        if (double.tryParse(v) == null) return 'Enter a valid price';
        return null;
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _divider)),
      ],
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _secondary, size: 20),
        ),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textMid,
        ),
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: _textLight,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        alignLabelWithHint: maxLines != null && maxLines > 1,
      ),
      validator: validator,
    );
  }

  Widget _buildPremiumDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _textDark),
      dropdownColor: _cardBg,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _secondary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _secondary, size: 20),
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMid),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.category_outlined, size: 16, color: _textLight),
              const SizedBox(width: 6),
              Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMid),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.keys.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = cat;
                    _selectedSubcategory = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [_secondary, _accent])
                        : null,
                    color: isSelected ? null : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : _divider,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _secondary.withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _categoryIcons[cat] ?? Icons.category_rounded,
                        size: 15,
                        color: isSelected ? Colors.white : _secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 16, color: _textLight),
              const SizedBox(width: 6),
              Text(
                'Condition',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMid),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _divider),
          ),
          child: Row(
            children: [
              _conditionOption('new', 'Brand New', Icons.fiber_new_rounded),
              _conditionOption('used', 'Used', Icons.recycling_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _conditionOption(String value, String label, IconData icon) {
    final isSelected = _selectedCondition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCondition = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_secondary, _accent])
                : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _secondary.withOpacity(0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: isSelected ? Colors.white : _textLight),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // PUBLISH BUTTON
  // ──────────────────────────────────────────
  Widget _buildPublishButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: _isSubmitting || _isUploading ? null : _submitListing,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: _isSubmitting || _isUploading
                ? LinearGradient(colors: [_textLight.withOpacity(0.35), _textLight.withOpacity(0.25)])
                : const LinearGradient(
                    colors: [_primary, _secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isSubmitting || _isUploading
                ? []
                : [
                    BoxShadow(
                      color: _secondary.withOpacity(0.38),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
          ),
          child: Center(
            child: _isSubmitting || _isUploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEdit ? Icons.save_rounded : Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        _isEdit ? 'Save Changes' : 'Publish Listing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// ANIMATED ICON BUTTON HELPER
// ──────────────────────────────────────────
class _AnimatedIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String? label;
  final Color color;
  final bool filled;

  const _AnimatedIconButton({
    required this.onTap,
    this.icon,
    this.label,
    required this.color,
    this.filled = false,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.label != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: widget.filled
                      ? LinearGradient(
                          colors: [widget.color, const Color(0xFF5A9E30)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: widget.filled ? Colors.white : widget.color,
                    letterSpacing: -0.2,
                  ),
                ),
              )
            : Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7EF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
      ),
    );
  }
}