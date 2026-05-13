import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/fertilizer_havest_advisert/api_service.dart';
import '../../widgets/common_widets.dart';
import '../../utils/theme.dart';

class AdvisoryResultScreen extends StatelessWidget {
  final AdvisoryResult result;

  const AdvisoryResultScreen({super.key, required this.result});

  String _cropTitle(AdvisoryResult r) {
    final d = r.cropDisplayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    final c = r.crop.trim();
    if (c.isEmpty) return 'Your crop';
    return c[0].toUpperCase() + c.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Advisory Report',
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
          // Crop banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🌾', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advisory for',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _cropTitle(result),
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    InfoChip(
                      label: '${result.fertilizers.length} Fertilizers',
                      color: Colors.white,
                      icon: Icons.science_rounded,
                    ),
                    const SizedBox(height: 6),
                    InfoChip(
                      label: '${result.pesticides.length} Alerts',
                      color: Colors.white,
                      icon: Icons.warning_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (result.cropInsight != null && result.cropInsight!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'AI crop note',
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.cropInsight!.trim(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Fertilizers Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Fertilizer Recommendations',
                    icon: Icons.science_rounded,
                    color: AppTheme.fertilizerColor,
                  ),
                  const SizedBox(height: 16),
                  if (result.fertilizers.isEmpty)
                    EmptyState(
                      icon: Icons.check_circle_rounded,
                      message:
                          'Nutrient levels are optimal. No fertilizers needed.',
                      color: Colors.green,
                    )
                  else
                    ...result.fertilizers.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FertilizerCard(name: f),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pesticides Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Pest & Disease Alerts',
                    icon: Icons.bug_report_rounded,
                    color: AppTheme.pesticideColor,
                  ),
                  const SizedBox(height: 16),
                  if (result.pesticides.isEmpty)
                    EmptyState(
                      icon: Icons.shield_rounded,
                      message:
                          'No pest or disease risk detected under current conditions.',
                      color: Colors.green,
                    )
                  else
                    ...result.pesticides.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PesticideCard(
                          issue: p.issue,
                          solution: p.solution,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These recommendations are based on rule-based analysis. '
                    'Always consult a certified agronomist for critical decisions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
