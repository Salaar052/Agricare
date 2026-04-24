// File: lib/screens/crop_recommendation/soil_mineral_form_screen.dart
// UPDATED VERSION - Direct Navigation to Growth Plan Screen

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'soil_input_field.dart';
import 'growth_plan_screen.dart';

class SoilMineralFormScreen extends StatefulWidget {
  const SoilMineralFormScreen({Key? key}) : super(key: key);

  @override
  _SoilMineralFormScreenState createState() => _SoilMineralFormScreenState();
}

class _SoilMineralFormScreenState extends State<SoilMineralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String get apiUrl {
    if (kIsWeb) {
      return 'http://10.209.229.141/api/v1/crop-recommendation/recommend';
    }
    return "http://10.209.229.141:5000/api/v1/crop-recommendation/recommend";
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prepare data
      final soilData = {
        'N': double.parse(_nitrogenController.text),
        'P': double.parse(_phosphorusController.text),
        'K': double.parse(_potassiumController.text),
        'temperature': double.parse(_temperatureController.text),
        'humidity': double.parse(_humidityController.text),
        'ph': double.parse(_phController.text),
        'rainfall': double.parse(_rainfallController.text),
      };

      print('📤 Sending request to: $apiUrl');
      print('📤 Data: $soilData');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(soilData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout - Server took too long to respond'),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          print('✅ Success: ${jsonData['recommended_crop']}');
          
          // Navigate directly to Growth Plan Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GrowthPlanScreen(
                cropName: jsonData['recommended_crop'],
                recommendationData: jsonData,
                soilData: soilData,
              ),
            ),
          );
        } else {
          throw Exception(jsonData['error'] ?? 'Prediction failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = _formatError(e.toString());
      });
      _showErrorDialog(_formatError(e.toString()));
    }
  }

  String _formatError(String error) {
    if (error.contains('Failed host lookup') || error.contains('SocketException')) {
      return 'Cannot connect to server.\n\n'
          '✓ Make sure backend is running on port 5000\n'
          '✓ Android Emulator: Use http://10.0.2.2:5000\n'
          '✓ iOS Simulator: Use http://localhost:5000\n'
          '✓ Real Device: Use your PC\'s IP address';
    }
    if (error.contains('Connection refused')) {
      return 'Server not running.\n\n'
          '✓ Start Backend: npm start (port 5000)\n'
          '✓ Check .env file has GEMINI_API_KEY';
    }
    if (error.contains('timeout')) {
      return 'Request timeout.\n\n'
          '✓ The AI service is taking too long\n'
          '✓ Please try again with a stable connection';
    }
    return error.replaceAll('Exception: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF4A7C2C))),
          ),
        ],
      ),
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
        title: Text(
          'Soil Mineral Data',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                SizedBox(height: 24),
                _buildSectionTitle('Soil Nutrients (NPK)'),
                SizedBox(height: 12),
                SoilInputField(
                  controller: _nitrogenController,
                  label: 'Nitrogen (N)',
                  hint: 'Enter nitrogen value (kg/ha)',
                  icon: Icons.grass,
                  suffix: 'kg/ha',
                ),
                SizedBox(height: 16),
                SoilInputField(
                  controller: _phosphorusController,
                  label: 'Phosphorus (P)',
                  hint: 'Enter phosphorus value (kg/ha)',
                  icon: Icons.water_drop,
                  suffix: 'kg/ha',
                ),
                SizedBox(height: 16),
                SoilInputField(
                  controller: _potassiumController,
                  label: 'Potassium (K)',
                  hint: 'Enter potassium value (kg/ha)',
                  icon: Icons.eco,
                  suffix: 'kg/ha',
                ),
                SizedBox(height: 24),
                _buildSectionTitle('Soil Properties'),
                SizedBox(height: 12),
                SoilInputField(
                  controller: _phController,
                  label: 'pH Level',
                  hint: 'Enter pH value (0-14)',
                  icon: Icons.science_outlined,
                  suffix: 'pH',
                ),
                SizedBox(height: 24),
                _buildSectionTitle('Environmental Factors'),
                SizedBox(height: 12),
                SoilInputField(
                  controller: _temperatureController,
                  label: 'Temperature',
                  hint: 'Enter temperature (°C)',
                  icon: Icons.thermostat,
                  suffix: '°C',
                ),
                SizedBox(height: 16),
                SoilInputField(
                  controller: _humidityController,
                  label: 'Humidity',
                  hint: 'Enter humidity (%)',
                  icon: Icons.opacity,
                  suffix: '%',
                ),
                SizedBox(height: 16),
                SoilInputField(
                  controller: _rainfallController,
                  label: 'Rainfall',
                  hint: 'Enter rainfall (mm)',
                  icon: Icons.cloud,
                  suffix: 'mm',
                ),
                SizedBox(height: 32),
                _buildSubmitButton(),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'Server: $apiUrl',
                    style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A7C2C), Color(0xFF5D9A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A7C2C).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter your soil test values to get personalized crop recommendations with complete growth plans',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4A7C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: Color(0xFF4A7C2C).withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Get Recommendations',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}