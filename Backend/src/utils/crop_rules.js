/**
 * Central crop rules configuration.
 * Extend this file to add new crops, thresholds, or recommendations.
 */

export const FERTILIZER_THRESHOLDS = {
  nitrogen: { threshold: 50, recommendation: 'Urea' },
  phosphorus: { threshold: 40, recommendation: 'DAP' },
  potassium: { threshold: 40, recommendation: 'MOP' },
};

export const PESTICIDE_CONDITIONS = [
  {
    id: 'fungal_disease',
    issue: 'Fungal Disease',
    solution: 'Carbendazim',
    check: ({ humidity }) => humidity > 80,
    description: 'High humidity (>80%) creates ideal conditions for fungal growth.',
  },
  {
    id: 'stem_borer',
    issue: 'Stem Borer',
    solution: 'Chlorantraniliprole',
    check: ({ temperature }) => temperature > 30,
    description: 'High temperature (>30°C) favors stem borer infestation.',
  },
];

export const HARVEST_BASE_DATES = {
  rice: { month: 4, day: 10 },      // April 10
  wheat: { month: 3, day: 20 },     // March 20
  maize: { month: 9, day: 15 },     // September 15
  cotton: { month: 10, day: 5 },    // October 5
  sugarcane: { month: 2, day: 1 },  // February 1
};

export const DEFAULT_HARVEST_BASE = { month: 4, day: 10 }; // Fallback

export const HARVEST_ADJUSTMENTS = {
  rainPenaltyDays: 3,       // Subtract if rain exists in forecast
  highTempPenaltyDays: 2,   // Subtract if temp > 35 for multiple days
  highTempThreshold: 35,
  highTempMinDays: 2,       // How many days must exceed threshold
  coldTempBonusDays: 2,     // Add if temp < 20
  coldTempThreshold: 20,
};

