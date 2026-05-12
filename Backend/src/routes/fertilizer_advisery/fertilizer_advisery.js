import { Router } from "express";

import { getAdvisoryController } from "../../controllers/fertilizer_advisery/fertilizer_advisery.js";

const router = Router();
// POST /api/advisory
router.post('/', getAdvisoryController);

export default router;