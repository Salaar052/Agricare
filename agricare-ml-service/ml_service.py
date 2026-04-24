"""
AgriCare ML Service - CORRECTED to match Streamlit app
This version properly uses the MinMaxScaler and crop dictionary
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import os

app = Flask(__name__)
CORS(app)

# ============================================
# LOAD MODEL AND SCALER (from Streamlit repo)
# ============================================
print("Loading model and scaler...")

try:
    # Load MinMaxScaler (NOT StandardScaler!)
    with open('minmaxscaler.pkl', 'rb') as f:
        scaler = pickle.load(f)
    print("✓ MinMaxScaler loaded successfully!")
    
    # Load RandomForest model
    with open('model.pkl', 'rb') as f:
        model = pickle.load(f)
    print("✓ Model loaded successfully!")
    print(f"✓ Model type: {type(model)}")
    
except Exception as e:
    print(f"❌ Error loading files: {e}")
    print("Make sure 'model.pkl' and 'minmaxscaler.pkl' are in this directory!")
    model = None
    scaler = None

# ============================================
# CROP DICTIONARY (from Streamlit app)
# This maps the model's numeric predictions to crop names
# ============================================
CROP_DICT = {
    1: 'rice',
    2: 'maize',
    3: 'chickpea',
    4: 'kidneybeans',
    5: 'pigeonpeas',
    6: 'mothbeans',
    7: 'mungbean',
    8: 'blackgram',
    9: 'lentil',
    10: 'pomegranate',
    11: 'banana',
    12: 'mango',
    13: 'grapes',
    14: 'watermelon',
    15: 'muskmelon',
    16: 'apple',
    17: 'orange',
    18: 'papaya',
    19: 'coconut',
    20: 'cotton',
    21: 'jute',
    22: 'coffee'
}

# ============================================
# API ENDPOINTS
# ============================================

@app.route('/health', methods=['GET'])
def health_check():
    """Check if service is healthy"""
    return jsonify({
        'status': 'healthy' if (model is not None and scaler is not None) else 'error',
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None,
        'scaler_type': str(type(scaler).__name__) if scaler else None
    })

@app.route('/predict', methods=['POST'])
def predict_crop():
    """
    Predict crop based on 7 input parameters
    
    Expected JSON:
    {
        "N": 90,
        "P": 42,
        "K": 43,
        "temperature": 20.879744,
        "humidity": 82.002744,
        "ph": 6.502985,
        "rainfall": 202.935536
    }
    """
    try:
        if model is None or scaler is None:
            return jsonify({
                'error': 'Model or scaler not loaded',
                'details': 'Please check if model.pkl and minmaxscaler.pkl exist'
            }), 500
        
        data = request.json
        print(f"\n📥 Received data: {data}")
        
        # Validate required fields
        required_fields = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
        missing = [f for f in required_fields if f not in data]
        
        if missing:
            return jsonify({
                'error': 'Missing required fields',
                'missing': missing,
                'required': required_fields
            }), 400
        
        # Extract values in EXACT order (critical!)
        N = float(data['N'])
        P = float(data['P'])
        K = float(data['K'])
        temperature = float(data['temperature'])
        humidity = float(data['humidity'])
        ph = float(data['ph'])
        rainfall = float(data['rainfall'])
        
        # Create input array in correct order: [N, P, K, temp, humidity, ph, rainfall]
        input_data = np.array([[N, P, K, temperature, humidity, ph, rainfall]])
        print(f"📊 Input array: {input_data}")
        
        # Scale the input using MinMaxScaler (same as Streamlit)
        scaled_input = scaler.transform(input_data)
        print(f"📏 Scaled input: {scaled_input}")
        
        # Make prediction (returns a number 1-22)
        prediction_number = model.predict(scaled_input)[0]
        print(f"🔢 Prediction number: {prediction_number}")
        
        # Convert number to crop name using dictionary
        crop_name = CROP_DICT.get(int(prediction_number), "Unknown crop")
        print(f"🌾 Crop name: {crop_name}")
        
        # Get probability scores for all crops
        try:
            probabilities = model.predict_proba(scaled_input)[0]
            confidence = float(max(probabilities) * 100)
            
            # Get top 3 predictions
            top_3_indices = np.argsort(probabilities)[-3:][::-1]
            top_3_crops = [
                {
                    'crop': CROP_DICT.get(idx + 1, f'Crop_{idx + 1}'),
                    'confidence': round(float(probabilities[idx] * 100), 2)
                }
                for idx in top_3_indices
            ]
        except:
            # If predict_proba not available
            confidence = 100.0
            top_3_crops = [{'crop': crop_name, 'confidence': 100.0}]
        
        response = {
            'success': True,
            'recommended_crop': crop_name,
            'confidence': round(confidence, 2),
            'all_recommendations': top_3_crops,
            'input_data': {
                'N': N,
                'P': P,
                'K': K,
                'temperature': temperature,
                'humidity': humidity,
                'ph': ph,
                'rainfall': rainfall
            }
        }
        
        print(f"✅ Response: {response}\n")
        return jsonify(response), 200
        
    except ValueError as e:
        print(f"❌ ValueError: {e}")
        return jsonify({
            'error': 'Invalid input values',
            'details': str(e)
        }), 400
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': 'Prediction failed',
            'details': str(e)
        }), 500

@app.route('/crops', methods=['GET'])
def get_crops():
    """Get list of all 22 crops"""
    return jsonify({
        'crops': list(CROP_DICT.values()),
        'total': len(CROP_DICT)
    })

@app.route('/test', methods=['GET'])
def test_prediction():
    """Test endpoint with sample data from Streamlit"""
    test_data = {
        'N': 90,
        'P': 42,
        'K': 43,
        'temperature': 20.879744,
        'humidity': 82.002744,
        'ph': 6.502985,
        'rainfall': 202.935536
    }
    
    # Call predict internally
    from flask import Request
    with app.test_request_context(json=test_data):
        response = predict_crop()
        return response

# ============================================
# START SERVER
# ============================================

if __name__ == '__main__':
    print("\n" + "="*70)
    print("🌾 AgriCare ML Microservice (Streamlit-compatible)")
    print("="*70)
    print(f"Model loaded: {'✓' if model else '✗'}")
    print(f"Scaler loaded: {'✓' if scaler else '✗'}")
    print(f"Scaler type: {type(scaler).__name__ if scaler else 'N/A'}")
    print(f"Total crops: {len(CROP_DICT)}")
    print("="*70)
    print("\n📡 Endpoints:")
    print("  GET  /health  - Check service status")
    print("  POST /predict - Predict crop")
    print("  GET  /crops   - List all crops")
    print("  GET  /test    - Test with sample data")
    print("\n🧪 Test command:")
    print("  curl http://localhost:5001/test")
    print("="*70 + "\n")
    
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=True)