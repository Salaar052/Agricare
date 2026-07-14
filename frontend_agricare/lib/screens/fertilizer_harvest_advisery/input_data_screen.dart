import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/fertilizer_havest_advisert/api_service.dart';
import '../../controllers/auth_controller.dart';
import '../../services/location_service.dart';
import '../../widgets/common_widets.dart';
import '../../utils/theme.dart';
import '../../utils/soil_validation.dart';
import './advisery_screen.dart';
import './harvest_screen.dart';

class FertilizerHarvestAdvisoryInputScreen extends StatefulWidget {
  const FertilizerHarvestAdvisoryInputScreen({super.key});

  @override
  State<FertilizerHarvestAdvisoryInputScreen> createState() =>
      _FertilizerHarvestAdvisoryInputScreenState();
}

class _FertilizerHarvestAdvisoryInputScreenState
    extends State<FertilizerHarvestAdvisoryInputScreen> {
  final _formKey = GlobalKey<FormState>();

  static const String _otherCropKey = '__other__';

  final _nitrogenController = TextEditingController(text: '30');
  final _phosphorusController = TextEditingController(text: '20');
  final _potassiumController = TextEditingController(text: '25');
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _customCropController = TextEditingController();

  bool _isLoading = false;
  bool _weatherLoading = true;
  String? _weatherHint;
  String? _errorMessage;

  String _cropDropdown = 'rice';

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

  @override
  void initState() {
    super.initState();
    _loadLiveWeather();
  }

  Future<void> _loadLiveWeather() async {
    setState(() {
      _weatherLoading = true;
      _weatherHint = null;
    });

    try {
      final auth = Get.find<AuthController>();
      final lat = auth.latitude.value;
      final lng = auth.longitude.value;

      if (lat == 0.0 && lng == 0.0) {
        if (!mounted) return;
        setState(() {
          _temperatureController.text = '28';
          _humidityController.text = '65';
          _weatherHint =
              'Save your location in Profile to use GPS-based weather here.';
          _weatherLoading = false;
        });
        return;
      }

      final w = await _locationService.getWeather(
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      setState(() {
        _temperatureController.text = w.temperature.round().toString();
        _humidityController.text = w.humidity.round().toString();
        _weatherHint = 'Using weather for your saved location.';
        _weatherLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _temperatureController.text = '28';
        _humidityController.text = '65';
        _weatherHint = 'Could not load live weather. Values are editable.';
        _weatherLoading = false;
      });
    }
  }

  String get _effectiveCropName {
    if (_cropDropdown == _otherCropKey) {
      return _customCropController.text.trim();
    }
    return _cropDropdown;
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _customCropController.dispose();
    super.dispose();
  }

  Future<void> _getAdvisory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // parse nutrient inputs and validate ranges
      double nitrogen = double.tryParse(_nitrogenController.text) ?? double.nan;
      double phosphorus =
          double.tryParse(_phosphorusController.text) ?? double.nan;
      double potassium =
          double.tryParse(_potassiumController.text) ?? double.nan;

      final List<String> rangeErrors = [];
      if (nitrogen.isNaN) {
        rangeErrors.add('Enter a valid Nitrogen value');
      } else if (nitrogen < SoilValidation.nitrogenMin ||
          nitrogen > SoilValidation.nitrogenMax) {
        rangeErrors.add(
          'Nitrogen must be between ${SoilValidation.nitrogenMin} and ${SoilValidation.nitrogenMax} mg/kg',
        );
      }
      if (phosphorus.isNaN) {
        rangeErrors.add('Enter a valid Phosphorus value');
      } else if (phosphorus < SoilValidation.phosphorusMin ||
          phosphorus > SoilValidation.phosphorusMax) {
        rangeErrors.add(
          'Phosphorus must be between ${SoilValidation.phosphorusMin} and ${SoilValidation.phosphorusMax} mg/kg',
        );
      }
      if (potassium.isNaN) {
        rangeErrors.add('Enter a valid Potassium value');
      } else if (potassium < SoilValidation.potassiumMin ||
          potassium > SoilValidation.potassiumMax) {
        rangeErrors.add(
          'Potassium must be between ${SoilValidation.potassiumMin} and ${SoilValidation.potassiumMax} mg/kg',
        );
      }

      if (rangeErrors.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = rangeErrors.join('\n');
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getAdvisory(
        crop: _effectiveCropName,
        soil: SoilInput(
          nitrogen: nitrogen,
          phosphorus: phosphorus,
          potassium: potassium,
        ),
        weather: WeatherInput(
          temperature: double.parse(_temperatureController.text),
          humidity: double.parse(_humidityController.text),
        ),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdvisoryResultScreen(result: result)),
      );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '🌾 Agri Advisory',
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
                    _buildSectionCard(
                      title: 'Crop Information',
                      icon: Icons.eco_rounded,
                      color: AppTheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _cropDropdown,
                            decoration: const InputDecoration(
                              labelText: 'Select crop',
                              prefixIcon: Icon(
                                Icons.grass_rounded,
                                color: AppTheme.primary,
                              ),
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
                                hintText: 'e.g. Dragon fruit, gram, mustard…',
                                prefixIcon: Icon(
                                  Icons.edit_note_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (v) {
                                if (_cropDropdown != _otherCropKey) {
                                  return null;
                                }
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your crop name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unlisted crops are sent to AgriCare AI for a short growing note with your advisory.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Soil Nutrients',
                      icon: Icons.landscape_rounded,
                      color: AppTheme.fertilizerColor,
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Range: ${SoilValidation.nitrogenMin} - ${SoilValidation.nitrogenMax} mg/kg',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              NutrientField(
                                label: 'Nitrogen',
                                unit: 'mg/kg',
                                controller: _nitrogenController,
                                icon: Icons.circle,
                                min: SoilValidation.nitrogenMin,
                                max: SoilValidation.nitrogenMax,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Range: ${SoilValidation.phosphorusMin} - ${SoilValidation.phosphorusMax} mg/kg',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              NutrientField(
                                label: 'Phosphorus',
                                unit: 'mg/kg',
                                controller: _phosphorusController,
                                icon: Icons.circle,
                                min: SoilValidation.phosphorusMin,
                                max: SoilValidation.phosphorusMax,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Range: ${SoilValidation.potassiumMin} - ${SoilValidation.potassiumMax} mg/kg',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              NutrientField(
                                label: 'Potassium',
                                unit: 'mg/kg',
                                controller: _potassiumController,
                                icon: Icons.circle,
                                min: SoilValidation.potassiumMin,
                                max: SoilValidation.potassiumMax,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Current weather',
                      icon: Icons.wb_sunny_rounded,
                      color: AppTheme.accentLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _weatherHint ??
                                      'Loading weather from your location…',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              if (_weatherLoading)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Refresh weather',
                                  onPressed: _loadLiveWeather,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: NutrientField(
                                  label: 'Temperature',
                                  unit: '°C',
                                  controller: _temperatureController,
                                  icon: Icons.thermostat_rounded,
                                  validationKind: 'temperature',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: NutrientField(
                                  label: 'Humidity',
                                  unit: '%',
                                  controller: _humidityController,
                                  icon: Icons.water_drop_rounded,
                                  validationKind: 'humidity',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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
                      const SizedBox(height: 16),
                    ],

                    LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _getAdvisory,
                      label: _isLoading
                          ? 'Generating AI Advisory…'
                          : 'Get AI Advisory',
                      icon: Icons.auto_awesome_rounded,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HarvestScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: const Text('Harvest Planner'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        foregroundColor: AppTheme.harvestColor,
                        side: const BorderSide(color: AppTheme.harvestColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

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
}
