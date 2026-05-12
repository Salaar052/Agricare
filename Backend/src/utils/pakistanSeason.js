// Pakistan cropping season helper (coarse but practical)
// Pakistan broadly uses Rabi (winter) and Kharif (summer/monsoon).

export function getPakistanSeason(date = new Date()) {
  const d = date instanceof Date ? date : new Date(date);
  const month = d.getMonth() + 1; // 1-12

  // Rabi: Oct-Mar
  if (month >= 10 || month <= 3) {
    return {
      id: 'rabi',
      name: 'Rabi',
      window: 'Oct–Mar',
      notes: 'Cooler season; major crops include wheat and pulses.',
    };
  }

  // Kharif: Apr-Sep
  return {
    id: 'kharif',
    name: 'Kharif',
    window: 'Apr–Sep',
    notes: 'Warmer/monsoon season; major crops include rice, maize, cotton.',
  };
}

export function getPakistanSeasonCandidateCrops(seasonId) {
  const kharif = [
    'Rice',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Sorghum (Jowar)',
    'Millet (Bajra)',
    'Sesame (Til)',
    'Mung bean (Moong)',
    'Fodder (Sorghum/Fodder maize)',
  ];

  const rabi = [
    'Wheat',
    'Barley',
    'Chickpea/Gram (Chana)',
    'Mustard/Canola',
    'Lentil (Masoor)',
    'Pea',
    'Potato',
    'Onion',
    'Sunflower',
  ];

  return seasonId === 'rabi' ? rabi : kharif;
}
