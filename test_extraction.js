import { extractLabReportValuesFromImage } from './src/services/cropRecommendation/labReportExtraction.service.js';
import sharp from 'sharp';

const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="520">
  <rect width="100%" height="100%" fill="white"/>
  <text x="30" y="80" font-size="48" font-family="Arial">SOIL ANALYSIS REPORT</text>
  <text x="30" y="160" font-size="42" font-family="Arial">pH 7.45</text>
  <text x="30" y="230" font-size="42" font-family="Arial">Nitrogen (N) 0.068 %</text>
  <text x="30" y="300" font-size="42" font-family="Arial">Phosphorus (P2O5) 12.4 mg/kg</text>
  <text x="30" y="370" font-size="42" font-family="Arial">Potassium (K2O) 210 mg/kg</text>
  <text x="30" y="440" font-size="42" font-family="Arial">Rainfall (Monthly Avg.) 78.6 mm</text>
  <text x="30" y="500" font-size="42" font-family="Arial">Temperature (Monthly Avg.) 28.4 C</text>
</svg>`;

async function run() {
  try {
    const buffer = await sharp(Buffer.from(svg)).png().toBuffer();
    const out = await extractLabReportValuesFromImage({ buffer, mimeType: 'image/png', filename: 'test.png' });
    console.log("RESULT_START");
    console.log(JSON.stringify(out, null, 2));
    console.log("RESULT_END");
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}
run();