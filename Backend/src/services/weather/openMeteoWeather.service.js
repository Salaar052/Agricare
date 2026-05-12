import axios from 'axios';

function asNum(v) {
  if (v === null || v === undefined) return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function sum(arr) {
  if (!Array.isArray(arr)) return null;
  let total = 0;
  let hasAny = false;
  for (const v of arr) {
    const n = asNum(v);
    if (n === null) continue;
    total += n;
    hasAny = true;
  }
  return hasAny ? total : null;
}

/**
 * Fetch current weather + short forecast summary from Open-Meteo.
 * No API key required.
 */
export async function fetchOpenMeteoWeather({ lat, lng }) {
  const latitude = asNum(lat);
  const longitude = asNum(lng);

  if (latitude === null || longitude === null) {
    const err = new Error('lat and lng must be valid numbers');
    err.statusCode = 400;
    throw err;
  }

  const url =
    'https://api.open-meteo.com/v1/forecast' +
    `?latitude=${encodeURIComponent(latitude)}` +
    `&longitude=${encodeURIComponent(longitude)}` +
    '&current_weather=true' +
    '&hourly=relativehumidity_2m,precipitation' +
    '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum' +
    '&temperature_unit=celsius&windspeed_unit=kmh' +
    '&timezone=auto' +
    '&forecast_days=7';

  const response = await axios.get(url, { timeout: 15000 });
  const data = response.data || {};

  const current = data.current_weather || {};
  const currentTempC = asNum(current.temperature);
  const currentWindKmh = asNum(current.windspeed);
  const currentWeatherCode = current.weathercode ?? null;
  const currentTime = typeof current.time === 'string' ? current.time : null;

  const hourlyHumidity = data.hourly?.relativehumidity_2m;
  const hourlyPrecip = data.hourly?.precipitation;
  const humidityNow = Array.isArray(hourlyHumidity) ? asNum(hourlyHumidity[0]) : null;
  const precipNext24hMm = Array.isArray(hourlyPrecip) ? sum(hourlyPrecip.slice(0, 24)) : null;

  const daily = data.daily || {};
  const dailyPrecipSum = Array.isArray(daily.precipitation_sum) ? daily.precipitation_sum : null;
  const precipNext3DaysMm = dailyPrecipSum ? sum(dailyPrecipSum.slice(0, 3)) : null;

  const dailyTmax = Array.isArray(daily.temperature_2m_max) ? daily.temperature_2m_max : null;
  const dailyTmin = Array.isArray(daily.temperature_2m_min) ? daily.temperature_2m_min : null;

  return {
    source: 'open-meteo',
    coordinates: { lat: latitude, lng: longitude },
    current: {
      time: currentTime,
      temperatureC: currentTempC,
      humidityPct: humidityNow,
      windSpeedKmh: currentWindKmh,
      weatherCode: currentWeatherCode,
    },
    forecastSummary: {
      precipNext24hMm,
      precipNext3DaysMm,
      dailyTemperatureMaxC: dailyTmax?.map(asNum) ?? null,
      dailyTemperatureMinC: dailyTmin?.map(asNum) ?? null,
      dailyPrecipitationSumMm: dailyPrecipSum?.map(asNum) ?? null,
    },
    fetchedAt: new Date().toISOString(),
  };
}

/**
 * Simple geocoding for manual location search (Open-Meteo Geocoding API)
 */
export async function searchLocationOpenMeteo({ query, count = 5 }) {
  const q = typeof query === 'string' ? query.trim() : '';
  if (!q) {
    const err = new Error('query is required');
    err.statusCode = 400;
    throw err;
  }

  const url =
    'https://geocoding-api.open-meteo.com/v1/search' +
    `?name=${encodeURIComponent(q)}` +
    `&count=${encodeURIComponent(count)}` +
    '&language=en&format=json';

  const response = await axios.get(url, { timeout: 15000 });
  const results = Array.isArray(response.data?.results) ? response.data.results : [];

  return results.map((r) => ({
    name: r?.name ?? null,
    admin1: r?.admin1 ?? null,
    country: r?.country ?? null,
    latitude: asNum(r?.latitude),
    longitude: asNum(r?.longitude),
  }));
}
