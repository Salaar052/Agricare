// ============================================================
// input_screen.dart — Screen 1: User Input Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../services/location_service.dart';

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

  final AuthController _auth = Get.find<AuthController>();
  final LocationService _locationService = LocationService();
  final _locationController = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationLabel;
  bool _searchingLocation = false;
  List<LocationSearchResult> _locationResults = const [];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    if (_auth.hasLocation) {
      _selectedLatitude = _auth.latitude.value;
      _selectedLongitude = _auth.longitude.value;
      _selectedLocationLabel = _auth.locationLabel.value.isNotEmpty
          ? _auth.locationLabel.value
          : null;
      _locationController.text = _selectedLocationLabel ?? '';
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _locationController.dispose();
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
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      locationLabel: _selectedLocationLabel,
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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationResults = const [];
    });
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        setState(() {
          _errorMessage = 'Location permission denied. Please search manually.';
          _isLoading = false;
        });
        return;
      }
      final label = await _locationService.reverseGeocodeLabel(
        pos.latitude,
        pos.longitude,
      );
      setState(() {
        _selectedLatitude = pos.latitude;
        _selectedLongitude = pos.longitude;
        _selectedLocationLabel = label != 'Unknown' ? label : null;
        _locationController.text = _selectedLocationLabel ?? '';
        _isLoading = false;
      });
      _auth.setLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        label: _selectedLocationLabel,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to resolve location. Please search manually.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchingLocation = true;
      _errorMessage = null;
      _locationResults = const [];
    });
    try {
      final results = await _locationService.searchLocations(query);
      setState(() {
        _locationResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Location search failed. Please try again.';
      });
    } finally {
      setState(() {
        _searchingLocation = false;
      });
    }
  }

  void _selectLocation(LocationSearchResult result) {
    setState(() {
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      _selectedLocationLabel = result.label;
      _locationController.text = result.label;
      _locationResults = const [];
    });
    _auth.setLocation(
      lat: result.latitude,
      lng: result.longitude,
      label: result.label,
    );
    Navigator.of(context).pop();
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search location',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) async {
                        await _searchLocation(value);
                        setSheetState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter city, region or address',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            await _searchLocation(_locationController.text);
                            setSheetState(() {});
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _useCurrentLocation();
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Use current location'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: const Color(0xFF2D6A4F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_searchingLocation) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 12),
                    ],
                    if (_locationResults.isNotEmpty) ...[
                      const Text(
                        'Choose a location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      ..._locationResults.map((result) {
                        return ListTile(
                          title: Text(result.label),
                          subtitle: Text(
                            '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                          ),
                          onTap: () => _selectLocation(result),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
              _buildBackButton(context),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 24),
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B4332)),
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4332),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final label =
        _selectedLocationLabel ??
        'Use your login location or search a location';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A6655),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF2D6A4F),
                  ),
                  label: const Text('Use my location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    side: const BorderSide(color: Color(0xFF2D6A4F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showLocationPicker,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Select location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
