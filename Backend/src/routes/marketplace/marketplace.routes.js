import { Router } from "express";
import {
  checkMarketplaceAccount,
  registerMarketplaceAccount,
  getAllItems,
  getProductDetails,
  getMyProfile,
  editMyProfile,
  getSavedItems,
  addToSavedItems,
  removeFromSavedItems,
  getSellerProfile,
  createNewListing,
  getMyListings,
  updateMyListing,
  deleteMyListing,
} from "../../controllers/marketplace/marketplace.controllers.js";
import { verifyJwt } from "../../middlewares/authentication.js";

const marketplaceRouter = Router();

// ✅ All routes require JWT authentication
marketplaceRouter.use(verifyJwt);

// Check if user has marketplace account
marketplaceRouter.get("/check-account", checkMarketplaceAccount);

// Register marketplace account
marketplaceRouter.post("/register", registerMarketplaceAccount);

// Get all items (requires login to interact)
marketplaceRouter.get("/items", getAllItems);

// Get product details
marketplaceRouter.get("/items/:productId", getProductDetails);

// My profile routes
marketplaceRouter.get("/my-profile", getMyProfile);
marketplaceRouter.put("/my-profile", editMyProfile);

// Saved items routes
marketplaceRouter.get("/saved-items", getSavedItems);
marketplaceRouter.post("/saved-items", addToSavedItems);
marketplaceRouter.delete("/saved-items/:itemId", removeFromSavedItems);

// Seller profile (public view - but requires login)
marketplaceRouter.get("/seller/:sellerId", getSellerProfile);

// My listings routes
marketplaceRouter.get("/my-listings", getMyListings);
marketplaceRouter.post("/listings", createNewListing);
marketplaceRouter.put("/my-listings/:itemId", updateMyListing);
marketplaceRouter.delete("/my-listings/:itemId", deleteMyListing);

export default marketplaceRouter;