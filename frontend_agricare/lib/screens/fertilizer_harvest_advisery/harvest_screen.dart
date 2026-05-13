import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/fertilizer_havest_advisert/api_service.dart';
import '../../controllers/auth_controller.dart';
import '../../services/location_service.dart';
import '../../widgets/common_widets.dart';
import '../../utils/theme.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  static const String _otherCropKey = '__other__';

  final _formKey = GlobalKey<FormState>();
  String _cropDropdown = 'rice';
  final _customCropController = TextEditingController();

  bool _isLoading = false;
  bool _forecastLoading = true;
  String? _forecastHint;
  String? _errorMessage;
  HarvestResult? _result;

  final List<Map<String, TextEditingController>> _forecastDays = List.generate(
    3,
    (i) => {
      'temp': TextEditingController(text: '28'),
      'rain': TextEditingController(text: '0'),
    },
  );

  final List<String> _presetCrops = const [
    'rice',
    'wheat',
    'maize',
    'cotton',
    'sugarcane',
    'potato',
    'tomato',
  ];

  final LocationService _locationService = LocationService();

  String get _effectiveCropName {
    if (_cropDropdown == _otherCropKey) {
      return _customCropController.text.trim();
    }
    return _cropDropdown;
  }

  @override
  void initState() {
    super.initState();
    _loadLiveForecast();
  }

  Future<void> _loadLiveForecast() async {
    setState(() {
      _forecastLoading = true;
      _forecastHint = null;
    });

    try {
      final auth = Get.find<AuthController>();
      final lat = auth.latitude.value;
      final lng = auth.longitude.value;

      if (lat == 0.0 && lng == 0.0) {
        if (!mounted) return;
        setState(() {
          _forecastHint =
              'Save your location in Profile to auto-fill a 3-day forecast.';
          _forecastLoading = false;
        });
        return;
      }

      final rows = await _locationService.getDailyMaxTempAndPrecip(
        latitude: lat,
        longitude: lng,
        days: 3,
      );

      if (!mounted) return;
      for (var i = 0; i < _forecastDays.length && i < rows.length; i++) {
        _forecastDays[i]['temp']!.text = rows[i].temp.round().toString();
        _forecastDays[i]['rain']!.text = rows[i].rain.toStringAsFixed(1);
      }
      setState(() {
        _forecastHint = 'Forecast from Open-Meteo for your saved location.';
        _forecastLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _forecastHint = 'Could not load forecast. You can edit values manually.';
        _forecastLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final day in _forecastDays) {
      day['temp']?.dispose();
      day['rain']?.dispose();
    }
    _customCropController.dispose();
    super.dispose();
  }

  Future<void> _getHarvestSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final forecast = _forecastDays
          .map(
            (day) => ForecastDay(
              temp: double.parse(day['temp']!.text),
              rain: double.parse(day['rain']!.text),
            ),
          )
          .toList();

      final result = await ApiService.getHarvestSuggestion(
        crop: _effectiveCropName,
        forecast: forecast,
      );

      setState(() => _result = result);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar matching the advisory screen style ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '🗓️ Harvest Planner',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B4332), AppTheme.primary],
                  ),
                ),
                child: Opacity(
                  opacity: 0.08,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                    ),
                    itemBuilder: (_, __) =>
                        const Icon(Icons.grass, color: Colors.white),
                  ),
                ),
              ),
            ),

          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info banner ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.85),
                            AppTheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '🌾',
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Harvest Timing',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'Uses live 3-day weather when your location is set',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Crop card ──
                    _buildSectionCard(
                      title: 'Select crop',
                      icon: Icons.eco_rounded,
                      color: AppTheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _cropDropdown,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.grass_rounded,
                                color: AppTheme.primary,
                              ),
                              labelText: 'Crop',
                            ),
                            items: [
                              ..._presetCrops.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c[0].toUpperCase() + c.substring(1),
                                  ),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: _otherCropKey,
                                child: Text('Other — type your crop'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _cropDropdown = v);
                            },
                          ),
                          if (_cropDropdown == _otherCropKey) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _customCropController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Crop name',
                                hintText: 'e.g. Barley, moong, citrus…',
                                prefixIcon: Icon(
                                  Icons.edit_note_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (v) {
                                if (_cropDropdown != _otherCropKey) return null;
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your crop name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Forecast card ──
                    _buildSectionCard(
                      title: '3-Day Weather Forecast',
                      icon: Icons.wb_sunny_rounded,
                      color: AppTheme.accentLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _forecastHint ??
                                      'Daily max temperature and total rain (mm)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(
                            _forecastDays.length,
                            (i) => _buildForecastRow(i),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Error banner ──
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Submit button ──
                    LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _getHarvestSuggestion,
                      label: 'Get Harvest Suggestion',
                      icon: Icons.calendar_month_rounded,
                      // no color override → uses default AppTheme.primary
                    ),

                    // ── Result card ──
                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      _buildResultCard(_result!),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared section card (mirrors advisory screen) ──
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, icon: icon, color: color),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildForecastRow(int index) {
    final icons = ['☀️', '🌤️', '🌧️'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${icons[index % icons.length]} Day ${index + 1}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _forecastDays[index]['temp'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Temp (°C)',
                    prefixIcon: Icon(
                      Icons.thermostat_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty || double.tryParse(v) == null)
                          ? 'Required'
                          : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _forecastDays[index]['rain'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rain (mm)',
                    prefixIcon: Icon(
                      Icons.water_drop_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty || double.tryParse(v) == null)
                          ? 'Required'
                          : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(HarvestResult result) {
    final adjustment = result.adjustmentDays;
    final adjustmentText = adjustment == 0
        ? 'No adjustment'
        : adjustment < 0
            ? '${adjustment.abs()} days earlier'
            : '$adjustment days later';
    final adjustmentColor = adjustment < 0
        ? Colors.orange
        : adjustment > 0
            ? Colors.blue
            : AppTheme.primary;

    final insight = result.cropInsight?.trim();
    final displayCrop =
        (result.cropDisplayName?.trim().isNotEmpty == true)
            ? result.cropDisplayName!.trim()
            : result.crop;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Harvest Recommendation',
              icon: Icons.agriculture_rounded,
              color: AppTheme.primary,
            ),

            if (insight != null && insight.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI note — $displayCrop',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Harvest date banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.12),
                    AppTheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Recommended Harvest Date',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.harvestDate,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InfoChip(
                    label: adjustmentText,
                    color: adjustmentColor,
                    icon: adjustment < 0
                        ? Icons.arrow_upward_rounded
                        : adjustment > 0
                            ? Icons.arrow_downward_rounded
                            : Icons.check_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(
              Icons.event_rounded,
              'Base Date',
              result.baseDate,
              Colors.grey,
            ),
            const Divider(height: 20),
            _buildInfoRow(
              Icons.lightbulb_rounded,
              'Advice',
              result.advice,
              AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}