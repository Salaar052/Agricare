import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/fertilizer_havest_advisert/api_service.dart';
import '../../widgets/common_widets.dart';
import '../../utils/theme.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCrop = 'rice';
  bool _isLoading = false;
  String? _errorMessage;
  HarvestResult? _result;

  // Default 3-day forecast
  final List<Map<String, TextEditingController>> _forecastDays = List.generate(
    3,
    (i) => {
      'temp': TextEditingController(text: ['34', '36', '32'][i]),
      'rain': TextEditingController(text: ['0', '0', '5'][i]),
    },
  );

  final List<String> _crops = ['rice', 'wheat', 'maize', 'cotton', 'sugarcane'];

  @override
  void dispose() {
    for (final day in _forecastDays) {
      day['temp']?.dispose();
      day['rain']?.dispose();
    }
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
        crop: _selectedCrop,
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
      appBar: AppBar(
        backgroundColor: AppTheme.harvestColor,
        foregroundColor: Colors.white,
        title: Text(
          'Harvest Planner',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.harvestColor.withOpacity(0.85),
                  AppTheme.harvestColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 36)),
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
                        'Based on crop type & weather forecast',
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

          Form(
            key: _formKey,
            child: Column(
              children: [
                // Crop selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Select Crop',
                          icon: Icons.eco_rounded,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _selectedCrop,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.grass_rounded,
                              color: AppTheme.primary,
                            ),
                            labelText: 'Crop',
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
                            if (v != null) setState(() => _selectedCrop = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forecast input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: '3-Day Weather Forecast',
                          icon: Icons.cloud_rounded,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter expected temperature & rainfall for each day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          _forecastDays.length,
                          (i) => _buildForecastRow(i),
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 14),
                ],

                LoadingButton(
                  isLoading: _isLoading,
                  onPressed: _getHarvestSuggestion,
                  label: 'Get Harvest Suggestion',
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.harvestColor,
                ),
              ],
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(_result!),
          ],

          const SizedBox(height: 32),
        ],
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
                      color: Colors.orange,
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
                      color: Colors.blue,
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
        : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.harvestColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Harvest Recommendation',
              icon: Icons.agriculture_rounded,
              color: AppTheme.harvestColor,
            ),
            const SizedBox(height: 20),

            // Harvest date (hero)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.harvestColor.withOpacity(0.1),
                    AppTheme.harvestColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.harvestColor.withOpacity(0.3),
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
                      color: AppTheme.harvestColor,
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

            // Base date row
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
              AppTheme.accent,
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
