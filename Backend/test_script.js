import { extractLabReportValuesFromImage } from './src/services/cropRecommendation/labReportExtraction.service.js';
import sharp from 'sharp';

// Create a simple table-like layout with separated columns.
const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="700">
  <rect width="100%" height="100%" fill="white"/>
  <text x="30" y="70" font-size="50" font-family="Arial">SOIL ANALYSIS REPORT</text>

  <!-- header row -->
  <text x="40" y="170" font-size="34" font-family="Arial">Parameters</text>
  <text x="760" y="170" font-size="34" font-family="Arial">Results</text>

  <!-- rows: label on left, value far right (like a table) -->
  <text x="40" y="240" font-size="40" font-family="Arial">pH</text>
  <text x="800" y="240" font-size="40" font-family="Arial">7.45</text>

  <text x="40" y="310" font-size="40" font-family="Arial">Nitrogen (N)</text>
  <text x="800" y="310" font-size="40" font-family="Arial">0.068</text>

  <text x="40" y="380" font-size="40" font-family="Arial">Phosphorus (P2O5)</text>
  <text x="800" y="380" font-size="40" font-family="Arial">12.4</text>

  <text x="40" y="450" font-size="40" font-family="Arial">Potassium (K2O)</text>
  <text x="800" y="450" font-size="40" font-family="Arial">210</text>

  <text x="40" y="520" font-size="40" font-family="Arial">Rainfall (Monthly Avg.)</text>
  <text x="800" y="520" font-size="40" font-family="Arial">78.6</text>

  <text x="40" y="590" font-size="40" font-family="Arial">Temperature (Monthly Avg.)</text>
  <text x="800" y="590" font-size="40" font-family="Arial">28.4</text>
</svg>`;

async function run() {
  try {
    const buffer = await sharp(Buffer.from(svg)).png().toBuffer();
    const out = await extractLabReportValuesFromImage({ buffer, mimeType: 'image/png', filename: 'test.png' });
    console.log(JSON.stringify(out, null, 2));
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
