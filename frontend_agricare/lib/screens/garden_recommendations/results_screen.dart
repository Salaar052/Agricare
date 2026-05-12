// ============================================================
// results_screen.dart — Screen 2: Plant Recommendation Results
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/garden_recommendation/plant_model.dart';
import './plant_card.dart';

class ResultsScreen extends StatelessWidget {
  final RecommendationResponse response;
  final RecommendationRequest request;

  const ResultsScreen({
    super.key,
    required this.response,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF5),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: response.plants.isEmpty
                  ? _buildEmpty()
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Recommendations',
                      style: GoogleFonts.merriweather(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                    Text(
                      '${response.plants.length} plants matched your conditions',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildConditionPills(),
        ],
      ),
    );
  }

  Widget _buildConditionPills() {
    final conditions = [
      {'icon': '🌡️', 'label': '${request.temperature.round()}°C'},
      {'icon': '📍', 'label': _capitalize(request.space)},
      {'icon': '☀️', 'label': _capitalize(request.sunlight)},
      {'icon': '💧', 'label': _capitalize(request.water)},
    ];

    return Row(
      children: conditions.map((c) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
                right: c == conditions.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                Text(c['icon']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  c['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D6A4F),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        // AI notice banner
        _buildAiBanner(),
        const SizedBox(height: 20),

        // Plant cards
        ...response.plants.asMap().entries.map((entry) {
          return PlantCard(
            plant: entry.value,
            rank: entry.key + 1,
          );
        }),
      ],
    );
  }

  Widget _buildAiBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Enhanced Explanations',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Plants selected by our rule engine. Pros, cons & tips powered by Gemini AI.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'No matches found',
              style: GoogleFonts.merriweather(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              response.message ??
                  'No plants match your current conditions.\nTry adjusting temperature, space, or sunlight.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}