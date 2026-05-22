import axios from 'axios';

import { fetchOpenMeteoWeather } from '../weather/openMeteoWeather.service.js';

import { getPakistanSeason, getPakistanSeasonCandidateCrops } from '../../utils/pakistanSeason.js';



function _extractJsonObject(text) {

  if (typeof text !== 'string') return null;

  const trimmed = text.trim();



  const noFences = trimmed

    .replace(/```json\n?/gi, '')

    .replace(/```\n?/g, '')

    .trim();



  try {

    return JSON.parse(noFences);

  } catch {

    const start = noFences.indexOf('{');

    const end = noFences.lastIndexOf('}');

    if (start >= 0 && end > start) {

      const candidate = noFences.substring(start, end + 1);

      try {

        return JSON.parse(candidate);

      } catch {

        return null;

      }

    }

    return null;

  }

}



function _getGeminiText(responseData) {

  const parts = responseData?.candidates?.[0]?.content?.parts;

  if (!Array.isArray(parts)) return responseData?.candidates?.[0]?.content?.parts?.[0]?.text;

  return parts

    .map((p) => (p && typeof p.text === 'string' ? p.text : ''))

    .join('')

    .trim();

}



export async function getWeatherBasedCropRecommendation({ lat, lng, locationLabel }) {

  if (!process.env.GEMINI_API_KEY) {

    const err = new Error('Gemini API key is not configured (GEMINI_API_KEY)');

    err.statusCode = 500;

    throw err;

  }



  const weather = await fetchOpenMeteoWeather({ lat, lng });

  const season = getPakistanSeason(new Date());

  const candidateCrops = getPakistanSeasonCandidateCrops(season.id);



  const loc = typeof locationLabel === 'string' && locationLabel.trim() ? locationLabel.trim() : 'Pakistan (user location)';



  const prompt = `You are an expert agronomist for Pakistan.



Task: Recommend the best crops to plant NOW based on weather + season.



Writing rules (strict):

- Use very simple English.

- Use short sentences.

- Keep each bullet under ~12 words.

- No long paragraphs.

- Use easy local words when helpful.



Location: ${loc}

Coordinates: lat=${weather.coordinates.lat}, lng=${weather.coordinates.lng}

Season in Pakistan: ${season.name} (${season.window})



Weather (current):

- Temperature: ${weather.current.temperatureC ?? 'N/A'} °C

- Humidity: ${weather.current.humidityPct ?? 'N/A'} %

- Wind: ${weather.current.windSpeedKmh ?? 'N/A'} km/h

- Weather code: ${weather.current.weatherCode ?? 'N/A'}



Weather (forecast summary):

- Precipitation next 24h: ${weather.forecastSummary.precipNext24hMm ?? 'N/A'} mm

- Precipitation next 3 days: ${weather.forecastSummary.precipNext3DaysMm ?? 'N/A'} mm



Pakistan season candidate crops (use these as the primary shortlist; you may add 1-2 others ONLY if very suitable in Pakistan):

${candidateCrops.map((c) => `- ${c}`).join('\n')}



Return ONLY valid JSON (no markdown, no extra text) in this schema:



{

  "season": {"id": "kharif|rabi", "name": "...", "window": "..."},

  "location": {"label": "...", "coordinates": {"lat": number, "lng": number}},

  "weather": {

    "current": {"temperatureC": number|null, "humidityPct": number|null, "windSpeedKmh": number|null, "weatherCode": number|null},

    "forecastSummary": {"precipNext24hMm": number|null, "precipNext3DaysMm": number|null}

  },

  "recommendations": [

    {

      "crop": "...",

      "suitabilityScore": 1-10,

      "why": ["short farmer-friendly reasons"],

      "plantingWindow": "...",

      "waterNeed": "Low|Medium|High",

      "keyRisks": ["..."],

      "actionTips": ["..."],

      "notRecommendedIf": ["..."],

      "pakistanNotes": "..."

    }

  ],

  "notRecommended": [

    {"crop": "...", "reason": "..."}

  ],

  "generalAdvisory": ["..."]

}



Rules:

- Focus on crops common in Pakistan and practical for farmers.

- Use the season strongly. Do not recommend out-of-season crops.

- Keep it concise but helpful. Provide 5-7 recommendations.

- Ensure JSON is parseable.`;



  const model = process.env.GEMINI_TEXT_MODEL || 'gemini-2.5-flash-lite';

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`;



  const response = await axios.post(

    url,

    {

      contents: [{ role: 'user', parts: [{ text: prompt }] }],

      generationConfig: {

        temperature: 0.4,

        maxOutputTokens: 2500,

        topP: 0.9,

        topK: 40,

        responseMimeType: 'application/json',

      },

    },

    {

      timeout: 45000,

      headers: { 'Content-Type': 'application/json' },

    }

  );



  const text = _getGeminiText(response.data);

  const json = _extractJsonObject(text);



  if (!json) {

    const err = new Error('Failed to parse Gemini response');

    err.statusCode = 502;

    err.details = { raw: String(text || '').slice(0, 800) };

    throw err;

  }



  return {

    success: true,

    season,

    weather,

    recommendation: json,

    generatedAt: new Date().toISOString(),

  };

}


