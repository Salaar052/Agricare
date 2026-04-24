// ============================================
// 2. FIXED MARKETPLACE CONTROLLERS (controllers/marketplace.controllers.js)
// ============================================
import { ApiError } from "../../utils/ApiError.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiResponse } from "../../utils/ApiResponse.js";
import User from "../../models/auth/user.js";
import { MarketplaceProfile } from "../../models/marketplace/marketplace.model.js";
import { Item } from "../../models/marketplace/item.model.js";
import mongoose from "mongoose";

// Helper: Get user by ID
const getUser = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new ApiError(404, "User not found");
  return user;
};

// 1️⃣ Check if user has marketplace account - FIXED
const checkMarketplaceAccount = asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Checking marketplace account for user:', req.user._id);
    
    const user = await getUser(req.user._id);
    console.log('👤 User found:', user.email);
    console.log('📊 User.haveMarketplaceAccount:', user.haveMarketplaceAccount);
    
    // Double check by querying MarketplaceProfile directly
    const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id });
    const actuallyHasAccount = !!marketplaceProfile;
    
    console.log('🏪 MarketplaceProfile exists:', actuallyHasAccount);
    
    // Sync the user field if it's out of sync
    if (user.haveMarketplaceAccount !== actuallyHasAccount) {
      console.log('🔄 Syncing haveMarketplaceAccount field...');
      user.haveMarketplaceAccount = actuallyHasAccount;
      await user.save();
    }
    
    console.log('✅ Final result - Has account:', actuallyHasAccount);
    
    return res.status(200).json(
      new ApiResponse(
        200,
        {
          haveMarketplaceAccount: actuallyHasAccount,
          userId: user._id,
        },
        "Marketplace account status retrieved successfully"
      )
    );
  } catch (error) {
    console.error('❌ Error in checkMarketplaceAccount:', error);
    throw error;
  }
});

// 2️⃣ Register marketplace account - FIXED
const registerMarketplaceAccount = asyncHandler(async (req, res) => {
  try {
    console.log('🚀 Starting marketplace registration...');
    console.log('📝 Request body:', req.body);
    console.log('👤 User ID:', req.user._id);
    
    const user = await getUser(req.user._id);
    console.log('✅ User found:', user.email);

    // Check if marketplace profile already exists
    const existingProfile = await MarketplaceProfile.findOne({ userId: user._id });
    if (existingProfile) {
      console.log('⚠️ Marketplace account already exists');
      throw new ApiError(400, "Marketplace account already exists");
    }

    const { shopName, shopDescription, sellerBio, shopImage, address, geoLocation } = req.body;

    // Validation
    if (!shopName?.trim()) {
      throw new ApiError(400, "Shop name is required");
    }

    if (!address?.trim()) {
      throw new ApiError(400, "Address is required");
    }

    console.log('📋 Creating marketplace profile...');

    const contactInfo = {
      name: user.username || "",
      phone: "", // Can be added later
      email: user.email || "",
    };

    const marketplaceProfile = await MarketplaceProfile.create({
      userId: user._id,
      shopName: shopName.trim(),
      shopDescription: shopDescription?.trim() || "",
      sellerBio: sellerBio?.trim() || "",
      shopImage: shopImage || user.profileImage || "",
      contactInfo,
      address: address.trim(),
      geoLocation: geoLocation || { type: "Point", coordinates: [0, 0] },
      isActive: true,
    });

    console.log('✅ Marketplace profile created:', marketplaceProfile._id);

    // ⚠️ CRITICAL: Update user's haveMarketplaceAccount field
    user.haveMarketplaceAccount = true;
    await user.save();
    
    console.log('✅ User updated with haveMarketplaceAccount = true');

    return res.status(201).json(
      new ApiResponse(
        201, 
        { marketplaceProfile }, 
        "Marketplace account registered successfully"
      )
    );
  } catch (error) {
    console.error('❌ Error in registerMarketplaceAccount:', error);
    throw error;
  }
});

const getAllItems = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, category, subcategory, search } = req.query;
  const filter = { status: "pending", isAvailable: true, isSold: false };

  if (category) filter.category = category;
  if (subcategory) filter.subcategory = subcategory;
  if (search) {
    filter.$or = [
      { title: { $regex: search, $options: "i" } },
      { description: { $regex: search, $options: "i" } },
    ];
  }

  const skip = (Number(page) - 1) * Number(limit);

  const items = await Item.find(filter)
    .populate("sellerId", "shopName shopImage contactInfo")
    .populate("userId", "username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(Number(limit));

  const totalItems = await Item.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(200, {
      items,
      pagination: {
        currentPage: Number(page),
        totalPages: Math.ceil(totalItems / Number(limit)),
        totalItems,
        itemsPerPage: Number(limit),
      },
    }, "Items retrieved successfully")
  );
});

// 4️⃣ Get product details
const getProductDetails = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  if (!productId || !mongoose.isValidObjectId(productId)) {
    throw new ApiError(400, "Valid product ID is required");
  }

  const item = await Item.findById(productId)
    .populate("sellerId", "shopName shopDescription shopImage contactInfo address geoLocation")
    .populate("userId", "username email profileImage");

  if (!item) throw new ApiError(404, "Product not found");

  if (item.status !== "pending" && item.userId._id.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "Product not available");
  }

  return res.status(200).json(
    new ApiResponse(200, { item }, "Product details retrieved successfully")
  );
});

// 5️⃣ Get my marketplace profile
const getMyProfile = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id })
    .populate("items", "title price images status createdAt isAvailable isSold")
    .populate("userId", "username email profileImage");

  if (!marketplaceProfile) {
    throw new ApiError(404, "Marketplace profile not found");
  }

  return res.status(200).json(
    new ApiResponse(200, { profile: marketplaceProfile }, "Profile retrieved successfully")
  );
});

// 6️⃣ Edit my marketplace profile
const editMyProfile = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id });
  
  if (!marketplaceProfile) {
    throw new ApiError(404, "Marketplace profile not found");
  }

  const { shopName, shopDescription, sellerBio, shopImage, address, geoLocation, isActive } = req.body;

  if (shopName) marketplaceProfile.shopName = shopName.trim();
  if (shopDescription !== undefined) marketplaceProfile.shopDescription = shopDescription.trim();
  if (sellerBio !== undefined) marketplaceProfile.sellerBio = sellerBio.trim();
  if (shopImage !== undefined) marketplaceProfile.shopImage = shopImage;
  if (address !== undefined) marketplaceProfile.address = address.trim();
  if (geoLocation !== undefined) marketplaceProfile.geoLocation = geoLocation;
  if (isActive !== undefined) marketplaceProfile.isActive = isActive;

  marketplaceProfile.contactInfo = {
    name: user.username,
    phone: marketplaceProfile.contactInfo.phone || "",
    email: user.email || "",
  };

  await marketplaceProfile.save();

  return res.status(200).json(
    new ApiResponse(200, { profile: marketplaceProfile }, "Profile updated successfully")
  );
});

// 7️⃣ Get saved items
const getSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id })
    .populate({ 
      path: "savedItems", 
      match: { status: "approved", isAvailable: true, isSold: false }, 
      populate: { path: "sellerId", select: "shopName shopImage contactInfo" } 
    });

  if (!marketplaceProfile) {
    throw new ApiError(404, "Marketplace profile not found");
  }

  return res.status(200).json(
    new ApiResponse(200, { savedItems: marketplaceProfile.savedItems }, "Saved items retrieved successfully")
  );
});

// Add to saved items
const addToSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.body;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id });
  if (!marketplaceProfile) {
    throw new ApiError(404, "Marketplace profile not found");
  }

  const item = await Item.findById(itemId);
  if (!item) throw new ApiError(404, "Item not found");
  if (item.status !== "approved") throw new ApiError(400, "Cannot save unapproved items");
  if (marketplaceProfile.savedItems.includes(itemId)) {
    throw new ApiError(400, "Item already saved");
  }

  marketplaceProfile.savedItems.push(itemId);
  await marketplaceProfile.save();

  return res.status(200).json(
    new ApiResponse(200, { savedItems: marketplaceProfile.savedItems }, "Item saved successfully")
  );
});

// Remove from saved items
const removeFromSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.params;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id });
  if (!marketplaceProfile) {
    throw new ApiError(404, "Marketplace profile not found");
  }

  marketplaceProfile.savedItems = marketplaceProfile.savedItems.filter(
    id => id.toString() !== itemId
  );
  await marketplaceProfile.save();

  return res.status(200).json(
    new ApiResponse(200, { savedItems: marketplaceProfile.savedItems }, "Item removed successfully")
  );
});

// 8️⃣ Get seller profile
const getSellerProfile = asyncHandler(async (req, res) => {
  const { sellerId } = req.params;
  if (!sellerId || !mongoose.isValidObjectId(sellerId)) {
    throw new ApiError(400, "Valid seller ID is required");
  }

  const sellerProfile = await MarketplaceProfile.findById(sellerId)
    .populate("userId", "username profileImage")
    .populate({ 
      path: "items", 
      match: { status: "approved", isAvailable: true, isSold: false }, 
      select: "title price images category subcategory createdAt" 
    });

  if (!sellerProfile) throw new ApiError(404, "Seller profile not found");
  if (!sellerProfile.isActive) throw new ApiError(403, "Seller profile is inactive");

  return res.status(200).json(
    new ApiResponse(200, { seller: sellerProfile }, "Seller profile retrieved successfully")
  );
});

// 9️⃣ Create new listing
const createNewListing = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const marketplaceProfile = await MarketplaceProfile.findOne({ userId: user._id });
  
  if (!marketplaceProfile) {
    throw new ApiError(403, "Marketplace account required to create listings");
  }

  const { title, category, subcategory, price, description, images, condition, location } = req.body;
  
  if (!title?.trim()) throw new ApiError(400, "Title is required");
  if (!category) throw new ApiError(400, "Category is required");
  if (!subcategory) throw new ApiError(400, "Subcategory is required");
  if (!price || price <= 0) throw new ApiError(400, "Valid price is required");

  const newItem = await Item.create({
    sellerId: marketplaceProfile._id,
    userId: user._id,
    title: title.trim(),
    category,
    subcategory,
    price: Number(price),
    description: description?.trim() || "",
    images: images || [],
    condition: condition || "new",
    location: location || marketplaceProfile.geoLocation,
    status: "pending",
    isAvailable: true,
    isSold: false,
  });

  marketplaceProfile.items.push(newItem._id);
  await marketplaceProfile.save();

  return res.status(201).json(
    new ApiResponse(201, { item: newItem }, "Listing created successfully. Awaiting admin approval")
  );
});

// 10️⃣ Get my listings
const getMyListings = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { status } = req.query;

  const filter = { userId: user._id };
  if (status) filter.status = status;

  const myItems = await Item.find(filter).sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, { items: myItems }, "Your listings retrieved successfully")
  );
});

// 11️⃣ Update my listing
const updateMyListing = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.params;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  const item = await Item.findOne({ _id: itemId, userId: user._id });
  if (!item) {
    throw new ApiError(404, "Item not found or you don't have permission");
  }

  const { title, category, subcategory, price, description, images, condition, location, isAvailable } = req.body;

  if (title !== undefined && title.trim()) item.title = title.trim();
  if (category !== undefined) item.category = category;
  if (subcategory !== undefined) item.subcategory = subcategory;
  if (price !== undefined && price > 0) item.price = Number(price);
  if (description !== undefined) item.description = description.trim();
  if (images !== undefined) item.images = images;
  if (condition !== undefined) item.condition = condition;
  if (location !== undefined) item.location = location;
  if (isAvailable !== undefined) item.isAvailable = isAvailable;

  if (item.status === "rejected") {
    item.status = "pending";
    item.rejectionReason = null;
  }

  await item.save();

  return res.status(200).json(
    new ApiResponse(200, { item }, "Listing updated successfully")
  );
});

// 12️⃣ Delete my listing
const deleteMyListing = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.params;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  const item = await Item.findOne({ _id: itemId, userId: user._id });
  if (!item) {
    throw new ApiError(404, "Item not found or you don't have permission");
  }

  await MarketplaceProfile.updateOne(
    { userId: user._id },
    { $pull: { items: itemId } }
  );

  await Item.findByIdAndDelete(itemId);

  return res.status(200).json(
    new ApiResponse(200, {}, "Listing deleted successfully")
  );
});

export {
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
  deleteMyListing
};