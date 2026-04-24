// File: lib/screens/crop_recommendation/growth_plan_screen.dart
// REDESIGNED - Combines API fetching with comprehensive plan display

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class _GrowthPlanScreenState extends State<GrowthPlanScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String? _selectedPlanType;
  bool _isLoading = false;
  Map<String, dynamic>? _growthPlan;
  String? _errorMessage;

  String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1/crop-recommendation/growth-plan';
    }
    return "http://192.168.0.101:5000/api/v1/crop-recommendation/growth-plan";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchGrowthPlan(String planType) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _growthPlan = null;
      _selectedPlanType = planType;
    });

    try {
      final requestData = {
        'cropName': widget.cropName,
        'soilData': widget.soilData,
        'planType': planType,
      };

      print('📤 Fetching $planType plan for: ${widget.cropName}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(
        const Duration(seconds: 70),
        onTimeout: () => throw Exception('Request timeout - AI taking too long'),
      );

      print('📥 Plan Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true && jsonData['growthPlan'] != null) {
          setState(() {
            _growthPlan = jsonData['growthPlan'];
            _isLoading = false;
          });
        } else {
          throw Exception(jsonData['error'] ?? 'Failed to generate plan');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error');
      }
    } catch (e) {
      print('❌ Plan Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
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
        actions: [
          if (_growthPlan != null)
            IconButton(
              icon: Icon(Icons.share, color: Color(0xFF4A7C2C)),
              onPressed: () => _showShareOptions(),
            ),
        ],
      ),
      body: _growthPlan == null
          ? _buildInitialView()
          : _buildPlanView(),
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
          if (_isLoading) _buildLoadingState(),
          if (_errorMessage != null) _buildErrorState(),
          if (!_isLoading && _errorMessage == null) _buildOptionCards(),
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
    final isSelected = _selectedPlanType == planType;
    
    return InkWell(
      onTap: () => _fetchGrowthPlan(planType),
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

  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF10B981),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Generating Your Plan...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI is creating a detailed plan\nThis may take up to 60 seconds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
          SizedBox(height: 16),
          Text(
            'Error Generating Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF991B1B),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _selectedPlanType = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PLAN VIEW - Tabbed Display
  // ============================================

  Widget _buildPlanView() {
    final overview = _growthPlan!['overview'] ?? {};
    
    return Column(
      children: [
        // Overview Card
        Container(
          width: double.infinity,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('🌾', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      overview['description'] ?? 'Comprehensive growth plan for ${widget.cropName}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _buildOverviewChip(Icons.timer, overview['totalGrowthPeriod'] ?? 'N/A'),
                  SizedBox(width: 8),
                  _buildOverviewChip(Icons.trending_up, overview['difficulty'] ?? 'N/A'),
                  SizedBox(width: 8),
                  _buildOverviewChip(Icons.wb_sunny, overview['bestSeason'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Color(0xFF10B981),
            unselectedLabelColor: Color(0xFF6B7280),
            indicatorColor: Color(0xFF10B981),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontSize: 13),
            tabs: [
              Tab(text: 'Growth Stages'),
              Tab(text: 'Irrigation'),
              Tab(text: 'Fertilization'),
              Tab(text: 'Pest Control'),
              Tab(text: 'Soil Care'),
              Tab(text: 'Harvesting'),
              Tab(text: 'Weather'),
              Tab(text: 'Costs & Tips'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGrowthStagesTab(),
              _buildIrrigationTab(),
              _buildFertilizationTab(),
              _buildPestDiseaseTab(),
              _buildSoilManagementTab(),
              _buildHarvestingTab(),
              _buildWeatherTab(),
              _buildCostAndTipsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TAB BUILDERS (Exact same as old code)
  // ============================================

  Widget _buildGrowthStagesTab() {
    final stages = _growthPlan!['growthStages'] as List? ?? [];
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];
        return _buildStageCard(index + 1, stage);
      },
    );
  }

  Widget _buildStageCard(int number, Map<String, dynamic> stage) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['stage'] ?? 'Stage $number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      Text(
                        stage['duration'] ?? 'Duration not specified',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage['description'] ?? '',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                if (stage['keyActivities'] != null) ...[
                  SizedBox(height: 12),
                  Text(
                    'Key Activities:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...(stage['keyActivities'] as List).map((activity) =>
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Color(0xFF10B981), fontSize: 16)),
                          Expanded(child: Text(activity.toString(), style: TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationTab() {
    final irrigation = _growthPlan!['irrigationPlan'] ?? {};
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildInfoCard('💧 Frequency', irrigation['frequency'] ?? 'Not specified', Color(0xFF3B82F6)),
        SizedBox(height: 12),
        _buildInfoCard('🚿 Method', irrigation['method'] ?? 'Not specified', Color(0xFF8B5CF6)),
        SizedBox(height: 12),
        _buildInfoCard('💦 Water Requirement', irrigation['waterRequirement'] ?? 'Not specified', Color(0xFF06B6D4)),
        SizedBox(height: 16),
        _buildListSection('⚠️ Critical Periods', irrigation['criticalPeriods'] ?? [], Color(0xFFEF4444)),
        SizedBox(height: 16),
        _buildListSection('💡 Irrigation Tips', irrigation['tips'] ?? [], Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildFertilizationTab() {
    final fertilization = _growthPlan!['fertilizationPlan'] ?? {};
    final basal = fertilization['basalApplication'] ?? {};
    final topDressing = fertilization['topDressing'] ?? [];
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Basal Application', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 12),
        _buildNutrientCard('N', 'Nitrogen', basal['nitrogen'] ?? 'Not specified'),
        SizedBox(height: 8),
        _buildNutrientCard('P', 'Phosphorus', basal['phosphorus'] ?? 'Not specified'),
        SizedBox(height: 8),
        _buildNutrientCard('K', 'Potassium', basal['potassium'] ?? 'Not specified'),
        SizedBox(height: 20),
        if (topDressing.isNotEmpty) ...[
          Text('Top Dressing Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 12),
          ...topDressing.map((td) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text(td['stage'] ?? 'Not specified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Nutrients: ${td['nutrients'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                Text('Amount: ${td['amount'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
              ],
            ),
          )).toList(),
        ],
        SizedBox(height: 16),
        _buildListSection('🌱 Organic Options', fertilization['organicOptions'] ?? [], Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildNutrientCard(String symbol, String name, String details) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(symbol, style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text(details, style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestDiseaseTab() {
    final pestManagement = _growthPlan!['pestAndDiseaseManagement'] ?? {};
    final pests = pestManagement['commonPests'] ?? [];
    final diseases = pestManagement['commonDiseases'] ?? [];
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Common Pests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 12),
        ...pests.map((pest) => _buildPestDiseaseCard(pest, true)).toList(),
        SizedBox(height: 20),
        Text('Common Diseases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 12),
        ...diseases.map((disease) => _buildPestDiseaseCard(disease, false)).toList(),
        SizedBox(height: 16),
        _buildListSection('🌿 Organic Solutions', pestManagement['organicSolutions'] ?? [], Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildPestDiseaseCard(Map<String, dynamic> item, bool isPest) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isPest ? '🐛' : '🦠', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Expanded(child: Text(item['name'] ?? 'Unknown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          SizedBox(height: 12),
          _buildDetailRow('Symptoms', item['symptoms'] ?? 'N/A'),
          SizedBox(height: 8),
          _buildDetailRow('Prevention', item['prevention'] ?? 'N/A'),
          SizedBox(height: 8),
          _buildDetailRow('Treatment', item['treatment'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + ':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _buildSoilManagementTab() {
    final soil = _growthPlan!['soilManagement'] ?? {};
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildListSection('🌍 Soil Preparation', soil['preparation'] ?? [], Color(0xFF92400E)),
        SizedBox(height: 16),
        _buildListSection('🔧 Maintenance Tasks', soil['maintenance'] ?? [], Color(0xFF7C2D12)),
        SizedBox(height: 16),
        _buildInfoCard('⚖️ pH Adjustment', soil['phAdjustment'] ?? 'Not specified', Color(0xFF8B5CF6)),
        SizedBox(height: 12),
        _buildInfoCard('🌿 Organic Matter', soil['organicMatter'] ?? 'Not specified', Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildHarvestingTab() {
    final harvest = _growthPlan!['harvestingGuide'] ?? {};
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildListSection('✅ Maturity Indicators', harvest['maturityIndicators'] ?? [], Color(0xFF10B981)),
        SizedBox(height: 16),
        _buildInfoCard('✂️ Harvest Method', harvest['harvestMethod'] ?? 'Not specified', Color(0xFFF59E0B)),
        SizedBox(height: 12),
        _buildInfoCard('📦 Expected Yield', harvest['expectedYield'] ?? 'Not specified', Color(0xFF8B5CF6)),
        SizedBox(height: 12),
        _buildInfoCard('🏪 Storage Advice', harvest['storageAdvice'] ?? 'Not specified', Color(0xFF3B82F6)),
        SizedBox(height: 16),
        _buildListSection('📋 Post-Harvest Steps', harvest['postHarvest'] ?? [], Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildWeatherTab() {
    final weather = _growthPlan!['weatherConsiderations'] ?? {};
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildInfoCard('🌡️ Temperature Management', weather['temperatureManagement'] ?? 'Not specified', Color(0xFFEF4444)),
        SizedBox(height: 12),
        _buildInfoCard('💧 Humidity Management', weather['humidityManagement'] ?? 'Not specified', Color(0xFF06B6D4)),
        SizedBox(height: 12),
        _buildInfoCard('☔ Rainfall Management', weather['rainfallManagement'] ?? 'Not specified', Color(0xFF3B82F6)),
        SizedBox(height: 16),
        _buildListSection('⚠️ Extreme Weather Protection', weather['extremeWeatherProtection'] ?? [], Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildCostAndTipsTab() {
    final cost = _growthPlan!['costEstimation'] ?? {};
    final tips = _growthPlan!['proTips'] ?? [];
    final warnings = _growthPlan!['warnings'] ?? [];
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Cost Estimation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 12),
        _buildCostRow('Seed', cost['seedCost']),
        _buildCostRow('Fertilizer', cost['fertilizerCost']),
        _buildCostRow('Irrigation', cost['irrigationCost']),
        _buildCostRow('Labor', cost['laborCost']),
        Divider(height: 24),
        _buildCostRow('Total Estimated', cost['totalEstimated'], isTotal: true),
        SizedBox(height: 8),
        _buildInfoCard('💰 Break-Even Point', cost['breakEvenPoint'] ?? 'Not specified', Color(0xFF10B981)),
        SizedBox(height: 24),
        _buildListSection('💡 Professional Tips', tips, Color(0xFF10B981)),
        SizedBox(height: 16),
        _buildListSection('⚠️ Important Warnings', warnings, Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildCostRow(String label, dynamic value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            value?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Color(0xFF10B981) : Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // REUSABLE WIDGETS
  // ============================================

  Widget _buildInfoCard(String title, String content, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List items, Color color) {
    if (items.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                SizedBox(width: 8),
                Expanded(child: Text(item.toString(), style: TextStyle(fontSize: 13, height: 1.5))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share Growth Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
              title: Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('PDF Export');
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Color(0xFF10B981)),
              title: Text('Share Text'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Text Sharing');
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF3B82F6)),
              title: Text('Email Plan'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Email');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!'), backgroundColor: Color(0xFF10B981)),
    );
  }
}