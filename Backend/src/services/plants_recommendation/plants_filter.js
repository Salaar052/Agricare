// ============================================================
// plantEngine.js — Rule-Based Filtering & Scoring System (ESM)
// ============================================================

import fs from 'fs';

// Load plants dataset (stable method)
const plants = JSON.parse(
  fs.readFileSync(
    new URL('./plants.json', import.meta.url)
  )
);

/**
 * STEP 1: Filter plants based on hard constraints
 */
function filterPlants({ temperature, space, sunlight }) {
  return plants.filter((plant) => {
    const tempOk = temperature >= plant.temp_min && temperature <= plant.temp_max;
    const spaceOk = plant.space.includes(space);
    const sunOk = plant.sunlight === sunlight;

    return tempOk && spaceOk && sunOk;
  });
}

/**
 * STEP 2: Score plants
 */
function scorePlants(filteredPlants, { temperature, space, sunlight, water }) {
  return filteredPlants.map((plant) => {
    let score = 0;

    if (temperature >= plant.temp_min && temperature <= plant.temp_max) {
      score += 5;
    }

    if (plant.space.includes(space)) {
      score += 3;
    }

    if (plant.sunlight === sunlight) {
      score += 2;
    }

    if (plant.water === water) {
      score += 1;
    }

    return { ...plant, score };
  });
}

/**
 * STEP 3: Sort and pick top N
 */
function getTopPlants(scoredPlants, topN = 3) {
  return [...scoredPlants] // avoid mutating original array
    .sort((a, b) => b.score - a.score)
    .slice(0, topN);
}

/**
 * MAIN ENGINE
 */
export function recommendPlants(userInput) {
  const filtered = filterPlants(userInput);

  if (filtered.length === 0) {
    return {
      plants: [],
      message: 'No plants match your current conditions.',
    };
  }

  const scored = scorePlants(filtered, userInput);
  const top3 = getTopPlants(scored, 3);

  return { plants: top3 };
}