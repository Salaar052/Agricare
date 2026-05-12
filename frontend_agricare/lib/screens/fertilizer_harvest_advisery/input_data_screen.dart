import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/fertilizer_havest_advisert/api_service.dart';
import '../../widgets/common_widets.dart';
import '../../utils/theme.dart';
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

  // Controllers
  final _cropController = TextEditingController(text: 'rice');
  final _nitrogenController = TextEditingController(text: '30');
  final _phosphorusController = TextEditingController(text: '20');
  final _potassiumController = TextEditingController(text: '25');
  final _temperatureController = TextEditingController(text: '34');
  final _humidityController = TextEditingController(text: '85');

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _crops = [
    'rice',
    'wheat',
    'maize',
    'cotton',
    'sugarcane',
    'potato',
    'tomato',
  ];

  @override
  void dispose() {
    _cropController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _getAdvisory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getAdvisory(
        crop: _cropController.text.trim(),
        soil: SoilInput(
          nitrogen: double.parse(_nitrogenController.text),
          phosphorus: double.parse(_phosphorusController.text),
          potassium: double.parse(_potassiumController.text),
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
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Harvest Planner',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HarvestScreen()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop Selection
                    _buildSectionCard(
                      title: 'Crop Information',
                      icon: Icons.eco_rounded,
                      color: AppTheme.primary,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _cropController.text,
                            decoration: const InputDecoration(
                              labelText: 'Select Crop',
                              prefixIcon: Icon(
                                Icons.grass_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                            items: _crops
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c[0].toUpperCase() + c.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _cropController.text = v;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Soil Nutrients
                    _buildSectionCard(
                      title: 'Soil Nutrients',
                      icon: Icons.landscape_rounded,
                      color: AppTheme.fertilizerColor,
                      child: Column(
                        children: [
                          NutrientField(
                            label: 'Nitrogen',
                            unit: 'mg/kg',
                            controller: _nitrogenController,
                            icon: Icons.circle,
                          ),
                          const SizedBox(height: 12),
                          NutrientField(
                            label: 'Phosphorus',
                            unit: 'mg/kg',
                            controller: _phosphorusController,
                            icon: Icons.circle,
                          ),
                          const SizedBox(height: 12),
                          NutrientField(
                            label: 'Potassium',
                            unit: 'mg/kg',
                            controller: _potassiumController,
                            icon: Icons.circle,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weather Conditions
                    _buildSectionCard(
                      title: 'Current Weather',
                      icon: Icons.wb_sunny_rounded,
                      color: AppTheme.accentLight,
                      child: Row(
                        children: [
                          Expanded(
                            child: NutrientField(
                              label: 'Temperature',
                              unit: '°C',
                              controller: _temperatureController,
                              icon: Icons.thermostat_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NutrientField(
                              label: 'Humidity',
                              unit: '%',
                              controller: _humidityController,
                              icon: Icons.water_drop_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Error
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

                    // Submit Button
                    LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _getAdvisory,
                      label: 'Get Advisory',
                      icon: Icons.search_rounded,
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
