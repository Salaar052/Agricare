// ============================================
// lib/screens/marketplace/marketplace_register_screen.dart
// Registration form with image upload using Cloudinary
// ============================================

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/marketplace_service.dart';
import '../../services/cloudinary_service.dart';
import '../../api/api_config.dart';
import '../../controllers/marketplace_account_controller.dart';

class MarketplaceRegisterScreen extends StatefulWidget {
  const MarketplaceRegisterScreen({super.key});

  @override
  State<MarketplaceRegisterScreen> createState() =>
      _MarketplaceRegisterScreenState();
}

class _MarketplaceRegisterScreenState extends State<MarketplaceRegisterScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;
  late final CloudinaryService _cloudinaryService;

  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _shopImageUrl = '';
  File? _selectedImage;

  final _imagePicker = ImagePicker();
  final _shopNameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _whatsappFocus = FocusNode();
  final _addressFocus = FocusNode();

  // ── Controllers ──
  late AnimationController _enterController;
  late AnimationController _headerController;
  late AnimationController _rippleController;
  late AnimationController _staggerController;
  late AnimationController _shimmerController;
  late AnimationController _bgOrbitController;

  // ── Enter ──
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Header icon ──
  late Animation<double> _headerFloat;
  late Animation<double> _headerScale;

  // ── Ripple ──
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;

  // ── Stagger (8 items) ──
  late List<Animation<double>> _fieldFades;
  late List<Animation<Offset>> _fieldSlides;

  // ── Shimmer ──
  late Animation<double> _shimmerAnim;

  // ── BG orbit ──
  late Animation<double> _orbitAnim;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _cloudinaryService = CloudinaryService();

    // 1. Screen enter — silky 900ms
    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _enterController, curve: Curves.easeOutQuart));
    _enterController.forward();

    // 2. Header icon breathe
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _headerFloat = Tween<double>(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeInOut));
    _headerScale = Tween<double>(begin: 1.0, end: 1.09).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeInOut));

    // 3. Dual ripple — offset phase
    _rippleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _ripple1 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));
    _ripple2 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _rippleController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    // 4. Stagger — 8 slots
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _fieldFades = List.generate(8, (i) {
      final s = (i * 0.11).clamp(0.0, 0.88);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _staggerController,
          curve: Interval(s, (s + 0.26).clamp(0.0, 1.0),
              curve: Curves.easeOut)));
    });
    _fieldSlides = List.generate(8, (i) {
      final s = (i * 0.11).clamp(0.0, 0.88);
      return Tween<Offset>(
              begin: const Offset(0, 0.22), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(s, (s + 0.26).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart)));
    });
    Future.delayed(
        const Duration(milliseconds: 250), () {
      if (mounted) _staggerController.forward();
    });

    // 5. Button shimmer sweep
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // 6. BG slow orbit
    _bgOrbitController = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _orbitAnim = Tween<double>(begin: 0.0, end: 2 * math.pi)
        .animate(_bgOrbitController);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopDescriptionController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _shopNameFocus.dispose();
    _descriptionFocus.dispose();
    _whatsappFocus.dispose();
    _addressFocus.dispose();
    _enterController.dispose();
    _headerController.dispose();
    _rippleController.dispose();
    _staggerController.dispose();
    _shimmerController.dispose();
    _bgOrbitController.dispose();
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
        try {
          final imageUrl =
              await _cloudinaryService.uploadImage(_selectedImage!);
          setState(() {
            _shopImageUrl = imageUrl;
            _isUploadingImage = false;
          });
        } catch (e) {
          setState(() {
            _selectedImage = null;
            _isUploadingImage = false;
          });
          _marketplaceService
              .showError('Failed to upload image: ${e.toString()}');
        }
      }
    } catch (e) {
      _marketplaceService.showError('Failed to pick image: ${e.toString()}');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PremiumBottomSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading || _isUploadingImage) {
      if (_isUploadingImage) {
        _marketplaceService
            .showError('Please wait for image upload to complete');
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _marketplaceService.registerMarketplaceAccount(
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        shopDescription: _shopDescriptionController.text.trim(),
        shopImage: _shopImageUrl,
      );

      if (Get.isRegistered<MarketplaceAccountController>()) {
        Get.find<MarketplaceAccountController>().setHaveMarketplaceAccount(true);
      }
      if (!mounted) return;

      // Return to Marketplace root inside the persistent bottom-nav shell.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      if (Get.isRegistered<MainNavController>()) {
        Get.find<MainNavController>().navigate(AppRoutes.marketplace);
      } else {
        Get.offAllNamed(AppRoutes.marketplace);
      }
    } catch (e) {
      if (!mounted) return;
      // `MarketplaceService.registerMarketplaceAccount` already displays a
      // user-facing error toast/snackbar.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateShopName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Shop name is required';
    if (value.trim().length < 3) return 'At least 3 characters required';
    if (value.trim().length > 50) return 'Maximum 50 characters allowed';
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    if (value.trim().length < 10) return 'Please enter your complete address';
    return null;
  }

  String? _validateWhatsAppNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'WhatsApp number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[1-9]\d{9,14}$').hasMatch(digits)) {
      return 'Use international format (e.g., +923001234567)';
    }
    return null;
  }

  Widget _staggered(int i, Widget child) => FadeTransition(
        opacity: _fieldFades[i],
        child: SlideTransition(position: _fieldSlides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading || _isUploadingImage) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isUploadingImage
                ? 'Please wait while we upload your image'
                : 'Please wait while we create your account'),
            duration: const Duration(seconds: 2),
          ));
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF4),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2D5016), size: 20),
            onPressed:
              (_isLoading || _isUploadingImage)
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Setup Your Shop',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFE8F0E4)),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── 0. Hero card ──
                      _staggered(0, _buildHeroCard()),
                      const SizedBox(height: 32),

                      // ── 1. Image upload ──
                      _staggered(1, Center(child: _buildImageSection())),
                      const SizedBox(height: 32),

                      // ── 2. Section label ──
                      _staggered(2, _buildSectionLabel()),
                      const SizedBox(height: 18),

                      // ── 3. Shop name ──
                      _staggered(
                          3,
                          _buildField(
                            controller: _shopNameController,
                            focusNode: _shopNameFocus,
                            nextFocus: _descriptionFocus,
                            label: 'Shop Name',
                            hint: 'e.g., GreenHarvest Agro Store',
                            icon: Icons.storefront_rounded,
                            validator: _validateShopName,
                            textInputAction: TextInputAction.next,
                          )),
                      const SizedBox(height: 16),

                      // ── 4. Description ──
                      _staggered(
                          4,
                          _buildField(
                            controller: _shopDescriptionController,
                            focusNode: _descriptionFocus,
                            nextFocus: _whatsappFocus,
                            label: 'Shop Description  (Optional)',
                            hint:
                                'e.g., Fresh organic produce, premium seeds & farming tools — delivered with care.',
                            icon: Icons.edit_note_rounded,
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
                          )),
                      const SizedBox(height: 16),

                      // ── 5. WhatsApp ──
                      _staggered(
                          5,
                          _buildField(
                            controller: _whatsappController,
                            focusNode: _whatsappFocus,
                            nextFocus: _addressFocus,
                            label: 'WhatsApp Number',
                            hint: 'e.g., +923001234567',
                            icon: Icons.phone_rounded,
                            validator: _validateWhatsAppNumber,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          )),
                      const SizedBox(height: 16),

                      // ── 6. Address ──
                      _staggered(
                          6,
                          _buildField(
                            controller: _addressController,
                            focusNode: _addressFocus,
                            label: 'Shop Address',
                            hint:
                                'e.g., Street 12, Model Town, Lahore, Punjab',
                            icon: Icons.location_on_rounded,
                            validator: _validateAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          )),
                      const SizedBox(height: 24),

                      // ── 7. Info + button ──
                      _staggered(
                          7,
                          Column(
                            children: [
                              _buildInfoBanner(),
                              const SizedBox(height: 28),
                              _buildSubmitButton(),
                              const SizedBox(height: 8),
                              _buildFooterNote(),
                            ],
                          )),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Hero Card — animated orbiting bg blobs
  // ──────────────────────────────────────────
  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _orbitAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A0F), Color(0xFF2D5016), Color(0xFF4A7C2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5016).withOpacity(0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF5A9233).withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Orbiting blob 1
              Positioned(
                top: -30 + 18 * math.sin(_orbitAnim.value),
                right: -30 + 18 * math.cos(_orbitAnim.value),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Orbiting blob 2
              Positioned(
                bottom: -20 + 12 * math.cos(_orbitAnim.value + 1.0),
                left: 40 + 12 * math.sin(_orbitAnim.value + 1.0),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated icon block
                  AnimatedBuilder(
                    animation: _headerController,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _headerFloat.value),
                      child: Transform.scale(
                          scale: _headerScale.value, child: child),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.22), width: 1),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Launch Your Shop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Join thousands of farmers already\nearning on AgriCare Market.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 13,
                            height: 1.55,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Stat chips
                        Row(
                          children: [
                            _StatChip(
                                icon: Icons.people_alt_rounded,
                                label: '12K+ Farmers'),
                            const SizedBox(width: 8),
                            _StatChip(
                                icon: Icons.star_rounded,
                                label: '4.9 Rated'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // Image Upload
  // ──────────────────────────────────────────
  Widget _buildImageSection() {
    return Column(
      children: [
        // Label row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C2C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Shop Logo',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D5016),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            // Dual ripple rings
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring 1
                    Opacity(
                      opacity:
                          (1.0 - _ripple1.value).clamp(0.0, 0.5),
                      child: Transform.scale(
                        scale: 0.88 + _ripple1.value * 0.30,
                        child: Container(
                          width: 158,
                          height: 158,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4A7C2C)
                                  .withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Ring 2 — offset phase
                    Opacity(
                      opacity:
                          (1.0 - _ripple2.value).clamp(0.0, 0.25),
                      child: Transform.scale(
                        scale: 0.88 + _ripple2.value * 0.42,
                        child: Container(
                          width: 158,
                          height: 158,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5A9233)
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Image circle
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: const Color(0xFF4A7C2C), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D5016).withOpacity(0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: _isUploadingImage
                    ? Container(
                        color: const Color(0xFFF5F9F3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4A7C2C)),
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : _shopImageUrl.isNotEmpty
                            ? Image.network(
                                _shopImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (ctx, child, prog) {
                                  if (prog == null) return child;
                                  return Container(
                                    color: const Color(0xFFF5F9F3),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF4A7C2C)),
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) =>
                                    _placeholderIcon(),
                              )
                            : _placeholderIcon(),
              ),
            ),
            // Camera badge
            if (!_isUploadingImage)
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A9233), Color(0xFF2D5016)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border:
                          Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5016).withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _shopImageUrl.isEmpty
              ? 'Tap to upload your brand logo'
              : 'Tap to change your logo',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A9B6A),
            fontStyle: FontStyle.italic,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }

  Widget _placeholderIcon() => Container(
        color: const Color(0xFFF5F9F3),
        child: Center(
          child: Icon(Icons.storefront_rounded,
              size: 50, color: const Color(0xFF4A7C2C).withOpacity(0.22)),
        ),
      );

  // ──────────────────────────────────────────
  // Section Label
  // ──────────────────────────────────────────
  Widget _buildSectionLabel() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5016), Color(0xFF5A9233)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Shop Details',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D5016),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE3EFD9),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Text Field — premium card style
  // ──────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5016).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted ??
            (nextFocus != null
                ? (_) => FocusScope.of(context).requestFocus(nextFocus)
                : null),
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1E3A0F),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: const Color(0xFF4A7C2C), size: 21),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE3EFD9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFE3EFD9), width: 1.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFF4A7C2C), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 18, vertical: maxLines > 1 ? 18 : 20),
          labelStyle: const TextStyle(
            color: Color(0xFF6B8F5E),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          hintStyle: TextStyle(
            color: const Color(0xFF4A7C2C).withOpacity(0.30),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Info Banner
  // ──────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4EDBC), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C2C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFF4A7C2C), size: 15),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your name & contact details will be\nautomatically linked from your profile.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF4A6B35),
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Submit Button — shimmer + depth
  // ──────────────────────────────────────────
  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5016), Color(0xFF4A7C2C), Color(0xFF5A9233)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5016).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF5A9233).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || _isUploadingImage) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: const Color(0xFF4A7C2C).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shimmer sweep
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Align(
                          alignment:
                              Alignment(_shimmerAnim.value, 0),
                          child: Container(
                            width: 80,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.rocket_launch_rounded,
                              size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Launch My Marketplace',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // Footer note
  // ──────────────────────────────────────────
  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded,
              size: 12, color: const Color(0xFF7A9B6A).withOpacity(0.7)),
          const SizedBox(width: 5),
          Text(
            'Secure  ·  Free to join  ·  Cancel anytime',
            style: TextStyle(
              fontSize: 11.5,
              color: const Color(0xFF7A9B6A).withOpacity(0.8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Stat chip inside hero card
// ──────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Premium Bottom Sheet
// ──────────────────────────────────────────
class _PremiumBottomSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PremiumBottomSheet(
      {required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EFD9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C2C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_search_rounded,
                        color: Color(0xFF4A7C2C), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Upload Shop Logo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D5016),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Square images work best',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A9B6A)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE8F0E4), height: 1),
              const SizedBox(height: 16),
              _SheetTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                subtitle: 'Use your camera right now',
                onTap: onCamera,
              ),
              const SizedBox(height: 10),
              _SheetTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                subtitle: 'Browse your saved photos',
                onTap: onGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE3EFD9), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C2C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4A7C2C), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5016))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFF7A9B6A))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFF7A9B6A)),
          ],
        ),
      ),
    );
  }
}