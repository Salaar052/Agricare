import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../../controllers/auth_controller.dart';
import '../../controllers/main_nav_controller.dart';
import '../../controllers/news_controller.dart';
import '../../api/auth_service.dart';
import '../../routes/app_routes.dart';
import '../news/news_detail_screen.dart';
import '../../widgets/news/news_card.dart';
import '../../services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final AuthService authService = AuthService();
  final LocationService _locationService = LocationService();

  late final NewsController _newsController;
  late final PageController _newsPageController;
  int _currentNewsPage = 0;

  // Animations
  late AnimationController _welcomeAnimController;
  late AnimationController _pulseController;
  late Animation<double> _welcomeFadeAnim;
  late Animation<double> _pulseAnim;
  // ✅ REMOVED: _welcomeSlideAnim — was causing overflow on scroll

  // Weather + location state
  WeatherData? _weather;
  bool _weatherLoading = true;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _newsController = Get.isRegistered<NewsController>()
        ? Get.find<NewsController>()
        : Get.put(NewsController(), permanent: true);

    _newsPageController = PageController(viewportFraction: 1.0);

    // Welcome card entrance animation — fade only, NO slide
    _welcomeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _welcomeFadeAnim = CurvedAnimation(
      parent: _welcomeAnimController,
      curve: Curves.easeOut,
    );
    // ✅ REMOVED SlideTransition setup — it pushed hero content outside
    // SliverAppBar's clipping boundary during collapse, causing the
    // "BOTTOM OVERFLOWED BY 67 PIXELS" error visible when scrolling.

    // Pulse animation for weather icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _welcomeAnimController.forward();

    Future.microtask(() {
      _newsController.refreshFirstPage();
      _fetchWeather();
    });
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    _welcomeAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _weatherLoading = true;
      _locationName = '';
    });

    try {
      double lat = authController.latitude.value;
      double lng = authController.longitude.value;

      if (lat == 0.0 && lng == 0.0) {
        if (mounted) {
          setState(() {
            _weather = WeatherData.fallback();
            _locationName = 'Unknown';
            _weatherLoading = false;
          });
        }
        return;
      }

      final results = await Future.wait([
        _locationService.getWeather(latitude: lat, longitude: lng),
        _reverseGeocode(lat, lng),
      ]);

      final weather = results[0] as WeatherData;
      final cityName = results[1] as String;

      authController.setLocation(
        lat: lat,
        lng: lng,
        temp: weather.temperature,
        label: cityName != 'Unknown' ? cityName : null,
      );

      if (mounted) {
        setState(() {
          _weather = weather;
          _locationName = cityName;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weather = WeatherData.fallback();
          _locationName = 'Unknown';
          _weatherLoading = false;
        });
      }
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lng&localityLanguage=en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = (data['city'] as String?)?.trim();
        final locality = (data['locality'] as String?)?.trim();
        final subdivision = (data['principalSubdivision'] as String?)?.trim();
        final country = (data['countryName'] as String?)?.trim();

        return city?.isNotEmpty == true
            ? city!
            : locality?.isNotEmpty == true
                ? locality!
                : subdivision?.isNotEmpty == true
                    ? subdivision!
                    : country ?? 'Unknown';
      }
    } catch (_) {}
    return 'Unknown';
  }

  void _onNewsPageChanged(int index, int totalItems) {
    setState(() => _currentNewsPage = index);
    if (index >= totalItems - 2) {
      _newsController.loadMore();
    }
  }

  _WeatherTheme _getWeatherTheme() {
    final label = _weather?.skyLabel.toLowerCase() ?? '';
    if (label.contains('clear') || label.contains('sunny')) {
      return _WeatherTheme(
        gradientColors: [const Color(0xFF1E6B3C), const Color(0xFF2D9B5A)],
        skyColors: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
        icon: '☀️',
        particles: _SkyParticle.sunny,
      );
    } else if (label.contains('cloud')) {
      return _WeatherTheme(
        gradientColors: [const Color(0xFF234B6A), const Color(0xFF3A7CA5)],
        skyColors: [const Color(0xFF64748B), const Color(0xFF94A3B8)],
        icon: '⛅',
        particles: _SkyParticle.cloudy,
      );
    } else if (label.contains('rain') || label.contains('drizzle')) {
      return _WeatherTheme(
        gradientColors: [const Color(0xFF1E3A5F), const Color(0xFF2D5A8E)],
        skyColors: [const Color(0xFF475569), const Color(0xFF64748B)],
        icon: '🌧️',
        particles: _SkyParticle.rainy,
      );
    } else if (label.contains('storm') || label.contains('thunder')) {
      return _WeatherTheme(
        gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)],
        skyColors: [const Color(0xFF374151), const Color(0xFF4B5563)],
        icon: '⛈️',
        particles: _SkyParticle.stormy,
      );
    } else if (label.contains('mist') ||
        label.contains('fog') ||
        label.contains('haze')) {
      return _WeatherTheme(
        gradientColors: [const Color(0xFF2D3B2D), const Color(0xFF4A5C4A)],
        skyColors: [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)],
        icon: '🌫️',
        particles: _SkyParticle.misty,
      );
    }
    return _WeatherTheme(
      gradientColors: [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
      skyColors: [const Color(0xFF52B788), const Color(0xFF74C69D)],
      icon: '🌤️',
      particles: _SkyParticle.sunny,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F0),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildWeatherStatsRow(),
                    const SizedBox(height: 28),
                    _buildNewsSectionHeader(),
                    const SizedBox(height: 12),
                    _buildNewsCarousel(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Quick Access'),
                    const SizedBox(height: 14),
                    _buildFeaturesGrid(),
                    const SizedBox(height: 20),
                    _buildQuickTipCard(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final theme = _getWeatherTheme();

    return SliverAppBar(
      expandedHeight: 260,
      collapsedHeight: 70,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: theme.gradientColors[0],
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0,
      forceElevated: false,
      // ✅ KEY FIX: flexibleSpace is clipped to the SliverAppBar bounds.
      // The old SlideTransition would animate content OUTSIDE those bounds
      // during collapse, triggering the 67px overflow error.
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandedHeight = 260.0;
          final collapsedHeight = 70.0 + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;
          final collapseProgress = ((expandedHeight - currentHeight) /
                  (expandedHeight - collapsedHeight))
              .clamp(0.0, 1.0);

          return Stack(
            // ✅ Use clipBehavior to prevent any child from painting outside
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              // Hero background
              _buildWelcomeWeatherHero(theme),

              // Collapsed top bar fades in on scroll
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: collapseProgress,
                  child: Container(
                    color: theme.gradientColors[0],
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    height: collapsedHeight,
                    child: _buildCollapsedAppBar(theme),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedAppBar(_WeatherTheme theme) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.agriculture, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Agri-Care',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (!_weatherLoading && _weather != null)
              Text(
                '${theme.icon} ${_weather!.tempDisplay}  ·  '
                '${_locationName.isNotEmpty ? _locationName : "–"}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () async {
            await authService.logout();
            Get.offAllNamed(AppRoutes.login);
          },
        ),
      ],
    );
  }

  // ── Hero — FadeTransition ONLY, no SlideTransition ────────────────────────
  Widget _buildWelcomeWeatherHero(_WeatherTheme theme) {
    // ✅ FIXED: Wrapped with ClipRect so nothing can paint outside the
    // SliverAppBar's allocated space. SlideTransition removed entirely —
    // it was translating the hero widget downward during the entrance
    // animation while the SliverAppBar was simultaneously collapsing,
    // producing the 67px overflow measured at the bottom of flexibleSpace.
    return ClipRect(
      child: FadeTransition(
        opacity: _welcomeFadeAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Sky gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.6, -0.5),
                      radius: 1.2,
                      colors: [
                        theme.skyColors[0].withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Floating orbs
              Positioned(
                top: -30,
                right: -30,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.skyColors[0].withOpacity(0.12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 30,
                child: ScaleTransition(
                  scale: ReverseAnimation(_pulseAnim),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),

              // Weather icon
              Positioned(
                top: 50,
                right: 24,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Text(
                    _weatherLoading ? '🌿' : theme.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),

              // Bottom fade band
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.gradientColors[0].withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
            // Content — Positioned so it never overflows during SliverAppBar collapse
Positioned(
  left: 22,
  right: 22,
  bottom: 20,                          // anchored to bottom, no overflow
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,    // only takes needed height
    children: [
      // Agri-Care badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Agri-Care',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),

      // Welcome greeting
      Obx(() => Text(
            'Good ${_getGreeting()},\n${authController.username.value.isNotEmpty ? authController.username.value : "Farmer"} 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          )),
      const SizedBox(height: 10),

      // Weather summary pill
      if (!_weatherLoading && _weather != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_rounded, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _locationName.isNotEmpty && _locationName != 'Unknown'
                      ? _locationName
                      : '–',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 1, height: 12,
                color: Colors.white30,
              ),
              Text(
                '${theme.icon}  ${_weather!.skyLabel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 1, height: 12,
                color: Colors.white30,
              ),
              Text(
                _weather!.tempDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        )
      else if (_weatherLoading)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Fetching weather...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
    ],
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  // ── Weather Stats Row ──────────────────────────────────────────────────────
  Widget _buildWeatherStatsRow() {
    final w = _weather;

    final stats = [
      _WeatherStat(
        icon: Icons.thermostat_rounded,
        label: 'Temp',
        value: _weatherLoading ? null : (w?.tempDisplay ?? '--'),
        color: const Color(0xFFEF4444),
      ),
      _WeatherStat(
        icon: Icons.water_drop_rounded,
        label: 'Humidity',
        value: _weatherLoading ? null : (w?.humidityDisplay ?? '--'),
        color: const Color(0xFF3B82F6),
      ),
      _WeatherStat(
        icon: Icons.air_rounded,
        label: 'Wind',
        value: _weatherLoading ? null : (w?.windDisplay ?? '--'),
        color: const Color(0xFF8B5CF6),
      ),
      _WeatherStat(
        icon: Icons.wb_cloudy_rounded,
        label: 'Sky',
        value: _weatherLoading ? null : (w?.skyLabel ?? '--'),
        color: const Color(0xFF0EA5E9),
      ),
    ];

    return GestureDetector(
      onTap: _fetchWeather,
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: stats.indexOf(stat) < stats.length - 1 ? 10 : 0,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: stat.color.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: stat.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stat.icon, color: stat.color, size: 17),
                  ),
                  const SizedBox(height: 6),
                  stat.value == null
                      ? SizedBox(
                          height: 12,
                          width: 30,
                          child: LinearProgressIndicator(
                            backgroundColor: const Color(0xFFEEF2EE),
                            color: stat.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Text(
                          stat.value!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2E1A),
                          ),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFADB5BD),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── News Section Header ────────────────────────────────────────────────────
  Widget _buildNewsSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('Latest News'),
        GestureDetector(
          onTap: () => _newsController.refreshFirstPage(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C2C).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF4A7C2C),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ── News Carousel ──────────────────────────────────────────────────────────
  Widget _buildNewsCarousel() {
    return Obx(() {
      final loading =
          _newsController.isLoading.value && _newsController.items.isEmpty;
      final items = _newsController.items;

      if (loading) return _buildNewsSkeletonCard();
      if (items.isEmpty) return _buildNewsEmptyState();

      return Column(
        children: [
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _newsPageController,
              onPageChanged: (index) =>
                  _onNewsPageChanged(index, items.length),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final news = items[index];
                return AnimatedScale(
                  scale: _currentNewsPage == index ? 1.0 : 0.96,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: NewsCard(
                        news: news,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  NewsDetailScreen(news: news),
                              transitionDuration:
                                  const Duration(milliseconds: 320),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    )),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildDotIndicators(items.length),
        ],
      );
    });
  }

  Widget _buildDotIndicators(int count) {
    final capped = count > 8 ? 8 : count;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(capped, (i) {
        final active = i == (_currentNewsPage % capped);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF4A7C2C)
                : const Color(0xFFCBD5CB),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildNewsSkeletonCard() {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(color: const Color(0xFFEEF2EE)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFFE8EDE8), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C2C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Color(0xFF4A7C2C),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'No news available right now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Features Grid ──────────────────────────────────────────────────────────
  Widget _buildFeaturesGrid() {
    final features = [
      _FeatureItem(
        title: 'Marketplace',
        subtitle: 'Buy & sell crops',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF3B82F6),
        route: AppRoutes.marketplace,
        emoji: '🛒',
      ),
      _FeatureItem(
        title: 'Community',
        subtitle: 'Talk to farmers',
        icon: Icons.forum_rounded,
        color: const Color(0xFF8B5CF6),
        route: AppRoutes.community,
        emoji: '💬',
      ),
      _FeatureItem(
        title: 'Crop Guide',
        subtitle: 'Smart suggestions',
        icon: Icons.spa_rounded,
        color: const Color(0xFF10B981),
        route: AppRoutes.recommendations,
        emoji: '🌱',
      ),
      _FeatureItem(
        title: 'AI Chatbot',
        subtitle: 'Ask anything',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFFF59E0B),
        route: AppRoutes.chatbot,
        emoji: '🤖',
      ),
      _FeatureItem(
        title: 'Home Garden',
        subtitle: 'Grow at home',
        icon: Icons.grass_rounded,
        color: const Color(0xFF06B6D4),
        route: AppRoutes.gardenRecommendations,
        emoji: '🏡',
      ),
      _FeatureItem(
        title: 'Fertilizer',
        subtitle: 'Fertilizer advisory',
        icon: Icons.science_rounded,
        color: const Color(0xFFEF4444),
        route: AppRoutes.fertilizerHarvestAdvisory,
        emoji: '🧪',
      ),
    ];

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) => _buildFeatureCard(context, features[i]),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem f) {
    return GestureDetector(
      onTap: () => Get.find<MainNavController>().navigate(f.route),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: f.color.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    f.color.withOpacity(0.15),
                    f.color.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2E1A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  f.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFADB5BD),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Tip Card ─────────────────────────────────────────────────────────
  Widget _buildQuickTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A7C2C).withOpacity(0.08),
            const Color(0xFF5D9A3A).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A7C2C).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A7C2C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('💡', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Tip",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A6B22),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Water your crops early morning to reduce evaporation and improve nutrient absorption.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4A5568),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A2E1A),
        letterSpacing: -0.4,
      ),
    );
  }
}

// ── Helper models ──────────────────────────────────────────────────────────────

class _WeatherTheme {
  final List<Color> gradientColors;
  final List<Color> skyColors;
  final String icon;
  final _SkyParticle particles;

  const _WeatherTheme({
    required this.gradientColors,
    required this.skyColors,
    required this.icon,
    required this.particles,
  });
}

enum _SkyParticle { sunny, cloudy, rainy, stormy, misty }

class _WeatherStat {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String emoji;

  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.emoji,
  });
}