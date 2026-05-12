import axios from 'axios';

function _inferImageMimeType({ mimeType, filename }) {
  const mt = typeof mimeType === 'string' ? mimeType.trim().toLowerCase() : '';
  if (mt.startsWith('image/')) return mt;

  const name = typeof filename === 'string' ? filename.toLowerCase() : '';
  const dot = name.lastIndexOf('.');
  const ext = dot >= 0 ? name.slice(dot) : '';

  // Flutter/Dart http multipart may send application/octet-stream.
  if (!mt || mt === 'application/octet-stream') {
    if (ext === '.png') return 'image/png';
    if (ext === '.webp') return 'image/webp';
    if (ext === '.heic') return 'image/heic';
    if (ext === '.heif') return 'image/heif';
    // default for jpg/jpeg or unknown extension
    return 'image/jpeg';
  }

  // If something else slipped through (e.g. application/pdf), reject early.
  return null;
}

function _extractJsonObject(text) {
  if (typeof text !== 'string') return null;
  const trimmed = text.trim();

  // Remove markdown fences if present
  const noFences = trimmed
    .replace(/```json\n?/gi, '')
    .replace(/```\n?/g, '')
    .trim();

  // Fast path
  try {
    return JSON.parse(noFences);
  } catch {
    // Try to salvage by extracting first JSON object substring
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

/**
 * Extract lab report values from an image using Gemini Vision.
 * Returns an object like:
 * { N: number|null, P: number|null, K: number|null, ph: number|null, temperature: number|null, humidity: number|null, rainfall: number|null }
 * or { error: "not_a_soil_report" }
 */
export async function extractLabReportValuesFromImage({ buffer, mimeType, filename }) {
  if (!process.env.GEMINI_API_KEY) {
    const error = new Error('Gemini API key is not configured (GEMINI_API_KEY)');
    error.statusCode = 500;
    throw error;
  }

  if (!buffer || !(buffer instanceof Buffer)) {
    const error = new Error('Invalid image buffer');
    error.statusCode = 400;
    throw error;
  }

  const base64 = buffer.toString('base64');
  const safeMimeType = _inferImageMimeType({ mimeType, filename });
  if (!safeMimeType) {
    const error = new Error(`Unsupported MIME type: ${mimeType || 'unknown'}`);
    error.statusCode = 400;
    throw error;
  }
  // Prefer an env override, but default to a generally-available multimodal model.
  // Some keys/environments do not have access to experimental model names.
  const preferredModel = process.env.GEMINI_VISION_MODEL;
  const modelCandidates = [
    preferredModel,
    // Match commonly-available names from v1beta ListModels for many keys
    'gemini-flash-latest',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    // Image-tuned model (if available) can be a good fallback
    'gemini-2.5-flash-image',
  ].filter(Boolean);

  const prompt = `You are a soil-lab report parser.
Extract ONLY these 7 numeric values from the lab report image:
- N  (Nitrogen, kg/ha)
- P  (Phosphorus, kg/ha)
- K  (Potassium, kg/ha)
- ph (Soil pH, 0-14)
- temperature (°C)
- humidity (%)
- rainfall (mm)

Return ONLY valid JSON.
Use null for any value you cannot find.
Example: {"N":40,"P":55,"K":43,"ph":6.5,"temperature":25,"humidity":82,"rainfall":202}
If the image is not a soil test/lab report, return {"error":"not_a_soil_report"}.
No extra text.`;

  let lastError = null;

  for (const model of modelCandidates) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`;

    // Try twice per model: first attempt, then a stricter retry if parsing fails.
    for (let attempt = 1; attempt <= 2; attempt += 1) {
      const strictPrompt =
        attempt === 1
          ? prompt
          : `${prompt}\n\nIMPORTANT: Output a COMPLETE JSON object in ONE LINE. Do not include any commentary. If you previously responded, ignore it and output the full JSON again.`;

      try {
        const response = await axios.post(
          url,
          {
            contents: [
              {
                role: 'user',
                parts: [
                  {
                    inlineData: {
                      mimeType: safeMimeType,
                      data: base64,
                    },
                  },
                  { text: strictPrompt },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.1,
              maxOutputTokens: 512,
              topP: 0.9,
              topK: 40,
              // Force JSON output when supported; reduces extra text/markdown.
              responseMimeType: 'application/json',
            },
          },
          {
            timeout: 45000,
            headers: { 'Content-Type': 'application/json' },
          }
        );

        const text = _getGeminiText(response.data);
        const extracted = _extractJsonObject(text);

        if (!extracted) {
          // Try retry/next-model instead of failing fast.
          const parseErr = new Error('Failed to parse AI response');
          parseErr.statusCode = 502;
          parseErr.details = { raw: String(text || '').slice(0, 500) };
          throw parseErr;
        }

        // Normalize: only keep expected keys.
        const result = {
          N: extracted.N ?? null,
          P: extracted.P ?? null,
          K: extracted.K ?? null,
          ph: extracted.ph ?? null,
          temperature: extracted.temperature ?? null,
          humidity: extracted.humidity ?? null,
          rainfall: extracted.rainfall ?? null,
          ...(extracted.error ? { error: extracted.error } : {}),
        };

        return result;
      } catch (error) {
      lastError = error;

      // If model is missing/unsupported, try next candidate.
      const msg = error?.response?.data?.error?.message || error?.message || '';
      const status = error?.response?.status;
      const isModelIssue =
        status === 404 ||
        msg.includes('is not found') ||
        msg.includes('not supported for generateContent');

      if (isModelIssue) continue;

      // Parsing issues should try again / try next model.
      if (error?.statusCode === 502 && String(error?.message || '').includes('Failed to parse')) {
        continue;
      }

      // Non-model errors should fail fast.
      if (error.response) {
        const message =
          error.response.data?.error?.message ||
          error.response.data?.error ||
          error.message ||
          'Gemini request failed';

        const err = new Error(message);
        err.statusCode = error.response.status;
        throw err;
      }

      throw error;
      }
    }
  }

  const fallbackMsg =
    lastError?.response?.data?.error?.message ||
    lastError?.message ||
    'No available Gemini model could be used for extraction';
  const err = new Error(fallbackMsg);
  err.statusCode = lastError?.response?.status || lastError?.statusCode || 502;
  throw err;
}
