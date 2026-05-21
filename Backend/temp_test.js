import sharp from 'sharp';
import { extractLabReportValuesFromImage } from './src/services/cropRecommendation/labReportExtraction.service.js';
process.env.LAB_REPORT_OCR_DEBUG = 'true';
const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='900' height='280'>
  <rect x='0' y='0' width='900' height='280' fill='white'/>
  <text x='20' y='50' font-size='28' font-family='Arial'>Parameters</text>
  <text x='330' y='50' font-size='28' font-family='Arial'>Results</text>
  <text x='560' y='50' font-size='28' font-family='Arial'>Units</text>

  <text x='20' y='120' font-size='26' font-family='Arial'>Phosphorus Potassium</text>
  <text x='330' y='120' font-size='26' font-family='Arial'>12</text>
  <text x='400' y='120' font-size='26' font-family='Arial'>210</text>
  <text x='560' y='120' font-size='26' font-family='Arial'>kg/ha</text>

  <text x='20' y='185' font-size='26' font-family='Arial'>pH</text>
  <text x='330' y='185' font-size='26' font-family='Arial'>6.8</text>
  <text x='560' y='185' font-size='26' font-family='Arial'>-</text>
</svg>`;
const buffer = await sharp(Buffer.from(svg)).png().toBuffer();
const out = await extractLabReportValuesFromImage({ buffer, mimeType: 'image/png', filename: 'synthetic.png' });
console.log(JSON.stringify(out, null, 2));
