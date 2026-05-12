import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/location_service.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final AuthController _auth = Get.find<AuthController>();
  final LocationService _locationService = LocationService();

  final _searchCtrl = TextEditingController();

  bool _busy = false;
  String? _error;
  List<LocationSearchResult> _results = const [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _useLiveLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        setState(() {
          _error =
              'Location permission was denied or location is unavailable.';
          _busy = false;
        });
        return;
      }

      final weather = await _locationService.getWeather(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      final label = await _locationService.reverseGeocodeLabel(
        pos.latitude,
        pos.longitude,
      );

      _auth.setLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        temp: weather.temperature,
        label: label != 'Unknown' ? label : null,
      );
      _auth.setLocationSetupCompleted(true);

      _goNext();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final results = await _locationService.searchLocations(q);
    setState(() {
      _results = results;
      _busy = false;
      if (results.isEmpty) {
        _error = 'No locations found. Try a different query.';
      }
    });
  }

  Future<void> _selectManual(LocationSearchResult r) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final weather = await _locationService.getWeather(
        latitude: r.latitude,
        longitude: r.longitude,
      );

      _auth.setLocation(
        lat: r.latitude,
        lng: r.longitude,
        temp: weather.temperature,
        label: r.label,
      );
      _auth.setLocationSetupCompleted(true);

      _goNext();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  void _skip() {
    _auth.setLocationSetupCompleted(true);
    _goNext();
  }

  void _goNext() {
    final next = (Get.arguments is Map ? (Get.arguments as Map)['next'] : null)
        ?.toString();
    final mode = (Get.arguments is Map ? (Get.arguments as Map)['mode'] : null)
        ?.toString();

    if (next != null && next.isNotEmpty) {
      if (mode == 'off') {
        Get.offNamed(next);
      } else {
        Get.offAllNamed(next);
      }
      return;
    }

    // Default target
    if (_auth.isAdmin.value) {
      Get.offAllNamed(AppRoutes.adminDashboard);
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Set Your Location',
          style: TextStyle(
            color: Color(0xFF1A2E1A),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use live GPS location or search manually. This helps us fetch weather and generate better crop recommendations.',
                style: TextStyle(
                  color: Color(0xFF667765),
                  fontSize: 13.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _useLiveLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Use My Current Location'),
                ),
              ),

              const SizedBox(height: 10),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDFEDD3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _locationService.openAppSettings(),
                            child: const Text('App Settings'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _locationService.openLocationSettings(),
                            child: const Text('Location Settings'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 6),
              const Text(
                'Search location',
                style: TextStyle(
                  color: Color(0xFF1A2E1A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'City, district, or area (e.g., Lahore)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _busy ? null : _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (_busy) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 10),
              ],

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return InkWell(
                      onTap: _busy ? null : () => _selectManual(r),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDFEDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Color(0xFF4A7C2C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1A2E1A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
