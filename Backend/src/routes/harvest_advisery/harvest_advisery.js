import { Router } from "express";
import { getHarvestController } from "../../controllers/harvest_advisery/harvest_advisery.js";

const router = Router();

// POST /api/harvest
router.post('/', getHarvestController);

export default router;  