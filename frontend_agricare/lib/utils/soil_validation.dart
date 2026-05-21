/// Client-side soil & weather validation (mirrors backend ranges).
class SoilValidation {
  static const double nitrogenMin = 0;
  static const double nitrogenMax = 500;
  static const double phosphorusMin = 0;
  static const double phosphorusMax = 500;
  static const double potassiumMin = 0;
  static const double potassiumMax = 500;
  static const double temperatureMin = -10;
  static const double temperatureMax = 55;
  static const double humidityMin = 0;
  static const double humidityMax = 100;

  static String? validateNutrient(String? value, String label, double min, double max) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid number for $label';
    if (n < min || n > max) {
      return '$label must be between ${min.toInt()} and ${max.toInt()} mg/kg';
    }
    return null;
  }

  static String? validateTemperature(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid temperature';
    if (n < temperatureMin || n > temperatureMax) {
      return 'Temperature must be between ${temperatureMin.toInt()}°C and ${temperatureMax.toInt()}°C';
    }
    return null;
  }

  static String? validateHumidity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Humidity is required';
    }
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid humidity';
    if (n < humidityMin || n > humidityMax) {
      return 'Humidity must be between ${humidityMin.toInt()}% and ${humidityMax.toInt()}%';
    }
    return null;
  }
}
