import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';
import '../../services/weather_based_crop_service.dart';

class WeatherBasedCropRecommendationScreen extends StatefulWidget {
  const WeatherBasedCropRecommendationScreen({super.key});

  @override
  State<WeatherBasedCropRecommendationScreen> createState() =>
      _WeatherBasedCropRecommendationScreenState();
}

class _WeatherBasedCropRecommendationScreenState
    extends State<WeatherBasedCropRecommendationScreen>
    with TickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();
  final LocationService _locationService = LocationService();
  final WeatherBasedCropService _service = WeatherBasedCropService();

  final _searchCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showChangeLocation = false;
  List<LocationSearchResult> _results = const [];
  Map<String, dynamic>? _apiResponse;
  double? _lat;
  double? _lng;
  String? _label;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  // ── Design tokens ──────────────────────────
  static const Color _primary    = Color(0xFF1C4A2A);
  static const Color _secondary  = Color(0xFF2D7A47);
  static const Color _accent     = Color(0xFF4CAF70);
  static const Color _bg         = Color(0xFFF4F8F1);
  static const Color _card       = Colors.white;
  static const Color _border     = Color(0xFFDCEDD5);
  static const Color _surface    = Color(0xFFEDF5E7);
  static const Color _textDark   = Color(0xFF0F2218);
  static const Color _textMid    = Color(0xFF4A6555);
  static const Color _textLight  = Color(0xFF93AFA0);
  static const Color _warning    = Color(0xFFB45309);
  static const Color _errorColor = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    if (_auth.hasLocation) {
      _lat   = _auth.latitude.value;
      _lng   = _auth.longitude.value;
      _label = _auth.locationLabel.value.isNotEmpty
          ? _auth.locationLabel.value
          : null;
      _refresh();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _useLiveLocation() async {
    setState(() { _loading = true; _error = null; _results = const []; });
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        setState(() {
          _error = 'Location permission denied. Please search manually.';
          _loading = false;
        });
        return;
      }
      _lat = pos.latitude;
      _lng = pos.longitude;
      final label = await _locationService.reverseGeocodeLabel(pos.latitude, pos.longitude);
      _label = label != 'Unknown' ? label : null;
      _auth.setLocation(lat: _lat!, lng: _lng!, label: _label);
      await _refresh();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _results = const []; });
    final results = await _locationService.searchLocations(q);
    setState(() {
      _results = results;
      _loading = false;
      if (results.isEmpty) _error = 'No locations found.';
    });
  }

  Future<void> _selectManual(LocationSearchResult r) async {
    _lat   = r.latitude;
    _lng   = r.longitude;
    _label = r.label;
    _auth.setLocation(lat: _lat!, lng: _lng!, label: r.label);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_lat == null || _lng == null) {
      setState(() { _error = 'Please set your location first.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _fadeController.reset();

    try {
      final response = await _service.recommend(
        lat: _lat!,
        lng: _lng!,
        locationLabel: _label ?? _auth.locationLabel.value,
        headers: _auth.getAuthHeaders(),
      );

      final weatherCurrent = response['weather']?['current'];
      final temp = weatherCurrent is Map ? weatherCurrent['temperatureC'] : null;
      if (temp is num) {
        _auth.setLocation(lat: _lat!, lng: _lng!, temp: temp.toDouble());
      }

      setState(() { _apiResponse = response; _loading = false; });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final rec          = _apiResponse?['recommendation'] as Map<String, dynamic>?;
    final season       = rec?['season']  as Map<String, dynamic>?;
    final weather      = rec?['weather'] as Map<String, dynamic>?;
    final current      = weather?['current']         as Map<String, dynamic>?;
    final forecast     = weather?['forecastSummary'] as Map<String, dynamic>?;
    final recommendations = (rec?['recommendations'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: _secondary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── 1. LOCATION CARD (always at top) ──
            _buildLocationCard(),
            const SizedBox(height: 12),

            // ── 2. NO-LOCATION PROMPT ──
            if (!_auth.hasLocation) ...[
              _buildNoLocationCard(),
              const SizedBox(height: 12),
            ],

            // ── 3. LOADER ──
            if (_loading) ...[
              _buildBeautifulLoader(),
              const SizedBox(height: 12),
            ],

            // ── 4. ERROR ──
            if (_error != null && !_loading) ...[
              _buildErrorCard(_error!),
              const SizedBox(height: 12),
            ],

            // ── 5. WEATHER SUMMARY ──
            if (rec != null && !_loading)
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherSummary(
                      label:    _label ?? _auth.locationLabel.value,
                      season:   season,
                      current:  current,
                      forecast: forecast,
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendations(recommendations),
                  ],
                ),
              ),

            // ── 6. HINT ──
            if (rec == null && !_loading && _error == null && _auth.hasLocation)
              _buildHintCard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: _textDark),
          ),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crop Recommendations',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3)),
          Text('Based on live weather data',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _textLight)),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ─────────────────────────────────────────
  // LOCATION CARD (top, collapsible change panel)
  // ─────────────────────────────────────────
  Widget _buildLocationCard() {
    final currentLabel = (_label ?? _auth.locationLabel.value).trim();

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.location_on_rounded, size: 20, color: _secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current location',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _textLight)),
                      const SizedBox(height: 2),
                      Text(
                        currentLabel.isNotEmpty ? currentLabel : 'Not set',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showChangeLocation = !_showChangeLocation;
                      _error = null;
                      _results = const [];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _showChangeLocation ? _primary : _surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showChangeLocation ? 'Done' : 'Change',
                      style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700,
                        color: _showChangeLocation ? Colors.white : _secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Collapsible change-location panel ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _showChangeLocation
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Container(height: 1, color: _border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      // Live location button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _useLiveLocation,
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text('Use my current location',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Divider with label
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: _border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('or search', style: TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Container(height: 1, color: _border)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Search field
                      TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                        decoration: InputDecoration(
                          hintText: 'Search city (e.g., Multan)',
                          hintStyle: TextStyle(color: _textLight, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: _textLight, size: 20),
                          suffixIcon: IconButton(
                            onPressed: _loading ? null : _search,
                            icon: const Icon(Icons.arrow_forward_rounded, color: _secondary, size: 20),
                          ),
                          filled: true,
                          fillColor: _surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                      ),

                      // Search results
                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._results.take(6).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: _loading ? null : () => _selectManual(r),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: _secondary, size: 17),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(r.label,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textDark)),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: _textLight, size: 18),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // NO LOCATION CARD
  // ─────────────────────────────────────────
  Widget _buildNoLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_off_outlined, color: _warning, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Set your location once to get weather-based crop recommendations.',
              style: TextStyle(color: _warning, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Get.toNamed(
              AppRoutes.locationSetup,
              arguments: {'next': AppRoutes.weatherBasedCrop, 'mode': 'off'},
            ),
            style: TextButton.styleFrom(
              foregroundColor: _warning,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('Set up', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BEAUTIFUL LOADER
  // ─────────────────────────────────────────
 Widget _buildBeautifulLoader() {
  return Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _secondary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 4,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _secondary,
                backgroundColor: _border,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Fetching Best crop according to your weather…',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Analysing current conditions for your location',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────
  // ERROR CARD
  // ─────────────────────────────────────────
  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.error_outline_rounded, color: _errorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg, style: const TextStyle(color: _errorColor, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loading ? null : _refresh,
            style: TextButton.styleFrom(foregroundColor: _errorColor, padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // WEATHER SUMMARY
  // ─────────────────────────────────────────
  Widget _buildWeatherSummary({
    required String? label,
    required Map<String, dynamic>? season,
    required Map<String, dynamic>? current,
    required Map<String, dynamic>? forecast,
  }) {
    final seasonName   = season?['name']?.toString()   ?? '--';
    final seasonWindow = season?['window']?.toString() ?? '';

    String v(dynamic x, String suffix) {
      if (x == null) return '--';
      if (x is num)  return '${x.toStringAsFixed(0)}$suffix';
      return '$x$suffix';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C4A2A), Color(0xFF2D7A47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Location + season header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (label != null && label.trim().isNotEmpty) ? label : 'Selected location',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5, letterSpacing: -0.2),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        seasonWindow.isNotEmpty ? '$seasonName · $seasonWindow' : seasonName,
                        style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _weatherStat(Icons.thermostat_outlined,        v(current?['temperatureC'],    '°C'), 'Temp'),
                _weatherStatDivider(),
                _weatherStat(Icons.water_drop_outlined,        v(current?['humidityPct'],     '%'),  'Humidity'),
                _weatherStatDivider(),
                _weatherStat(Icons.air_rounded,                v(current?['windSpeedKmh'],    ' km/h'), 'Wind'),
                _weatherStatDivider(),
                _weatherStat(Icons.umbrella_outlined,          v(forecast?['precipNext24hMm'],' mm'), 'Rain 24h'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _weatherStatDivider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15));

  // ─────────────────────────────────────────
  // RECOMMENDATIONS
  // ─────────────────────────────────────────
  Widget _buildRecommendations(List items) {
    if (items.isEmpty) return _buildHintCard(text: 'No recommendations returned. Pull to refresh.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Crops',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final it  = entry.value;
          final m   = it is Map ? it : <String, dynamic>{};

          final crop          = (m['crop'] ?? '--').toString();
          final score         = m['suitabilityScore'];
          final why           = (m['why'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
          final plantingWindow = (m['plantingWindow'] ?? '').toString();
          final waterNeed      = (m['waterNeed'] ?? '').toString();
          final pakistanNotes  = (m['pakistanNotes'] ?? '').toString();
          final keyRisks       = (m['keyRisks'] as List?)?.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() ?? const <String>[];
          final actionTips     = (m['actionTips'] as List?)?.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() ?? const <String>[];

          return _CropCard(
            rank: idx + 1,
            crop: crop,
            score: score,
            why: why,
            plantingWindow: plantingWindow,
            waterNeed: waterNeed,
            pakistanNotes: pakistanNotes,
            keyRisks: keyRisks,
            actionTips: actionTips,
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────
  // HINT CARD
  // ─────────────────────────────────────────
  Widget _buildHintCard({String? text}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: _secondary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text ?? 'Select a location to get crop recommendations based on current weather.',
              style: const TextStyle(color: _textMid, fontWeight: FontWeight.w600, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CROP CARD WIDGET
// ─────────────────────────────────────────
class _CropCard extends StatefulWidget {
  final int rank;
  final String crop;
  final dynamic score;
  final List<String> why;
  final String plantingWindow;
  final String waterNeed;
  final String pakistanNotes;
  final List<String> keyRisks;
  final List<String> actionTips;

  const _CropCard({
    required this.rank,
    required this.crop,
    required this.score,
    required this.why,
    required this.plantingWindow,
    required this.waterNeed,
    required this.pakistanNotes,
    required this.keyRisks,
    required this.actionTips,
  });

  @override
  State<_CropCard> createState() => _CropCardState();
}

class _CropCardState extends State<_CropCard> {
  bool _expanded = false;

  static const Color _primary   = Color(0xFF1C4A2A);
  static const Color _secondary = Color(0xFF2D7A47);
  static const Color _surface   = Color(0xFFEDF5E7);
  static const Color _border    = Color(0xFFDCEDD5);
  static const Color _textDark  = Color(0xFF0F2218);
  static const Color _textMid   = Color(0xFF4A6555);
  static const Color _textLight = Color(0xFF93AFA0);

  Color _scoreColor(dynamic score) {
    if (score == null) return _textLight;
    final s = score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0;
    if (s >= 8) return const Color(0xFF16A34A);
    if (s >= 6) return const Color(0xFF2D7A47);
    return const Color(0xFFB45309);
  }

  @override
  Widget build(BuildContext context) {
    final hasExtra = widget.actionTips.isNotEmpty ||
        widget.keyRisks.isNotEmpty ||
        widget.pakistanNotes.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank badge
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: widget.rank == 1 ? _primary : _surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${widget.rank}',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w900,
                        color: widget.rank == 1 ? Colors.white : _secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.crop,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.3)),
                      if (widget.why.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...widget.why.take(3).map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: CircleAvatar(radius: 2.5, backgroundColor: _secondary),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(w,
                                    style: const TextStyle(fontSize: 12.5, color: _textMid, height: 1.4, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.score != null)
                  Column(
                    children: [
                      Text(
                        '${widget.score}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _scoreColor(widget.score), height: 1),
                      ),
                      const Text('/10', style: TextStyle(fontSize: 10, color: _textLight, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),

          // ── Pills ──
          if (widget.plantingWindow.trim().isNotEmpty || widget.waterNeed.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  if (widget.plantingWindow.trim().isNotEmpty)
                    _Pill(icon: Icons.calendar_today_outlined, label: 'Planting', value: widget.plantingWindow),
                  if (widget.waterNeed.trim().isNotEmpty)
                    _Pill(icon: Icons.water_drop_outlined, label: 'Water', value: widget.waterNeed),
                ],
              ),
            ),

          // ── Expandable extra info ──
          if (hasExtra) ...[
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
              child: Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: _expanded
                      ? const BorderRadius.vertical(bottom: Radius.zero)
                      : const BorderRadius.vertical(bottom: Radius.circular(17)),
                  border: const Border(top: BorderSide(color: _border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18, color: _secondary),
                    const SizedBox(width: 8),
                    Text(
                      _expanded ? 'Hide details' : 'More details',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _secondary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _border)),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.actionTips.isNotEmpty) ...[
                      _SectionLabel(label: 'Action Tips', icon: Icons.tips_and_updates_outlined),
                      const SizedBox(height: 8),
                      ...widget.actionTips.take(3).map((t) => _BulletRow(text: t, color: const Color(0xFF16A34A))),
                    ],
                    if (widget.keyRisks.isNotEmpty) ...[
                      if (widget.actionTips.isNotEmpty) const SizedBox(height: 12),
                      _SectionLabel(label: 'Key Risks', icon: Icons.warning_amber_outlined),
                      const SizedBox(height: 8),
                      ...widget.keyRisks.take(2).map((t) => _BulletRow(text: t, color: const Color(0xFFB45309))),
                    ],
                    if (widget.pakistanNotes.trim().isNotEmpty) ...[
                      if (widget.actionTips.isNotEmpty || widget.keyRisks.isNotEmpty) const SizedBox(height: 12),
                      _SectionLabel(label: 'Pakistan Notes', icon: Icons.info_outline_rounded),
                      const SizedBox(height: 8),
                      Text(widget.pakistanNotes,
                          style: const TextStyle(fontSize: 13, color: _textMid, height: 1.5, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Pill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5E7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCEDD5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2D7A47)),
          const SizedBox(width: 5),
          Text('$label: $value',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1C4A2A))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF2D7A47)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F2218), letterSpacing: 0.1)),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.5),
            child: CircleAvatar(radius: 2.5, backgroundColor: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A6555), height: 1.4, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}