// File: lib/screens/crop_recommendation/lab_report_upload_screen.dart
//
// Flow:
//   1. User picks an image (camera or gallery)
//   2. We send base64 image to Anthropic Claude vision API to extract
//      N, P, K, pH, temperature, humidity, rainfall from the report
//   3. Extracted values pre-fill the same 7 editable fields
//   4. User reviews / corrects values, then taps "Analyse"
//   5. Same POST /crop-recommendation/recommend request as manual form
//   6. Navigates to GrowthPlanScreen on success
//
// Dependencies to add to pubspec.yaml:
//   image_picker: ^1.0.7
//   http: ^1.2.1   (already used elsewhere)

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'growth_plan_screen.dart';
import '../../api/api_config.dart';
import 'soil_input_field.dart';

class LabReportUploadScreen extends StatefulWidget {
  const LabReportUploadScreen({super.key});

  @override
  State<LabReportUploadScreen> createState() => _LabReportUploadScreenState();
}

class _LabReportUploadScreenState extends State<LabReportUploadScreen>
    with TickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _dark    = Color(0xFF1A2F0E);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF8FAF7A);
  static const _bg      = Color(0xFFF4F8F0);
  static const _bgCard  = Color(0xFFFFFFFF);
  static const _border  = Color(0xFFDFEDD3);
  static const _surface = Color(0xFFEDF4E5);
  static const _blue    = Color(0xFF0284C7);
  static const _blueBg  = Color(0xFFE0F2FE);
  static const _blueBorder = Color(0xFFBAE6FD);

  // ── State ─────────────────────────────────────────────────────────────────
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool    _isExtracting = false; // AI reading the image
  bool    _isSubmitting = false; // sending to crop API
  bool    _fieldsReady  = false; // extraction done, show form
  String? _extractError;
  String? _submitError;
  String? _extractionNote; // any note from AI (e.g. "some fields not found")

  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  // Controllers — same 7 fields as manual form
  final _N   = TextEditingController();
  final _P   = TextEditingController();
  final _K   = TextEditingController();
  final _ph  = TextEditingController();
  final _tmp = TextEditingController();
  final _hum = TextEditingController();
  final _rnf = TextEditingController();

  // Track which fields were auto-filled vs empty (for highlighting)
  final Set<String> _autoFilled = {};

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _formCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  String get _apiUrl => ApiConfig.apiV1('/crop-recommendation/recommend');

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _formFade = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _formSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _formCtrl.dispose();
    _N.dispose(); _P.dispose(); _K.dispose(); _ph.dispose();
    _tmp.dispose(); _hum.dispose(); _rnf.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // Backend limit is 5MB. Enforce early to avoid slow uploads.
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.lengthInBytes > maxBytes) {
        throw Exception('Image is too large. Please upload a file under 5MB.');
      }

      String filename = '';
      try {
        filename = picked.name;
      } catch (_) {
        filename = '';
      }
      filename = filename.trim();
      if (filename.isEmpty) {
        final tail = picked.path.split('/').last.trim();
        filename = tail.isNotEmpty ? tail : 'lab_report.jpg';
      }
      if (!filename.contains('.')) {
        // Ensure an extension exists so backend can infer type when content-type is octet-stream.
        filename = '$filename.jpg';
      }

      setState(() {
        _imageBytes = bytes;
        _imageFilename = filename;
        _fieldsReady  = false;
        _extractError = null;
        _extractionNote = null;
        _autoFilled.clear();
        _formCtrl.reset();
        // clear old values
        for (final c in [_N, _P, _K, _ph, _tmp, _hum, _rnf]) {
          c.clear();
        }
      });
      await _extractValues();
    } catch (e) {
      setState(() => _extractError = 'Could not open image: $e');
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _dark),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    color: _mid,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: _blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ── AI extraction via Anthropic API ──────────────────────────────────────
  Future<void> _extractValues() async {
    if (_imageBytes == null) return;
    setState(() { _isExtracting = true; _extractError = null; });

    try {
      // Send to backend for extraction (keeps API keys off the mobile app)
      final uri = Uri.parse(ApiConfig.apiV1('/crop-recommendation/extract-lab-report'));
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: _imageFilename ?? 'lab_report.jpg',
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        try {
          final err = jsonDecode(response.body);
          final apiError = err['error'] ?? err['message'];
          if (apiError == 'not_a_soil_report') {
            throw Exception(
              'This image does not appear to be a soil test report. Please upload a valid lab certificate.',
            );
          }
          throw Exception(apiError ?? 'AI service error ${response.statusCode}');
        } catch (_) {
          throw Exception('AI service error ${response.statusCode}');
        }
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        throw Exception(body['error'] ?? 'Failed to extract values');
      }

      final Map<String, dynamic> extracted =
          Map<String, dynamic>.from(body['extracted'] ?? {});

      if (extracted.containsKey('error')) {
        throw Exception(
          'This image does not appear to be a soil test report. Please upload a valid lab certificate.',
        );
      }

      // ── Fill controllers ────────────────────────────────────────────────
      void fill(TextEditingController ctrl, String key, String fieldName) {
        final val = extracted[key];
        if (val != null) {
          ctrl.text = val.toString();
          _autoFilled.add(fieldName);
        }
      }

      setState(() {
        _autoFilled.clear();
        fill(_N,   'N',           'N');
        fill(_P,   'P',           'P');
        fill(_K,   'K',           'K');
        fill(_ph,  'ph',          'ph');
        fill(_tmp, 'temperature', 'tmp');
        fill(_hum, 'humidity',    'hum');
        fill(_rnf, 'rainfall',    'rnf');

        // Build a note about missing fields
        final missing = <String>[];
        if (_N.text.isEmpty)   missing.add('Nitrogen');
        if (_P.text.isEmpty)   missing.add('Phosphorus');
        if (_K.text.isEmpty)   missing.add('Potassium');
        if (_ph.text.isEmpty)  missing.add('pH');
        if (_tmp.text.isEmpty) missing.add('Temperature');
        if (_hum.text.isEmpty) missing.add('Humidity');
        if (_rnf.text.isEmpty) missing.add('Rainfall');

        _extractionNote = missing.isEmpty
            ? null
            : 'Could not read: ${missing.join(', ')}. Please fill these in manually.';

        _isExtracting = false;
        _fieldsReady  = true;
      });

      _formCtrl.forward();
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _extractError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Submit to crop-recommendation API ────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _submitError = null; });

    try {
      final soilData = {
        'N':           double.parse(_N.text),
        'P':           double.parse(_P.text),
        'K':           double.parse(_K.text),
        'temperature': double.parse(_tmp.text),
        'humidity':    double.parse(_hum.text),
        'ph':          double.parse(_ph.text),
        'rainfall':    double.parse(_rnf.text),
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(soilData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GrowthPlanScreen(
                cropName: json['recommended_crop'],
                recommendationData: json,
                soilData: soilData,
              ),
            ),
          );
        } else {
          throw Exception(json['error'] ?? 'Prediction failed');
        }
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submitError  = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildUploadZone(),
                    if (_isExtracting) ...[
                      const SizedBox(height: 20),
                      _buildExtractionLoader(),
                    ],
                    if (_extractError != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(_extractError!, onRetry: () =>
                          _extractValues()),
                    ],
                    if (_fieldsReady) ...[
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: _buildExtractedForm(),
                        ),
                      ),
                    ],
                    if (_submitError != null) ...[
                      const SizedBox(height: 14),
                      _buildErrorBanner(_submitError!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bgCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _surface, shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _dark),
          ),
        ),
      ),
      title: const Text(
        'Upload Lab Report',
        style: TextStyle(
          color: _dark, fontSize: 18,
          fontWeight: FontWeight.w800, letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.2), blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6BAE3E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: Color(0xFF9DE05A), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-powered report scanning',
                  style: TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w800, letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Take a photo or upload your soil test certificate. Our AI will automatically extract N, P, K, pH and environmental values for you.',
                  style: TextStyle(
                    color: Color(0xFF9DB88A), fontSize: 12.5, height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload zone ───────────────────────────────────────────────────────────
  Widget _buildUploadZone() {
    if (_imageBytes != null && !_isExtracting) {
      return _buildImagePreview();
    }
    return GestureDetector(
      onTap: _showSourceSheet,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _blue.withOpacity(0.35),
            width: 1.5,
            // Dashed border via CustomPainter would be ideal but we use solid
            // with a subtle blue tint for simplicity in Flutter
          ),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.05),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _blueBg, shape: BoxShape.circle,
                border: Border.all(color: _blueBorder),
              ),
              child: const Icon(Icons.upload_rounded, color: _blue, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tap to upload or take a photo',
              style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w700, color: _dark),
            ),
            const SizedBox(height: 5),
            Text(
              'JPG, PNG — soil test certificate or lab report',
              style: TextStyle(
                  fontSize: 12, color: _light, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniSourceChip(Icons.camera_alt_rounded, 'Camera'),
                const SizedBox(width: 8),
                _miniSourceChip(Icons.photo_library_rounded, 'Gallery'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniSourceChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _blueBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _blueBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _blue),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _blue)),
          ],
        ),
      );

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            // Overlay bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF86EFAC), size: 16),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'Image uploaded',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSourceSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Extraction loader ─────────────────────────────────────────────────────
  Widget _buildExtractionLoader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blueBorder),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _blueBg, borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: _blue),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading your lab report…',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _dark),
                ),
                SizedBox(height: 3),
                Text(
                  'AI is scanning for soil values. This takes a few seconds.',
                  style: TextStyle(
                      fontSize: 12.5, color: _light, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String msg, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.error_rounded,
                color: Color(0xFFDC2626), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B)),
                ),
                const SizedBox(height: 3),
                Text(msg,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFDC2626), height: 1.5)),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Extracted form ────────────────────────────────────────────────────────
  Widget _buildExtractedForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success / partial banner
          _buildExtractionStatus(),
          const SizedBox(height: 20),

          // ── NPK group ───────────────────────────────────────────────────
          _fieldGroup(
            title: 'Soil Nutrients (NPK)',
            icon: Icons.grass_rounded,
            color: const Color(0xFF16A34A),
            children: [
              _field(_N, 'N', 'Nitrogen (N)', 'e.g. 40', Icons.grass_rounded,
                  'kg/ha', 0, 140, '0 – 140',
                  'Amount of nitrogen in soil.'),
              const SizedBox(height: 16),
              _field(_P, 'P', 'Phosphorus (P)', 'e.g. 50',
                  Icons.water_drop_rounded, 'kg/ha', 5, 145, '5 – 145',
                  'Promotes root development.'),
              const SizedBox(height: 16),
              _field(_K, 'K', 'Potassium (K)', 'e.g. 43',
                  Icons.eco_rounded, 'kg/ha', 5, 205, '5 – 205',
                  'Improves water and disease resistance.'),
            ],
          ),
          const SizedBox(height: 14),

          // ── pH group ────────────────────────────────────────────────────
          _fieldGroup(
            title: 'Soil Properties',
            icon: Icons.science_rounded,
            color: const Color(0xFF7C3AED),
            children: [
              _field(_ph, 'ph', 'pH Level', 'e.g. 6.5',
                  Icons.science_rounded, 'pH', 0, 14, '0 – 14',
                  'Neutral (7.0) is ideal for most crops.'),
            ],
          ),
          const SizedBox(height: 14),

          // ── Environmental group ─────────────────────────────────────────
          _fieldGroup(
            title: 'Environmental Factors',
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFD97706),
            children: [
              _field(_tmp, 'tmp', 'Temperature', 'e.g. 25',
                  Icons.thermostat_rounded, '°C', 0, 50, '0 – 50°C',
                  'Average growing season temperature.'),
              const SizedBox(height: 16),
              _field(_hum, 'hum', 'Humidity', 'e.g. 82',
                  Icons.water_rounded, '%', 14, 100, '14 – 100%',
                  'Relative humidity percentage.'),
              const SizedBox(height: 16),
              _field(_rnf, 'rnf', 'Rainfall', 'e.g. 202',
                  Icons.grain_rounded, 'mm', 20, 300, '20 – 300mm',
                  'Average annual rainfall.'),
            ],
          ),
          const SizedBox(height: 28),

          // ── Submit button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mid,
                disabledBackgroundColor: _light.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Analyse & Get Recommendations',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.2,
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

  Widget _buildExtractionStatus() {
    final hasWarning = _extractionNote != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasWarning
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWarning
              ? const Color(0xFFFDE68A)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: hasWarning
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              hasWarning
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              size: 16,
              color: hasWarning
                  ? const Color(0xFFD97706)
                  : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWarning
                      ? 'Partial extraction'
                      : 'All values extracted',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasWarning
                        ? const Color(0xFF92400E)
                        : const Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasWarning
                      ? _extractionNote!
                      : 'AI successfully read all 7 soil values. Review them below and tap Analyse when ready.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: hasWarning
                        ? const Color(0xFFB45309)
                        : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Field group card ──────────────────────────────────────────────────────
  Widget _fieldGroup({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: _dark, letterSpacing: -0.2,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _border),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Individual field ──────────────────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String key,
    String label,
    String hint,
    IconData icon,
    String suffix,
    double min,
    double max,
    String range,
    String desc,
  ) {
    final wasAutoFilled = _autoFilled.contains(key);
    return Stack(
      children: [
        SoilInputField(
          controller: ctrl,
          label: label,
          hint: hint,
          icon: icon,
          suffix: suffix,
          minValue: min,
          maxValue: max,
          rangeLabel: range,
          description: desc,
        ),
        // Auto-fill indicator badge
        if (wasAutoFilled)
          Positioned(
            top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _blueBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blueBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high_rounded,
                      size: 10, color: _blue),
                  SizedBox(width: 3),
                  Text(
                    'Auto-filled',
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: _blue),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}