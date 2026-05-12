// ============================================================
// input_screen.dart — Screen 1: User Input Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../models/garden_recommendation/plant_model.dart';
import '../../api/garden_recommendation/api_service.dart';
import './option_chip.dart';
import './results_screen.dart';
import '../../utils/constants.dart';
//import './plant_card.dart'

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  String? _selectedSpace;
  String? _selectedSunlight;
  String? _selectedWater;
  double _temperature = 28.0;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedSpace != null &&
      _selectedSunlight != null &&
      _selectedWater != null;

  Future<void> _getRecommendations() async {
    if (!_canSubmit) {
      setState(
        () => _errorMessage = 'Please select all options before continuing.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final request = RecommendationRequest(
      temperature: _temperature,
      space: _selectedSpace!,
      sunlight: _selectedSunlight!,
      water: _selectedWater!,
    );

    final response = await ApiService().getRecommendations(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(response: response, request: request),
        ),
      );
    } else {
      setState(() => _errorMessage = response.error ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTemperatureCard(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 32),
              if (_errorMessage != null) _buildError(),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('🌱', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GardenAI',
                  style: GoogleFonts.merriweather(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                Text(
                  'Smart Plant Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Find what grows best\nfor your space 🌿',
          style: GoogleFonts.merriweather(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B4332),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your environment and we\'ll\nrecommend the perfect vegetables for you.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌡️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Temperature',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_temperature.round()}°C',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _temperature,
              min: 5,
              max: 45,
              divisions: 40,
              onChanged: (val) => setState(() => _temperature = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5°C ❄️',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '45°C 🔥',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Drag to set your local temperature. You can also use GPS.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Growing Space',
          child: OptionChipGroup(
            label: 'Where will you grow?',
            options: AppConstants.spaceOptions,
            selectedValue: _selectedSpace,
            onSelect: (val) => setState(() => _selectedSpace = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Sunlight',
          child: OptionChipGroup(
            label: 'Available sunlight?',
            options: AppConstants.sunlightOptions,
            selectedValue: _selectedSunlight,
            onSelect: (val) => setState(() => _selectedSunlight = val),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Water Availability',
          child: OptionChipGroup(
            label: 'How much can you water?',
            options: AppConstants.waterOptions,
            selectedValue: _selectedWater,
            onSelect: (val) => setState(() => _selectedWater = val),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Text('❌', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFDC2626),
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
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getRecommendations,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          disabledBackgroundColor: const Color(0xFF2D6A4F).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitThreeBounce(color: Colors.white, size: 20),
                  const SizedBox(width: 14),
                  Text(
                    'Finding your plants...',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    'Get Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
