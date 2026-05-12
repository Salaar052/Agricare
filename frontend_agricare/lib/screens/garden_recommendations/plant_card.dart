// ============================================================
// plant_card.dart — Plant Recommendation Result Card
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/garden_recommendation/plant_model.dart';

class PlantCard extends StatefulWidget {
  final PlantRecommendation plant;
  final int rank;

  const PlantCard({super.key, required this.plant, required this.rank});

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _rankColor {
    switch (widget.rank) {
      case 1:
        return const Color(0xFFF59E0B); // Gold
      case 2:
        return const Color(0xFF94A3B8); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF2D6A4F);
    }
  }

  String get _rankLabel {
    switch (widget.rank) {
      case 1:
        return '🥇 Best Match';
      case 2:
        return '🥈 Great Pick';
      case 3:
        return '🥉 Good Option';
      default:
        return '#${widget.rank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card Header ──────────────────────────────────
          _buildHeader(),

          // ── Score Bar ────────────────────────────────────
          _buildScoreBar(),

          // ── Expandable Details ───────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded ? _buildDetails() : const SizedBox.shrink(),
          ),

          // ── Toggle Button ────────────────────────────────
          _buildToggle(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Emoji avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.plant.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name + category + rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _rankColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _rankLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _rankColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.plant.name,
                  style: GoogleFonts.merriweather(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B4332),
                  ),
                ),
                Text(
                  widget.plant.category,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Score badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _rankColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _rankColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${widget.plant.score}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _rankColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suitability Score',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              Text(
                '${widget.plant.score}/${widget.plant.maxScore}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: widget.plant.scorePercent.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE5E7EB),
            progressColor: _rankColor,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final ai = widget.plant.ai;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Pros
          _buildSection(
            icon: '✅',
            title: 'Pros',
            color: const Color(0xFF059669),
            items: ai.pros,
          ),

          const SizedBox(height: 16),

          // Cons
          _buildSection(
            icon: '⚠️',
            title: 'Cons',
            color: const Color(0xFFD97706),
            items: ai.cons,
          ),

          const SizedBox(height: 16),

          // Tips
          if (ai.tips.isNotEmpty) _buildTipsBox(ai.tips),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsBox(String tips) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care Tip',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tips,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _expanded = !_expanded);
        _expanded ? _controller.forward() : _controller.reverse();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _expanded ? 'Show less' : 'View details',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D6A4F),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF2D6A4F),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}