// File: lib/screens/crop_recommendation/soil_mineral_form_screen.dart

import 'package:flutter/material.dart';
import 'soil_input_field.dart';
import 'growth_plan_screen.dart';
import '../../api/api_config.dart';
import '../../api/crop_recommendation/crop_recommendation_api.dart';

class SoilMineralFormScreen extends StatefulWidget {
  const SoilMineralFormScreen({super.key});

  @override
  State<SoilMineralFormScreen> createState() => _SoilMineralFormScreenState();
}

class _SoilMineralFormScreenState extends State<SoilMineralFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _phController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // ── Pakistan Soil Auto-fill ───────────────────────────────────────────────
  // Research-based typical values for Pakistani agricultural soil (kg/ha):
  //   N ≈ 40  → Pakistani soils are broadly deficient in nitrogen; average
  //             farmer application in Punjab is ~54 kg/acre ≈ 133 kg/ha but
  //             the baseline soil N before fertiliser is low (≈ 40 kg/ha).
  //   P ≈ 30  → Most Pakistani soils are calcareous and deficient in P;
  //             farmer application is ~13 kg/acre ≈ 32 kg/ha; soil P ≈ 30.
  //   K ≈ 200 → Potassium deficiency is less prevalent; Punjab soils typically
  //             show adequate K (199–361 kg/ha range); 200 is a safe median.
  //
  // Sources: AARI Punjab, FAO Pakistan 2025, Nature Scientific Reports 2025,
  //          Punjab crop-nutrition studies (Multan, Gujranwala, Sheikhupura).
  static const double _pkN = 40.0;
  static const double _pkP = 30.0;
  static const double _pkK = 200.0;

  bool _usePakistanDefaults = false;

  void _togglePakistanDefaults(bool value) {
    setState(() {
      _usePakistanDefaults = value;
      if (value) {
        _nitrogenController.text = _pkN.toStringAsFixed(0);
        _phosphorusController.text = _pkP.toStringAsFixed(0);
        _potassiumController.text = _pkK.toStringAsFixed(0);
      } else {
        _nitrogenController.clear();
        _phosphorusController.clear();
        _potassiumController.clear();
      }
    });
  }

  // ── Palette ───────────────────────────────────────────────────────────────
  static const _dark = Color(0xFF1A2F0E);
  static const _mid = Color(0xFF4A7C2C);
  static const _light = Color(0xFF8FAF7A);
  static const _bg = Color(0xFFF4F8F0);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDFEDD3);
  static const _surface = Color(0xFFEDF4E5);

  // Pakistan flag green accent
  static const _pkGreen = Color(0xFF01411C);
  static const _pkBg = Color(0xFFE8F5E3);
  static const _pkBorder = Color(0xFF8FBD7A);

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double> _fadeAnim;
  late List<Animation<double>> _sectionFades;
  late List<Animation<Offset>> _sectionSlides;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // 5 sections: info card + pak-toggle + 3 field groups + button
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sectionFades = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, (s + 0.28).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
    _sectionSlides = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(
            s,
            (s + 0.28).clamp(0, 1),
            curve: Curves.easeOutQuart,
          ),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _staggerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _staggerCtrl.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final soilData = {
        'N': double.parse(_nitrogenController.text),
        'P': double.parse(_phosphorusController.text),
        'K': double.parse(_potassiumController.text),
        'temperature': double.parse(_temperatureController.text),
        'humidity': double.parse(_humidityController.text),
        'ph': double.parse(_phController.text),
        'rainfall': double.parse(_rainfallController.text),
      };

      final jsonData = await CropRecommendationApi.predict(
        n: soilData['N'] as num,
        p: soilData['P'] as num,
        k: soilData['K'] as num,
        temperature: soilData['temperature'] as num,
        humidity: soilData['humidity'] as num,
        ph: soilData['ph'] as num,
        rainfall: soilData['rainfall'] as num,
      );

      setState(() => _isLoading = false);

      if (jsonData['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GrowthPlanScreen(
              cropName: jsonData['recommended_crop'],
              recommendationData: jsonData,
              soilData: soilData,
            ),
          ),
        );
      } else {
        throw Exception(jsonData['error'] ?? 'Prediction failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _formatError(e.toString());
      });
      _showErrorDialog(_errorMessage!);
    }
  }

  String _formatError(String e) {
    if (e.contains('SocketException') || e.contains('Failed host lookup')) {
      return 'Cannot connect to server.\n\n'
          '• Check your internet connection\n'
          '• Backend: ${ApiConfig.backendOrigin}\n'
          '• Crop ML: ${ApiConfig.mlOrigin}';
    }
    if (e.contains('Connection refused')) {
      return 'Server not running.\n\n'
          '• Backend: ${ApiConfig.backendOrigin}\n'
          '• Crop ML: ${ApiConfig.mlOrigin}';
    }
    if (e.contains('timeout')) {
      return 'Request timed out.\n\n'
          '• The AI service took too long\n'
          '• Try again with a stable connection';
    }
    return e.replaceAll('Exception: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _bgCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5A7A45),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: _mid,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pakistan defaults info dialog ─────────────────────────────────────────
  void _showPakistanInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _bgCard,
        title: Row(
          children: [
            const Text('🇵🇰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Pakistan Soil Defaults',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These values reflect the typical nutrient levels found in Pakistani agricultural soil, based on AARI Punjab data, FAO assessments, and published soil studies.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF5A7A45),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            _infoRow(
              'Nitrogen (N)',
              '${_pkN.toStringAsFixed(0)} kg/ha',
              'Low — Pakistani soils are broadly N-deficient',
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Phosphorus (P)',
              '${_pkP.toStringAsFixed(0)} kg/ha',
              'Low — Most soils are calcareous, limiting P availability',
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Potassium (K)',
              '${_pkK.toStringAsFixed(0)} kg/ha',
              'Adequate — Punjab soils typically range 199–361 kg/ha',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _pkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _pkBorder),
              ),
              child: const Text(
                '💡 These are baseline soil values before fertiliser application. If you have a soil test report, use those values instead for better accuracy.',
                style: TextStyle(fontSize: 11.5, color: _pkGreen, height: 1.55),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: _mid,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: _pkGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _pkGreen,
                    ),
                  ),
                ],
              ),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8FAF7A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      _anim(0, _buildInfoCard()),
                      const SizedBox(height: 16),

                      // Pakistan auto-fill toggle
                      _anim(1, _buildPakistanToggleCard()),
                      const SizedBox(height: 24),

                      // Section 1: NPK
                      _anim(
                        2,
                        _buildFieldGroup(
                          title: 'Soil Nutrients (NPK)',
                          icon: Icons.grass_rounded,
                          color: const Color(0xFF16A34A),
                          badge: _usePakistanDefaults
                              ? 'Auto-filled 🇵🇰'
                              : null,
                          fields: [
                            SoilInputField(
                              controller: _nitrogenController,
                              label: 'Nitrogen (N)',
                              hint: 'e.g. 40',
                              icon: Icons.grass_rounded,
                              suffix: 'kg/ha',
                              minValue: 0,
                              maxValue: 140,
                              rangeLabel: '0 – 140',
                              description:
                                  'Amount of nitrogen available in soil.',
                              readOnly: _usePakistanDefaults,
                            ),
                            const SizedBox(height: 16),
                            SoilInputField(
                              controller: _phosphorusController,
                              label: 'Phosphorus (P)',
                              hint: 'e.g. 50',
                              icon: Icons.water_drop_rounded,
                              suffix: 'kg/ha',
                              minValue: 5,
                              maxValue: 145,
                              rangeLabel: '5 – 145',
                              description:
                                  'Phosphorus promotes root development.',
                              readOnly: _usePakistanDefaults,
                            ),
                            const SizedBox(height: 16),
                            SoilInputField(
                              controller: _potassiumController,
                              label: 'Potassium (K)',
                              hint: 'e.g. 43',
                              icon: Icons.eco_rounded,
                              suffix: 'kg/ha',
                              minValue: 5,
                              maxValue: 205,
                              rangeLabel: '5 – 205',
                              description:
                                  'Potassium improves water and disease resistance.',
                              readOnly: _usePakistanDefaults,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Soil properties
                      _anim(
                        3,
                        _buildFieldGroup(
                          title: 'Soil Properties',
                          icon: Icons.science_rounded,
                          color: const Color(0xFF7C3AED),
                          fields: [
                            SoilInputField(
                              controller: _phController,
                              label: 'pH Level',
                              hint: 'e.g. 6.5',
                              icon: Icons.science_rounded,
                              suffix: 'pH',
                              minValue: 0,
                              maxValue: 14,
                              rangeLabel: '0 – 14',
                              description:
                                  'Neutral (7.0) is ideal for most crops. Most crops prefer 6–7.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Environmental
                      _anim(
                        4,
                        _buildFieldGroup(
                          title: 'Environmental Factors',
                          icon: Icons.wb_sunny_rounded,
                          color: const Color(0xFFD97706),
                          fields: [
                            SoilInputField(
                              controller: _temperatureController,
                              label: 'Temperature',
                              hint: 'e.g. 25',
                              icon: Icons.thermostat_rounded,
                              suffix: '°C',
                              minValue: 0,
                              maxValue: 50,
                              rangeLabel: '0 – 50°C',
                              description:
                                  'Average temperature during the growing season.',
                            ),
                            const SizedBox(height: 16),
                            SoilInputField(
                              controller: _humidityController,
                              label: 'Humidity',
                              hint: 'e.g. 82',
                              icon: Icons.water_rounded,
                              suffix: '%',
                              minValue: 14,
                              maxValue: 100,
                              rangeLabel: '14 – 100%',
                              description: 'Relative humidity as a percentage.',
                            ),
                            const SizedBox(height: 16),
                            SoilInputField(
                              controller: _rainfallController,
                              label: 'Rainfall',
                              hint: 'e.g. 202',
                              icon: Icons.grain_rounded,
                              suffix: 'mm',
                              minValue: 20,
                              maxValue: 300,
                              rangeLabel: '20 – 300mm',
                              description:
                                  'Average annual rainfall in millimetres.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit button
                      _anim(5, _buildSubmitButton()),
                    ],
                  ),
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
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: _dark,
            ),
          ),
        ),
      ),
      title: const Text(
        'Soil Mineral Data',
        style: TextStyle(
          color: _dark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
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
            color: _dark.withOpacity(0.2),
            blurRadius: 20,
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
            child: const Icon(
              Icons.science_rounded,
              color: Color(0xFF9DE05A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fill in your soil data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Enter your soil test readings below. Each field shows its accepted range — values outside that range will be flagged.',
                  style: TextStyle(
                    color: Color(0xFF9DB88A),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pakistan toggle card ──────────────────────────────────────────────────
  Widget _buildPakistanToggleCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _usePakistanDefaults ? _pkBg : _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _usePakistanDefaults ? _pkBorder : _border,
          width: _usePakistanDefaults ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _usePakistanDefaults
                ? _pkGreen.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flag + icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _usePakistanDefaults
                  ? _pkGreen.withOpacity(0.12)
                  : _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🇵🇰', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // Label + sub-text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Use Pakistan Soil Values',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _usePakistanDefaults ? _pkGreen : _dark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Info button
                    GestureDetector(
                      onTap: _showPakistanInfoDialog,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _usePakistanDefaults
                              ? _pkGreen.withOpacity(0.15)
                              : _border,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 11,
                          color: _usePakistanDefaults
                              ? _pkGreen
                              : const Color(0xFF8FAF7A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _usePakistanDefaults
                      ? 'N=${_pkN.toStringAsFixed(0)}  P=${_pkP.toStringAsFixed(0)}  K=${_pkK.toStringAsFixed(0)} kg/ha — auto-filled'
                      : "Don't have soil test values? Auto-fill NPK for Pakistan",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _usePakistanDefaults
                        ? _pkGreen.withOpacity(0.75)
                        : const Color(0xFF8FAF7A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Toggle switch
          Switch.adaptive(
            value: _usePakistanDefaults,
            onChanged: _togglePakistanDefaults,
            activeColor: _pkGreen,
            activeTrackColor: _pkBorder,
            inactiveThumbColor: _light,
            inactiveTrackColor: _border,
          ),
        ],
      ),
    );
  }

  // ── Field group card ──────────────────────────────────────────────────────
  Widget _buildFieldGroup({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> fields,
    String? badge,
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Badge shown when auto-fill is active
              if (badge != null)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _pkBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _pkBorder),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _pkGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _border),
          const SizedBox(height: 16),

          // Auto-fill notice strip
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _pkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _pkBorder),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline_rounded, size: 13, color: _pkGreen),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'NPK values are filled with typical Pakistan soil averages. Disable the toggle above to enter custom values.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _pkGreen,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          ...fields,
        ],
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _mid,
              disabledBackgroundColor: _light.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: _mid.withOpacity(0.3),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Analyse & Get Recommendations',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Powered by AI  ·  ${Uri.parse(ApiConfig.mlOrigin).host}',
          style: const TextStyle(fontSize: 10.5, color: Color(0xFFB0C4A0)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Stagger helper ────────────────────────────────────────────────────────
  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _sectionFades[i],
    child: SlideTransition(position: _sectionSlides[i], child: child),
  );
}
