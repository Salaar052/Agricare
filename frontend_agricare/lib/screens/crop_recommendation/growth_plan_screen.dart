// File: lib/screens/crop_recommendation/growth_plan_screen.dart
// REDESIGNED - Combines API fetching with comprehensive plan display

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import '../../api/api_config.dart';
import '../../controllers/auth_controller.dart';

class GrowthPlanScreen extends StatefulWidget {
  final String cropName;
  final Map<String, dynamic> recommendationData;
  final Map<String, dynamic> soilData;

  const GrowthPlanScreen({
    Key? key,
    required this.cropName,
    required this.recommendationData,
    required this.soilData,
  }) : super(key: key);

  @override
  _GrowthPlanScreenState createState() => _GrowthPlanScreenState();
}

class _PlanFetchResult {
  final String planType;
  final Map<String, dynamic>? plan;
  final bool fallback;
  final String? warning;
  final String? error;

  const _PlanFetchResult({
    required this.planType,
    this.plan,
    this.fallback = false,
    this.warning,
    this.error,
  });
}

class _GrowthPlanScreenState extends State<GrowthPlanScreen> {
  String? _lastOpenedPlanType;

  String get apiUrl => ApiConfig.apiV1('/crop-recommendation/growth-plan');

  Future<_PlanFetchResult> _fetchGrowthPlanData(String planType) async {
    try {
      AuthController? auth;
      if (Get.isRegistered<AuthController>()) {
        auth = Get.find<AuthController>();
      }

      final locationContext = (auth != null && auth.hasLocation)
          ? {
              'lat': auth.latitude.value,
              'lng': auth.longitude.value,
              'label': auth.locationLabel.value,
            }
          : null;

      final requestData = {
        'cropName': widget.cropName,
        'soilData': widget.soilData,
        'planType': planType,
        'context': {
          if (locationContext != null) 'location': locationContext,
          if (widget.recommendationData['weather'] != null)
            'weather': widget.recommendationData['weather'],
          if (widget.recommendationData['season'] != null)
            'season': widget.recommendationData['season'],
        },
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(
            const Duration(seconds: 70),
            onTimeout: () => throw Exception('Request timeout - AI taking too long'),
          );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['growthPlan'] != null) {
          return _PlanFetchResult(
            planType: planType,
            plan: (jsonData['growthPlan'] as Map).cast<String, dynamic>(),
            fallback: jsonData['fallback'] == true,
            warning: (jsonData['warning'] as String?)?.trim(),
          );
        }
        return _PlanFetchResult(
          planType: planType,
          error: (jsonData['error'] as String?)?.trim() ?? 'Failed to generate plan',
        );
      }

      final errorData = json.decode(response.body);
      return _PlanFetchResult(
        planType: planType,
        error: (errorData['error'] as String?)?.trim() ?? 'Server error',
      );
    } catch (e) {
      return _PlanFetchResult(
        planType: planType,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  String _planTitle(String planType) {
    switch (planType) {
      case 'irrigation':
        return 'Irrigation Plan';
      case 'pesticides':
        return 'Pesticides & Fertilizers';
      case 'complete':
      default:
        return 'Complete Growth Plan';
    }
  }

  Color _planAccent(String planType) {
    switch (planType) {
      case 'irrigation':
        return Color(0xFF3B82F6);
      case 'pesticides':
        return Color(0xFFEF4444);
      case 'complete':
      default:
        return Color(0xFF7C3AED);
    }
  }

  String _fieldLabel(String key) {
    switch (key) {
      case 'activeIngredient':
        return 'Active ingredient';
      case 'timing':
        return 'Timing';
      case 'frequency':
        return 'Frequency';
      case 'method':
        return 'Method';
      case 'water':
        return 'Water';
      case 'dose':
        return 'Dose';
      case 'stage':
        return 'Stage';
      case 'when':
        return 'When to apply';
      case 'duration':
        return 'Duration';
      default:
        return key;
    }
  }

  void _openPlanModal(String planType) {
    setState(() => _lastOpenedPlanType = planType);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final accent = _planAccent(planType);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 14, 8, 14),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _planTitle(planType),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                widget.cropName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Color(0xFF6B7280)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: FutureBuilder<_PlanFetchResult>(
                      future: _fetchGrowthPlanData(planType),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildModalLoading();
                        }
                        final result = snapshot.data;
                        if (result == null) {
                          return _buildModalError(
                            message: 'Failed to load plan.',
                            onRetry: () => Navigator.pop(context),
                          );
                        }
                        if (result.error != null || result.plan == null) {
                          return _buildModalError(
                            message: result.error ?? 'Failed to load plan.',
                            onRetry: () {
                              Navigator.pop(context);
                              _openPlanModal(planType);
                            },
                          );
                        }
                        return _buildPlanContent(
                          planType: planType,
                          plan: result.plan!,
                          accent: accent,
                          fallback: result.fallback,
                          warning: result.warning,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Plan',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.cropName.toUpperCase(),
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [],
      ),
      body: _buildInitialView(),
    );
  }

  // ============================================
  // INITIAL VIEW - Plan Type Selection
  // ============================================

  Widget _buildInitialView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRecommendationHeader(),
          SizedBox(height: 20),
          _buildOptionCards(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecommendationHeader() {
    final confidence = widget.recommendationData['confidence'] ?? 0.0;
    
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('🌾', style: TextStyle(fontSize: 40)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOMMENDED CROP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.cropName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Confidence: ${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Detailed Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 16),
          _buildOptionCard(
            title: 'Complete Growth Plan',
            description: 'Full guide: stages, irrigation, fertilization, pest control & more',
            icon: Icons.auto_graph,
            color: Color(0xFF7C3AED),
            planType: 'complete',
          ),
          SizedBox(height: 12),
          _buildOptionCard(
            title: 'Pesticides & Fertilizers',
            description: 'Chemical & organic products with application schedule',
            icon: Icons.science,
            color: Color(0xFFEF4444),
            planType: 'pesticides',
          ),
          SizedBox(height: 12),
          _buildOptionCard(
            title: 'Irrigation Plan',
            description: 'Water management, frequency & critical periods',
            icon: Icons.water_drop,
            color: Color(0xFF3B82F6),
            planType: 'irrigation',
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String planType,
  }) {
    final isSelected = _lastOpenedPlanType == planType;
    
    return InkWell(
      onTap: () => _openPlanModal(planType),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isSelected ? color : Color(0xFFD1D5DB),
              size: isSelected ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalLoading() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Generating a concise plan…',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          SizedBox(height: 6),
          Text(
            'This can take up to 60 seconds.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildModalError({required String message, required VoidCallback onRetry}) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
          SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 14),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return const [];
  }

  Widget _buildBulletsCard({
    required String title,
    required List<String> bullets,
    required Color accent,
    IconData? icon,
  }) {
    if (bullets.isEmpty) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: accent),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF2D3748)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ...bullets.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueCard({
    required String title,
    required Color accent,
    required Map<String, dynamic> data,
    List<String> keys = const [],
    List<String> bullets = const [],
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF2D3748))),
          SizedBox(height: 10),
          ...keys.map((k) {
            final v = (data[k] ?? '').toString().trim();
            if (v.isEmpty) return SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_fieldLabel(k)}: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: accent)),
                  Expanded(child: Text(v, style: TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xFF374151)))),
                ],
              ),
            );
          }),
          if (bullets.isNotEmpty) ...[
            SizedBox(height: 2),
            ...bullets.map(
              (b) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 7),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Text(b, style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF374151)))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanContent({
    required String planType,
    required Map<String, dynamic> plan,
    required Color accent,
    required bool fallback,
    required String? warning,
  }) {
    final summary = (plan['summary'] is Map) ? (plan['summary'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final summaryTitle = (summary['title'] ?? '').toString().trim();
    final summaryBullets = _stringList(summary['bullets']);
    final warnings = _stringList(plan['warnings']);

    final content = <Widget>[];

    if (fallback || (warning != null && warning.trim().isNotEmpty)) {
      content.add(
        Container(
          margin: EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFFB45309), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  (warning != null && warning.trim().isNotEmpty)
                      ? warning.trim()
                      : 'AI response was limited — showing a safe fallback plan.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    content.add(
      Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summaryTitle.isNotEmpty)
                Text(
                  summaryTitle,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
              if (summaryTitle.isNotEmpty && summaryBullets.isNotEmpty) SizedBox(height: 10),
              if (summaryBullets.isNotEmpty)
                ...summaryBullets.take(8).map(
                      (b) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 7),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text(b, style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF374151)))),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );

    content.add(SizedBox(height: 12));

    if (planType == 'irrigation') {
      final irrigation = (plan['irrigation'] is Map) ? (plan['irrigation'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      content.addAll([
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildBulletsCard(
            title: 'Water Needs',
            bullets: _stringList(irrigation['waterNeeds']),
            accent: accent,
            icon: Icons.water_drop,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildBulletsCard(
            title: 'Critical Periods',
            bullets: _stringList(irrigation['criticalPeriods']),
            accent: Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ]);

      final scheduleRaw = irrigation['schedule'];
      final schedule = (scheduleRaw is List) ? scheduleRaw : const [];
      for (final item in schedule) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        content.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildKeyValueCard(
              title: (m['stage'] ?? 'Schedule').toString(),
              accent: accent,
              data: m,
              keys: const ['timing', 'frequency', 'method', 'water'],
              bullets: _stringList(m['bullets']),
            ),
          ),
        );
      }

      content.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildBulletsCard(
            title: 'Do / Don’t',
            bullets: _stringList(irrigation['doDonts']),
            accent: accent,
            icon: Icons.checklist,
          ),
        ),
      );
    } else if (planType == 'pesticides') {
      final fertilizersRaw = plan['fertilizers'];
      final fertilizers = (fertilizersRaw is List) ? fertilizersRaw : const [];
      for (final f in fertilizers) {
        if (f is! Map) continue;
        final m = f.cast<String, dynamic>();
        content.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildKeyValueCard(
              title: (m['name'] ?? 'Fertilizer').toString(),
              accent: Color(0xFF10B981),
              data: m,
              keys: const ['stage', 'dose', 'method'],
              bullets: _stringList(m['bullets']),
            ),
          ),
        );
      }

      final pesticidesRaw = plan['pesticides'];
      final pesticides = (pesticidesRaw is List) ? pesticidesRaw : const [];
      for (final p in pesticides) {
        if (p is! Map) continue;
        final m = p.cast<String, dynamic>();
        content.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildKeyValueCard(
              title: (m['target'] ?? 'Pest/Disease').toString(),
              accent: Color(0xFFEF4444),
              data: m,
              keys: const ['activeIngredient', 'when', 'dose'],
              bullets: [..._stringList(m['safety']), ..._stringList(m['bullets'])],
            ),
          ),
        );
      }

      content.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildBulletsCard(
            title: 'IPM (First Choice)',
            bullets: _stringList(plan['ipm']),
            accent: Color(0xFF10B981),
            icon: Icons.eco,
          ),
        ),
      );
    } else {
      final stagesRaw = plan['stages'];
      final stages = (stagesRaw is List) ? stagesRaw : const [];
      for (final s in stages) {
        if (s is! Map) continue;
        final m = s.cast<String, dynamic>();
        content.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildKeyValueCard(
              title: (m['stage'] ?? 'Stage').toString(),
              accent: accent,
              data: m,
              keys: const ['duration'],
              bullets: _stringList(m['bullets']),
            ),
          ),
        );
      }

      content.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildBulletsCard(
            title: 'Quick Tips',
            bullets: _stringList(plan['quickTips']),
            accent: Color(0xFF10B981),
            icon: Icons.lightbulb,
          ),
        ),
      );
    }

    content.add(
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildBulletsCard(
          title: 'Warnings',
          bullets: warnings,
          accent: Color(0xFFEF4444),
          icon: Icons.health_and_safety,
        ),
      ),
    );

    content.add(SizedBox(height: 10));

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), backgroundColor: Color(0xFF10B981)),
    );
  }
}