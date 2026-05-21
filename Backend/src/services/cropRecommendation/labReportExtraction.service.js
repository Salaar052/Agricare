import axios from 'axios';

let _tesseractWorkerPromise;
let _ocrQueue = Promise.resolve();

async function _withOcrLock(fn) {
  // Tesseract workers are not reliably safe to share concurrently.
  // Serialize recognize calls to avoid cross-request interference.
  const prev = _ocrQueue;
  let release;
  _ocrQueue = new Promise((r) => {
    release = r;
  });
  await prev;
  try {
    return await fn();
  } finally {
    release();
  }
}

async function _getTesseractWorker() {
  if (_tesseractWorkerPromise) return _tesseractWorkerPromise;

  _tesseractWorkerPromise = (async () => {
    // Lazy import to avoid paying the cost unless extraction endpoint is used.
    const [{ createWorker }, { default: sharp }] = await Promise.all([
      import('tesseract.js'),
      import('sharp'),
    ]);

    // Keep a reference so callers can use it for preprocessing defaults.
    // tesseract.js v6: language is provided to createWorker; no loadLanguage/initialize methods.
    const worker = await createWorker('eng');
    await worker.setParameters({
      preserve_interword_spaces: '1',
      // PSM 6 = Assume a single uniform block of text.
      tessedit_pageseg_mode: '6',
    });

    return { worker, sharp };
  })();

  return _tesseractWorkerPromise;
}

function _safeNumberFromToken(token) {
  if (token === null || token === undefined) return null;
  let s = String(token).trim();
  if (!s) return null;

  // Common OCR confusions.
  s = s.replace(/[Oo]/g, '0');
  s = s.replace(/\s+/g, '');

  // Normalize decimal separators.
  // If it contains a comma but no dot, treat comma as decimal.
  if (s.includes(',') && !s.includes('.')) {
    s = s.replace(/,/g, '.');
  } else {
    // Otherwise remove thousands separators.
    s = s.replace(/,/g, '');
  }

  const num = Number.parseFloat(s);
  return Number.isFinite(num) ? num : null;
}

function _coerceIntoRange(value, { min, max }) {
  if (value === null || value === undefined) return null;
  if (!Number.isFinite(value)) return null;

  if (typeof min !== 'number' || typeof max !== 'number') return value;
  if (value >= min && value <= max) return value;

  // OCR often drops decimal points: 745 -> 7.45, 284 -> 28.4
  const div10 = value / 10;
  if (div10 >= min && div10 <= max) return div10;
  const div100 = value / 100;
  if (div100 >= min && div100 <= max) return div100;

  return null;
}

function _extractInlineNumberFromText(text, { min, max }) {
  const t = String(text || '');
  const m = t.match(/(-?\d+[\d.,]*\d|\d)/);
  const raw = _safeNumberFromToken(m?.[0]);
  return _coerceIntoRange(raw, { min, max });
}

function _parseWordsFromTsv(tsvText) {
  if (typeof tsvText !== 'string' || !tsvText.trim()) return [];

  const lines = tsvText.split(/\r?\n/g).filter(Boolean);
  if (!lines.length) return [];

  // Expected header includes: level page_num block_num par_num line_num word_num left top width height conf text
  const out = [];
  for (let i = 1; i < lines.length; i += 1) {
    const row = lines[i];
    const cols = row.split('\t');
    if (cols.length < 12) continue;
    const level = Number(cols[0]);
    if (level !== 5) continue; // word level

    const left = Number(cols[6]);
    const top = Number(cols[7]);
    const width = Number(cols[8]);
    const height = Number(cols[9]);
    const conf = Number(cols[10]);
    const text = cols.slice(11).join('\t');

    if (!text || !text.trim()) continue;
    if (![left, top, width, height].every((n) => Number.isFinite(n))) continue;

    out.push({
      text: text.trim(),
      confidence: Number.isFinite(conf) ? conf : null,
      bbox: {
        x0: left,
        y0: top,
        x1: left + width,
        y1: top + height,
      },
    });
  }

  return out;
}

function _normalizeLine(line) {
  return String(line || '')
    .replace(/[|]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function _normalizeWord(word) {
  return String(word || '')
    .toLowerCase()
    .replace(/[^a-z0-9().%]/g, '')
    .trim();
}

function _wordCenterY(w) {
  const b = w?.bbox;
  if (!b) return null;
  return (Number(b.y0) + Number(b.y1)) / 2;
}

function _wordRightX(w) {
  const b = w?.bbox;
  if (!b) return null;
  return Number(b.x1);
}

function _wordLeftX(w) {
  const b = w?.bbox;
  if (!b) return null;
  return Number(b.x0);
}

function _wordHeight(w) {
  const b = w?.bbox;
  if (!b) return null;
  return Math.max(0, Number(b.y1) - Number(b.y0));
}

function _median(nums) {
  const arr = nums.filter((n) => Number.isFinite(n)).sort((a, b) => a - b);
  if (!arr.length) return null;
  const mid = Math.floor(arr.length / 2);
  return arr.length % 2 ? arr[mid] : (arr[mid - 1] + arr[mid]) / 2;
}

function _clusterWordsIntoRows(words) {
  const ws = (Array.isArray(words) ? words : []).filter((w) => w?.bbox && w?.text);
  if (!ws.length) return [];

  const heights = ws.map(_wordHeight).filter((n) => Number.isFinite(n) && n > 0);
  const medH = _median(heights) || 20;
  const yTol = Math.max(10, medH * 0.65);

  // Sort by y, then x.
  const sorted = ws
    .map((w) => ({
      w,
      cy: _wordCenterY(w),
      cx: (_wordLeftX(w) ?? 0) + ((_wordRightX(w) ?? 0) - (_wordLeftX(w) ?? 0)) / 2,
    }))
    .filter((x) => Number.isFinite(x.cy))
    .sort((a, b) => (a.cy - b.cy) || (a.cx - b.cx));

  const rows = [];
  for (const item of sorted) {
    const last = rows[rows.length - 1];
    if (!last) {
      rows.push({ cy: item.cy, items: [item.w] });
      continue;
    }
    if (Math.abs(item.cy - last.cy) <= yTol) {
      last.items.push(item.w);
      // Update running average.
      last.cy = (last.cy * (last.items.length - 1) + item.cy) / last.items.length;
    } else {
      rows.push({ cy: item.cy, items: [item.w] });
    }
  }

  // Sort each row by x.
  for (const r of rows) {
    r.items.sort((a, b) => (_wordLeftX(a) ?? 0) - (_wordLeftX(b) ?? 0));
  }
  return rows;
}

function _rowText(rowWords) {
  return rowWords
    .map((w) => String(w?.text || '').trim())
    .filter(Boolean)
    .join(' ');
}

function _normalizeRowTextForMatch(t) {
  return String(t || '')
    .toLowerCase()
    .replace(/[^a-z0-9()%./\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function _quantize(n, step) {
  if (!Number.isFinite(n)) return null;
  const s = Number(step) || 1;
  return Math.round(n / s) * s;
}

function _deriveResultsColumnRange(rows, { startY }) {
  // Cluster x positions of numeric tokens in table rows to infer the Results column.
  // Works even when header OCR fails or column boundaries are mis-read.
  const xs = [];

  const tableHint = (t) => {
    const compact = String(t || '').replace(/\s+/g, '');
    return (
      compact.includes('ph') ||
      compact.includes('nitrogen') ||
      compact.includes('phosphor') ||
      compact.includes('potassium') ||
      compact.includes('rainfall') ||
      compact.includes('temperature') ||
      compact.includes('humidity') ||
      t.includes('mg/kg') ||
      t.includes('mgkg') ||
      t.includes('ds/m') ||
      t.includes('%') ||
      t.includes('mm')
    );
  };

  for (const r of rows) {
    if (!Number.isFinite(r?.cy) || r.cy < startY) continue;
    const text = _normalizeRowTextForMatch(_rowText(r.items));
    if (!text || !tableHint(text)) continue;

    for (const w of r.items) {
      const x0 = _wordLeftX(w);
      if (!Number.isFinite(x0)) continue;
      const norm = _normalizeWord(w?.text);
      if (!norm || !/[0-9]/.test(norm)) continue;

      const raw = _safeNumberFromToken(norm);
      const val = _coerceIntoRange(raw, { min: 0, max: 10000 });
      if (val === null) continue;

      // Exclude likely Sr.No tokens
      const isSmallInt = Number.isInteger(val) && val >= 1 && val <= 30;
      if (isSmallInt) continue;

      xs.push(x0);
    }
  }

  if (xs.length < 4) return null;

  // Histogram by binning x0. Most frequent bin ~ Results column.
  const step = 60;
  const bins = new Map();
  for (const x of xs) {
    const b = _quantize(x, step);
    bins.set(b, (bins.get(b) || 0) + 1);
  }
  let bestBin = null;
  let bestCount = -1;
  for (const [b, count] of bins.entries()) {
    if (count > bestCount) {
      bestCount = count;
      bestBin = b;
    }
  }
  if (bestBin === null) return null;

  // Refine using all points near the winning bin.
  const near = xs.filter((x) => Math.abs(x - bestBin) <= step * 1.5);
  const center = _median(near) ?? bestBin;
  const spread = _median(near.map((x) => Math.abs(x - center))) ?? step;

  const x0 = center - Math.max(90, spread * 3);
  const x1 = center + Math.max(220, spread * 5);
  return { x0, x1, center };
}

function _scoreCandidate({ val, x0, resultsCenter, confidence, typicalMin, typicalMax }) {
  let score = 0;

  if (Number.isFinite(resultsCenter) && Number.isFinite(x0)) {
    score -= Math.abs(x0 - resultsCenter) / 6;
  }

  const isSmallInt = Number.isInteger(val) && val >= 1 && val <= 30;
  if (isSmallInt) score -= 50;
  else score += 10;

  if (typeof typicalMin === 'number' && typeof typicalMax === 'number') {
    if (val >= typicalMin && val <= typicalMax) score += 20;
  }

  if (Number.isFinite(confidence)) score += Math.max(0, Math.min(25, confidence / 4));

  return score;
}

function _pickResultNumberFromRow(rowWords, {
  resultsX0,
  resultsX1,
  resultsCenter,
  min,
  max,
  typicalMin,
  typicalMax,
}) {
  const candidates = [];
  for (const w of rowWords) {
    const x0 = _wordLeftX(w);
    if (!Number.isFinite(x0)) continue;
    if (Number.isFinite(resultsX0) && x0 < resultsX0) continue;
    if (Number.isFinite(resultsX1) && x0 > resultsX1) continue;

    const norm = _normalizeWord(w?.text);
    if (!norm || !/[0-9]/.test(norm)) continue;
    const raw = _safeNumberFromToken(norm);
    const val = _coerceIntoRange(raw, { min, max });
    if (val === null) continue;
    const score = _scoreCandidate({
      val,
      x0,
      resultsCenter,
      confidence: w?.confidence,
      typicalMin,
      typicalMax,
    });
    candidates.push({ val, x0, w, score });
  }
  if (!candidates.length) return null;

  candidates.sort((a, b) => (b.score - a.score) || (a.x0 - b.x0));
  return { value: candidates[0].val, word: candidates[0].w };
}

function _pickResultNumberForKey(rowWords, pickOpts, key) {
  // Collect candidates using the same logic as _pickResultNumberFromRow,
  // but choose differently for P/K to prevent swapped values when OCR merges rows.
  const candidates = [];
  for (const w of rowWords) {
    const x0 = _wordLeftX(w);
    if (!Number.isFinite(x0)) continue;
    if (Number.isFinite(pickOpts.resultsX0) && x0 < pickOpts.resultsX0) continue;
    if (Number.isFinite(pickOpts.resultsX1) && x0 > pickOpts.resultsX1) continue;

    const norm = _normalizeWord(w?.text);
    if (!norm || !/[0-9]/.test(norm)) continue;
    const raw = _safeNumberFromToken(norm);
    const val = _coerceIntoRange(raw, { min: pickOpts.min, max: pickOpts.max });
    if (val === null) continue;
    const score = _scoreCandidate({
      val,
      x0,
      resultsCenter: pickOpts.resultsCenter,
      confidence: w?.confidence,
      typicalMin: pickOpts.typicalMin,
      typicalMax: pickOpts.typicalMax,
    });
    candidates.push({ val, x0, w, score });
  }

  if (!candidates.length) return null;

  if (key === 'K') {
    // Potassium is usually the largest numeric result in the row.
    const strong = candidates.filter((c) => c.val >= 20);
    const pool = strong.length ? strong : candidates;
    pool.sort((a, b) => (b.val - a.val) || (b.score - a.score));
    return { value: pool[0].val, word: pool[0].w };
  }

  if (key === 'P') {
    // Phosphorus is usually smaller than Potassium; pick smallest plausible value.
    const plausible = candidates.filter((c) => c.val <= 500);
    const pool = plausible.length ? plausible : candidates;
    pool.sort((a, b) => (a.val - b.val) || (b.score - a.score));
    return { value: pool[0].val, word: pool[0].w };
  }

  candidates.sort((a, b) => (b.score - a.score) || (a.x0 - b.x0));
  return { value: candidates[0].val, word: candidates[0].w };
}

function _extractSoilInputsFromTableWords(words) {
  const out = {
    N: null,
    P: null,
    K: null,
    ph: null,
    temperature: null,
    humidity: null,
    rainfall: null,
  };
  const evidence = {};

  const rows = _clusterWordsIntoRows(words);
  if (!rows.length) return { values: out, evidence };

  // Find the table header row (fuzzy: needs at least 2 header keywords).
  let header = null;
  for (const r of rows) {
    const text = _normalizeRowTextForMatch(_rowText(r.items));
    const hits = ['parameters', 'results', 'units', 'method', 'interpretation']
      .reduce((acc, k) => acc + (text.includes(k) ? 1 : 0), 0);
    if (hits >= 2 && text.includes('results')) {
      header = r;
      break;
    }
  }

  const headerWords = header?.items || [];

  // Derive column boundaries using header word positions.
  const findHeaderWord = (needle) =>
    headerWords.find((w) => {
      const t = _normalizeWord(w?.text);
      return t === needle || t.startsWith(needle);
    });

  const wResults = header ? findHeaderWord('results') : null;
  const wUnits = header ? findHeaderWord('units') : null;
  const wMethod = header ? findHeaderWord('method') : null;

  const resultsX0 = wResults ? (_wordLeftX(wResults) ?? null) - 10 : null;
  const resultsX1 = wUnits
    ? (_wordLeftX(wUnits) ?? null) - 10
    : wMethod
      ? (_wordLeftX(wMethod) ?? null) - 10
      : null;

  const headerH = header
    ? _median(headerWords.map(_wordHeight).filter((n) => Number.isFinite(n) && n > 0)) || 20
    : 20;

  // If header isn't detected, start from the first row that looks like a soil-parameter row.
  const startY = (() => {
    if (header) return header.cy + headerH * 0.9;
    const keys = ['ph', 'nitrogen', 'phosphor', 'potassium', 'rainfall', 'temperature', 'humidity'];
    for (const r of rows) {
      const text = _normalizeRowTextForMatch(_rowText(r.items));
      const compact = text.replace(/\s+/g, '');
      if (keys.some((k) => compact.includes(k))) return r.cy - headerH * 0.5;
    }
    return Number.POSITIVE_INFINITY;
  })();

  // Auto-detect Results column range from numeric token clustering.
  const autoResults = _deriveResultsColumnRange(rows, { startY });
  const effectiveResultsX0 = (() => {
    if (Number.isFinite(resultsX0) && autoResults?.x0) {
      // If header-based boundary is far left of detected numeric column, trust auto.
      if (resultsX0 < autoResults.x0 - 250) return autoResults.x0;
      return resultsX0;
    }
    return Number.isFinite(resultsX0) ? resultsX0 : autoResults?.x0 ?? null;
  })();
  const effectiveResultsX1 = (() => {
    if (Number.isFinite(resultsX1)) return resultsX1;
    return autoResults?.x1 ?? null;
  })();
  const effectiveResultsCenter = autoResults?.center ?? (Number.isFinite(effectiveResultsX0) && Number.isFinite(effectiveResultsX1)
    ? (effectiveResultsX0 + effectiveResultsX1) / 2
    : null);

  const constraints = {
    ph: { min: 0, max: 14 },
    N: { min: 0, max: 1000 },
    // Keep broad bounds, but use typical ranges in scoring to avoid wrong picks.
    P: { min: 0, max: 10000 },
    K: { min: 0, max: 10000 },
    rainfall: { min: 0, max: 5000 },
    temperature: { min: -10, max: 80 },
    humidity: { min: 0, max: 100 },
  };

  const typical = {
    ph: { typicalMin: 3, typicalMax: 11 },
    N: { typicalMin: 0, typicalMax: 10 },
    P: { typicalMin: 0, typicalMax: 250 },
    K: { typicalMin: 20, typicalMax: 2000 },
    rainfall: { typicalMin: 0, typicalMax: 1000 },
    temperature: { typicalMin: 0, typicalMax: 60 },
    humidity: { typicalMin: 0, typicalMax: 100 },
  };

  const matchers = {
    ph: (t) => /\bph\b/.test(t) || /\bp\s*h\b/.test(t),
    N: (t) => t.includes('nitrogen') || /\(\s*n\s*\)/.test(t),
    P: (t) => t.includes('phosphor') || t.includes('p2o5') || t.includes('p205'),
    K: (t) => t.includes('potassium') || t.includes('k2o') || t.includes('k20'),
    rainfall: (t) => t.includes('rainfall'),
    temperature: (t) => {
      const compact = t.replace(/\s+/g, '');
      return (
        t.includes('temperature') ||
        compact.includes('temperature') ||
        compact.includes('temparature') ||
        compact.includes('temprature') ||
        /\btemp\w*\b/.test(t)
      );
    },
    humidity: (t) => t.includes('humidity'),
  };

  for (const r of rows) {
    if (r.cy < startY) continue;
    const text = _normalizeRowTextForMatch(_rowText(r.items));
    if (!text) continue;

    for (const key of Object.keys(out)) {
      if (out[key] !== null && out[key] !== undefined) continue;
      const isMatch = matchers[key];
      if (!isMatch || !isMatch(text)) continue;

      const c = constraints[key] || {};
      const tPrefs = typical[key] || {};
      const pickOpts = {
        resultsX0: effectiveResultsX0,
        resultsX1: effectiveResultsX1,
        resultsCenter: effectiveResultsCenter,
        ...c,
        ...tPrefs,
      };
      const picked = _pickResultNumberForKey(r.items, pickOpts, key);
      if (picked) {
        out[key] = picked.value;
        evidence[key] = `${text} -> ${picked.word?.text || ''}`.trim();
        continue;
      }

      // Fallback: nearest number to the right of the first matching anchor word, still within the row.
      const anchor = r.items.find((w) => {
        const nt = _normalizeWord(w?.text);
        if (!nt) return false;
        if (key === 'ph') return nt === 'ph' || nt === 'p.h' || /^ph\d/.test(nt);
        if (key === 'N') return nt.includes('nitrogen') || nt === '(n)' || nt === 'n';
        if (key === 'P') return nt.includes('phosphor') || nt.includes('p2o5') || nt.includes('p205');
        if (key === 'K') return nt.includes('potassium') || nt.includes('k2o') || nt.includes('k20');
        if (key === 'rainfall') return nt.includes('rainfall');
        if (key === 'temperature') return nt.includes('temperature') || nt === 'temp';
        if (key === 'humidity') return nt.includes('humidity');
        return false;
      });
      if (anchor) {
        const r2 = _findNearestNumberToRight(r.items, anchor, c);
        if (r2) {
          out[key] = r2.value;
          evidence[key] = `${text} -> ${r2.word?.text || ''}`.trim();
        }
      }
    }
  }

  return { values: out, evidence };
}

function _findNearestNumberToRight(words, anchorWord, { min, max }) {
  const ay = _wordCenterY(anchorWord);
  const ax = _wordRightX(anchorWord);
  const ah = _wordHeight(anchorWord) || 0;
  if (ay === null || ax === null) return null;

  const yTol = Math.max(14, ah * 0.8);
  const minX = ax + Math.max(10, ah * 0.5);

  let best = null;

  for (const w of words) {
    const text = _normalizeWord(w?.text);
    if (!text) continue;
    if (!/[0-9]/.test(text)) continue;

    const wx0 = _wordLeftX(w);
    const wy = _wordCenterY(w);
    if (wx0 === null || wy === null) continue;

    if (wx0 < minX) continue;
    if (Math.abs(wy - ay) > yTol) continue;

    const raw = _safeNumberFromToken(text);
    const val = _coerceIntoRange(raw, { min, max });
    if (val === null) continue;

    const dx = wx0 - minX;
    if (!best || dx < best.dx) {
      best = { value: val, dx, word: w };
    }
  }

  return best;
}

function _extractSoilInputsFromOcrWords(words) {
  const out = {
    N: null,
    P: null,
    K: null,
    ph: null,
    temperature: null,
    humidity: null,
    rainfall: null,
  };

  const evidence = {};

  if (!Array.isArray(words) || words.length === 0) {
    return { values: out, evidence };
  }

  // Normalize list once.
  const ws = words
    .map((w) => ({
      ...w,
      _t: _normalizeWord(w?.text),
    }))
    .filter((w) => w._t);

  const anchors = {
    // Allow OCR concatenation like "ph745" but avoid matching "phosphorus".
    ph: (w) => w._t === 'ph' || w._t === 'p.h' || /^ph\d/.test(w._t),
    N: (w) => w._t.startsWith('nitrogen') || w._t === '(n)' || w._t === 'n',
    P: (w) => w._t.startsWith('phosphor') || w._t.includes('p2o5') || w._t === '(p)' || w._t === 'p',
    K: (w) => w._t.startsWith('potassium') || w._t.includes('k2o') || w._t === '(k)' || w._t === 'k',
    rainfall: (w) => w._t.startsWith('rainfall'),
    temperature: (w) => w._t.startsWith('temperature') || w._t === 'temp',
    humidity: (w) => w._t.startsWith('humidity'),
  };

  const constraints = {
    ph: { min: 0, max: 14 },
    N: { min: 0, max: 1000 },
    P: { min: 0, max: 10000 },
    K: { min: 0, max: 10000 },
    rainfall: { min: 0, max: 5000 },
    temperature: { min: -10, max: 80 },
    humidity: { min: 0, max: 100 },
  };

  // For each key: find the best anchor (prefer the one with a valid number to the right)
  for (const key of Object.keys(out)) {
    const isAnchor = anchors[key];
    if (!isAnchor) continue;
    const c = constraints[key] || {};

    const anchorCandidates = ws.filter(isAnchor);
    let best = null;

    for (const a of anchorCandidates) {
      // If OCR merged label+value into one word (e.g. "ph745"), parse inline first.
      const inline = _extractInlineNumberFromText(a.text, c);
      if (inline !== null && inline !== undefined) {
        const rInline = { value: inline, dx: 0, word: a, anchor: a };
        if (!best || rInline.dx < best.dx) {
          best = rInline;
        }
        continue;
      }

      const r = _findNearestNumberToRight(ws, a, c);
      if (!r) continue;
      if (!best || r.dx < best.dx) {
        best = { ...r, anchor: a };
      }
    }

    if (best?.value !== null && best?.value !== undefined) {
      out[key] = best.value;
      evidence[key] = `${best.anchor?.text || ''} -> ${best.word?.text || ''}`.trim();
    }
  }

  // Special case: pH might be split into separate 'p' and 'h' words.
  // If we didn't find pH yet, try anchoring on a word that looks like 'pH' in OCR noise.
  if (out.ph === null) {
    const phLike = ws.find((w) => w._t.replace(/\./g, '') === 'ph');
    if (phLike) {
      const inline = _extractInlineNumberFromText(phLike.text, constraints.ph);
      if (inline !== null && inline !== undefined) {
        out.ph = inline;
        evidence.ph = `${phLike.text || ''} -> ${inline}`.trim();
        return { values: out, evidence };
      }

      const r = _findNearestNumberToRight(ws, phLike, constraints.ph);
      if (r) {
        out.ph = r.value;
        evidence.ph = `${phLike.text || ''} -> ${r.word?.text || ''}`.trim();
      }
    }
  }

  return { values: out, evidence };
}

function _extractValueFromLines(lines, { key, labelRegexes, min, max }) {
  const normalized = lines.map(_normalizeLine).filter(Boolean);
  for (const rawLine of normalized) {
    const line = rawLine;
    const matched = labelRegexes.some((r) => r.test(line));
    if (!matched) continue;

    // Extract the first number AFTER the label if possible.
    // We do this by finding the earliest label match index.
    let bestIndex = null;
    let bestLen = 0;
    for (const r of labelRegexes) {
      const m = line.match(r);
      if (m && typeof m.index === 'number') {
        const idx = m.index;
        if (bestIndex === null || idx < bestIndex) {
          bestIndex = idx;
          bestLen = m[0].length;
        }
      }
    }

    const after = bestIndex === null ? line : line.slice(bestIndex + bestLen);

    // Prefer a decimal-looking number; otherwise take the first numeric token.
    const tokenMatch = after.match(/(-?\d+[\d.,]*\d|\d)/);
    const raw = _safeNumberFromToken(tokenMatch?.[0]);
    const value = _coerceIntoRange(raw, { min, max });
    if (value === null) continue;

    return { key, value, line };
  }

  return { key, value: null, line: null };
}

function _isLikelySoilReport(lines) {
  const text = lines.join('\n').toLowerCase();
  const hits = [
    /soil\s+analysis/, /soil\s+test/, /ph\b/, /nitrogen\b/, /phosphor/, /potassium/, /ec\b/, /organic\s+matter/,
  ].reduce((acc, r) => acc + (r.test(text) ? 1 : 0), 0);
  return hits >= 2;
}

function _extractSoilInputsFromOcrLines(lines) {
  const out = {
    N: null,
    P: null,
    K: null,
    ph: null,
    temperature: null,
    humidity: null,
    rainfall: null,
  };

  const specs = [
    {
      key: 'ph',
      // Allow concatenation like "pH7.45" or "pH745".
      labelRegexes: [/\bp\s*h(?!\s*osph)/i],
      min: 0,
      max: 14,
    },
    {
      key: 'N',
      labelRegexes: [/nitrogen/i, /\(\s*n\s*\)/i, /\bn\s*\(/i],
      min: 0,
      max: 1000,
    },
    {
      key: 'P',
      labelRegexes: [/phosphor/i, /p\s*\(?\s*2\s*o\s*5\s*\)?/i],
      min: 0,
      max: 10000,
    },
    {
      key: 'K',
      labelRegexes: [/potassium/i, /k\s*\(?\s*2\s*o\s*\)?/i],
      min: 0,
      max: 10000,
    },
    {
      key: 'temperature',
      labelRegexes: [/temperature/i, /\btemp\b/i],
      min: -10,
      max: 80,
    },
    {
      key: 'humidity',
      labelRegexes: [/humidity/i, /relative\s*humidity/i],
      min: 0,
      max: 100,
    },
    {
      key: 'rainfall',
      labelRegexes: [/rainfall/i, /precip(?:itation)?/i],
      min: 0,
      max: 5000,
    },
  ];

  const evidence = {};
  for (const spec of specs) {
    const r = _extractValueFromLines(lines, spec);
    out[spec.key] = r.value;
    if (r.line) evidence[spec.key] = r.line;
  }

  return { values: out, evidence };
}

async function _preprocessForOcr({ buffer }) {
  const { sharp } = await _getTesseractWorker();

  // Try a couple of preprocess pipelines and pick the one that yields more hits.
  const pipelines = [
    // Balanced: rotate, upscale, grayscale, normalize, sharpen.
    async () =>
      sharp(buffer)
        .rotate()
        .resize({ width: 2800 })
        .grayscale()
        .normalize()
        .sharpen()
        .png()
        .toBuffer(),
    // High-contrast threshold: often helps with scanned PDFs / low-contrast photos.
    async () =>
      sharp(buffer)
        .rotate()
        .resize({ width: 3000 })
        .grayscale()
        .normalize()
        .threshold(170)
        .sharpen()
        .png()
        .toBuffer(),
    // Trim outer border (common for screenshots) then enhance.
    async () =>
      sharp(buffer)
        .rotate()
        .trim(12)
        .resize({ width: 2800 })
        .grayscale()
        .normalize()
        .sharpen()
        .png()
        .toBuffer(),
  ];

  const results = [];
  for (const fn of pipelines) {
    try {
      // eslint-disable-next-line no-await-in-loop
      const b = await fn();
      results.push(b);
    } catch {
      // ignore preprocessing errors and fall back to original
    }
  }
  return results.length ? results : [buffer];
}

async function _runOcrAndExtract({ buffer }) {
  const { worker } = await _getTesseractWorker();
  const candidates = await _preprocessForOcr({ buffer });

  let best = null;

  for (const img of candidates) {
    const psmAttempts = ['6', '4', '11'];

    for (const psm of psmAttempts) {
      // eslint-disable-next-line no-await-in-loop
      const { data } = await _withOcrLock(async () => {
        await worker.setParameters({ tessedit_pageseg_mode: psm });
        return worker.recognize(img, {}, { tsv: true });
      });

      const words = Array.isArray(data?.words) && data.words.length ? data.words : _parseWordsFromTsv(data?.tsv);
      const lineCandidates = Array.isArray(data?.lines) ? data.lines.map((l) => l?.text).filter(Boolean) : [];
      const lines = lineCandidates.length
        ? lineCandidates
        : String(data?.text || '')
            .split(/\r?\n/g)
            .map((l) => l.trim())
            .filter(Boolean);

      const fromTable = _extractSoilInputsFromTableWords(words);
      const fromWords = _extractSoilInputsFromOcrWords(words);
      const fromLines = _extractSoilInputsFromOcrLines(lines);

      // Merge: table-first, then word anchors, then text lines.
      const values = {
        N: fromTable.values.N ?? fromWords.values.N ?? fromLines.values.N,
        P: fromTable.values.P ?? fromWords.values.P ?? fromLines.values.P,
        K: fromTable.values.K ?? fromWords.values.K ?? fromLines.values.K,
        ph: fromTable.values.ph ?? fromWords.values.ph ?? fromLines.values.ph,
        temperature: fromTable.values.temperature ?? fromWords.values.temperature ?? fromLines.values.temperature,
        humidity: fromTable.values.humidity ?? fromWords.values.humidity ?? fromLines.values.humidity,
        rainfall: fromTable.values.rainfall ?? fromWords.values.rainfall ?? fromLines.values.rainfall,
      };

      const evidence = {
        ...fromLines.evidence,
        ...fromWords.evidence,
        ...fromTable.evidence,
      };

      const foundCount = Object.values(values).filter((v) => v !== null && v !== undefined).length;
      if (!best || foundCount > best.foundCount) {
        best = { values, evidence, lines, foundCount };
      }

      // Stop early if we already got most fields.
      if (foundCount >= 6) break;
    }
  }

  // Reset PSM back to default for subsequent calls.
  await _withOcrLock(() => worker.setParameters({ tessedit_pageseg_mode: '6' }));

  return best || { values: null, evidence: {}, lines: [], foundCount: 0 };
}

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
  const hasGeminiKey = Boolean(process.env.GEMINI_API_KEY);
  const useGeminiFallback =
    hasGeminiKey && String(process.env.LAB_REPORT_USE_GEMINI_FALLBACK || '').toLowerCase() === 'true';

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

  // 1) OCR-first: deterministic extraction to avoid picking unrelated report metadata.
  let ocr = null;
  try {
    ocr = await _runOcrAndExtract({ buffer });
  } catch (e) {
    // If OCR fails, we can still try Gemini (if configured).
    ocr = null;
  }

  const ocrValues = ocr?.values || {
    N: null,
    P: null,
    K: null,
    ph: null,
    temperature: null,
    humidity: null,
    rainfall: null,
  };

  const includeOcrDebug = String(process.env.LAB_REPORT_OCR_DEBUG || '').toLowerCase() === 'true';
  const ocrDebug = includeOcrDebug
    ? {
        foundCount: ocr?.foundCount || 0,
        evidence: ocr?.evidence || {},
        lines: Array.isArray(ocr?.lines) ? ocr.lines.slice(0, 60) : [],
      }
    : null;

  // If OCR suggests it's not even a soil report (and we found nothing), return the existing sentinel.
  if ((ocr?.foundCount || 0) === 0 && ocr?.lines?.length && !_isLikelySoilReport(ocr.lines)) {
    return { error: 'not_a_soil_report' };
  }

  // If Gemini isn't configured, OCR is our only extraction source.
  if (!useGeminiFallback) return includeOcrDebug ? { ...ocrValues, _ocrDebug: ocrDebug } : ocrValues;

  // If OCR already found everything, don't call Gemini.
  const allPresent = Object.values(ocrValues).every((v) => v !== null && v !== undefined);
  if (allPresent) return ocrValues;

  // 2) Gemini fallback (optional): used ONLY to fill missing values.
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

  const prompt = `You are a soil lab-report extractor.

Task: read the image and extract ONLY these 7 numeric values as they appear in the RESULTS row/column for the matching parameter:
- N  (Nitrogen)
- P  (Phosphorus / P2O5)
- K  (Potassium / K2O)
- ph (Soil pH)
- temperature (°C)
- humidity (%)
- rainfall (mm)

Rules:
- Ignore ALL unrelated metadata: client name, addresses, phone numbers, report numbers, dates, depth, crop name, lab details, signatures.
- Do NOT guess. If a value is not present, return null.
- Prefer the numeric value closest to the parameter name in the table.
- Return ONLY JSON, no markdown.

Output JSON schema:
{"N":number|null,"P":number|null,"K":number|null,"ph":number|null,"temperature":number|null,"humidity":number|null,"rainfall":number|null}

If the image is not a soil test/lab report, return {"error":"not_a_soil_report"}.`;

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
        const geminiValues = {
          N: extracted.N ?? null,
          P: extracted.P ?? null,
          K: extracted.K ?? null,
          ph: extracted.ph ?? null,
          temperature: extracted.temperature ?? null,
          humidity: extracted.humidity ?? null,
          rainfall: extracted.rainfall ?? null,
          ...(extracted.error ? { error: extracted.error } : {}),
        };

        // Prefer OCR for any field it found; use Gemini only for missing.
        const merged = {
          N: ocrValues.N ?? geminiValues.N ?? null,
          P: ocrValues.P ?? geminiValues.P ?? null,
          K: ocrValues.K ?? geminiValues.K ?? null,
          ph: ocrValues.ph ?? geminiValues.ph ?? null,
          temperature: ocrValues.temperature ?? geminiValues.temperature ?? null,
          humidity: ocrValues.humidity ?? geminiValues.humidity ?? null,
          rainfall: ocrValues.rainfall ?? geminiValues.rainfall ?? null,
          ...(geminiValues.error ? { error: geminiValues.error } : {}),
        };

        return merged;
      } catch (error) {
      lastError = error;

      // If Gemini quota is exceeded, don't fail the request.
      // Return OCR values (possibly partial) so the UI can proceed.
      const status = error?.response?.status;
      const msg =
        error?.response?.data?.error?.message ||
        error?.response?.data?.error ||
        error?.message ||
        '';
      if (status === 429 || String(msg).toLowerCase().includes('quota exceeded')) {
        return ocrValues;
      }

      // If model is missing/unsupported, try next candidate.
      const msg2 = error?.response?.data?.error?.message || error?.message || '';
      const status2 = error?.response?.status;
      const isModelIssue =
        status2 === 404 ||
        msg2.includes('is not found') ||
        msg2.includes('not supported for generateContent');

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
