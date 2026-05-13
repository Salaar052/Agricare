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
import { normalizeWhatsAppNumber, isValidWhatsAppNumberDigits } from "../../utils/phone.js";

const clampInt = (value, { min, max, fallback }) => {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(n)));
};

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const parseWhatsAppNumberOrThrow = (raw, { required = false } = {}) => {
  const digits = normalizeWhatsAppNumber(raw);
  if (!digits) {
    if (required) {
      throw new ApiError(
        400,
        "WhatsApp number is required (international format, e.g. +923001234567)."
      );
    }
    return "";
  }
  if (!isValidWhatsAppNumberDigits(digits)) {
    throw new ApiError(
      400,
      "Invalid WhatsApp number. Use international format like +923001234567 (country code + number)."
    );
  }
  return digits;
};

// In-memory cache for account status (per process)
// Note: still requires verifyJwt DB lookup, but avoids MarketplaceProfile query churn.
const ACCOUNT_STATUS_TTL_MS = 5 * 60 * 1000;
const accountStatusCache = new Map(); // userId -> { value: boolean, expiresAt: number }

const getCachedAccountStatus = (userId) => {
  const key = String(userId);
  const entry = accountStatusCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    accountStatusCache.delete(key);
    return null;
  }
  return entry.value;
};

const setCachedAccountStatus = (userId, value) => {
  const key = String(userId);
  accountStatusCache.set(key, { value: !!value, expiresAt: Date.now() + ACCOUNT_STATUS_TTL_MS });
};

const invalidateCachedAccountStatus = (userId) => {
  const key = String(userId);
  accountStatusCache.delete(key);
};

// Helper: Get user by ID
const getUser = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new ApiError(404, "User not found");
  return user;
};

// 1️⃣ Check if user has marketplace account - FIXED
const checkMarketplaceAccount = asyncHandler(async (req, res) => {
  const userId = req.user?._id;
  if (!userId) throw new ApiError(401, "Authentication required");

  const cached = getCachedAccountStatus(userId);
  if (cached !== null) {
    return res
      .status(200)
      .json(
        new ApiResponse(200, { haveMarketplaceAccount: cached }, "Marketplace account status retrieved successfully")
      );
  }

  // If middleware already loaded user + flag, use it as the fastest hint.
  // (Still validate against MarketplaceProfile once per TTL to stay accurate.)
  const hinted = req.user?.haveMarketplaceAccount === true;

  let actuallyHasAccount = hinted;
  if (!hinted) {
    const exists = await MarketplaceProfile.exists({ userId, isActive: true });
    actuallyHasAccount = !!exists;
  } else {
    // If hinted true, confirm quickly but avoid over-fetching.
    const exists = await MarketplaceProfile.exists({ userId, isActive: true });
    actuallyHasAccount = !!exists;
  }

  setCachedAccountStatus(userId, actuallyHasAccount);

  // Best-effort sync without fetching/saving the whole user doc.
  await User.updateOne(
    { _id: userId, haveMarketplaceAccount: { $ne: actuallyHasAccount } },
    { $set: { haveMarketplaceAccount: actuallyHasAccount } }
  );

  return res
    .status(200)
    .json(
      new ApiResponse(
        200,
        { haveMarketplaceAccount: actuallyHasAccount },
        "Marketplace account status retrieved successfully"
      )
    );
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

    const {
      shopName,
      shopDescription,
      sellerBio,
      shopImage,
      address,
      geoLocation,
      whatsapp_number,
    } = req.body;

    // Validation
    if (!shopName?.trim()) {
      throw new ApiError(400, "Shop name is required");
    }

    if (!address?.trim()) {
      throw new ApiError(400, "Address is required");
    }

    const whatsappDigits = parseWhatsAppNumberOrThrow(whatsapp_number, { required: true });

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
      whatsapp_number: whatsappDigits,
      contactInfo,
      address: address.trim(),
      geoLocation: geoLocation || { type: "Point", coordinates: [0, 0] },
      isActive: true,
    });

    console.log('✅ Marketplace profile created:', marketplaceProfile._id);

    // ⚠️ CRITICAL: Update user's haveMarketplaceAccount field
    user.haveMarketplaceAccount = true;
    await user.save();

    invalidateCachedAccountStatus(user._id);
    
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
  const { category, subcategory } = req.query;
  const page = clampInt(req.query.page, { min: 1, max: 100000, fallback: 1 });
  const limit = clampInt(req.query.limit, { min: 1, max: 50, fallback: 20 });
  const searchRaw = typeof req.query.search === "string" ? req.query.search.trim() : "";
  const search = searchRaw.length > 64 ? searchRaw.slice(0, 64) : searchRaw;

  // Public marketplace browse: only admin-approved, available listings
  const filter = { status: "approved", isAvailable: true, isSold: false };

  if (category) filter.category = category;
  if (subcategory) filter.subcategory = subcategory;
  const skip = (page - 1) * limit;

  // Search strategy:
  // - Avoid queries for tiny search strings.
  // - For multi-word searches, use $text (requires text index).
  // - For short single-token searches, do a prefix match on title only.
  const isSearchActive = search.length >= 2;
  const isMultiWord = /\s/.test(search);

  if (isSearchActive) {
    if (isMultiWord || search.length >= 4) {
      filter.$text = { $search: search };
    } else {
      const escaped = escapeRegExp(search);
      filter.title = { $regex: `^${escaped}`, $options: "i" };
    }
  }

  let query = Item.find(filter)
    .populate("sellerId", "shopName shopImage contactInfo")
    .populate("userId", "username email profileImage")
    .skip(skip)
    .limit(limit)
    .lean();

  let countQuery = Item.countDocuments(filter);

  if (filter.$text) {
    query = query
      .sort({ score: { $meta: "textScore" }, createdAt: -1 })
      .select({ score: { $meta: "textScore" } });
  } else {
    query = query.sort({ createdAt: -1 });
  }

  // Enable index usage for case-insensitive prefix searches
  if (!filter.$text && isSearchActive && !isMultiWord && search.length < 4) {
    query = query.collation({ locale: "en", strength: 2 });
    countQuery = countQuery.collation({ locale: "en", strength: 2 });
  }

  let items;
  let totalItems;
  try {
    [items, totalItems] = await Promise.all([query, countQuery]);
  } catch (err) {
    // If the deployment hasn't built the text index yet, fall back to a safe regex-based search.
    const message = err?.message || "";
    const isTextIndexMissing = filter.$text && /text index required|IndexNotFound|no such index/i.test(message);
    if (!isTextIndexMissing) throw err;

    const escaped = escapeRegExp(search);
    const fallbackFilter = { ...filter };
    delete fallbackFilter.$text;
    fallbackFilter.$or = [
      { title: { $regex: escaped, $options: "i" } },
      { description: { $regex: escaped, $options: "i" } },
    ];

    const fallbackQuery = Item.find(fallbackFilter)
      .populate("sellerId", "shopName shopImage contactInfo")
      .populate("userId", "username email profileImage")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    [items, totalItems] = await Promise.all([
      fallbackQuery,
      Item.countDocuments(fallbackFilter),
    ]);
  }

  return res.status(200).json(
    new ApiResponse(200, {
      items,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalItems / limit) || 1,
        totalItems,
        itemsPerPage: limit,
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
    .populate(
      "sellerId",
      "shopName shopDescription shopImage contactInfo address geoLocation whatsapp_number"
    )
    .populate("userId", "username email profileImage");

  if (!item) throw new ApiError(404, "Product not found");

  const isAdmin = req.user?.isAdmin === true;
  const ownerId =
    (item.userId && typeof item.userId === "object" && item.userId._id
      ? item.userId._id
      : item.userId) || null;
  const isOwner =
    !!ownerId && ownerId.toString() === req.user?._id?.toString();
  const isPubliclyVisible =
    item.status === "approved" && item.isAvailable === true && item.isSold === false;

  if (!isAdmin && !isOwner && !isPubliclyVisible) {
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

  const {
    shopName,
    shopDescription,
    sellerBio,
    shopImage,
    address,
    geoLocation,
    isActive,
    whatsapp_number,
  } = req.body;

  if (shopName) marketplaceProfile.shopName = shopName.trim();
  if (shopDescription !== undefined) marketplaceProfile.shopDescription = shopDescription.trim();
  if (sellerBio !== undefined) marketplaceProfile.sellerBio = sellerBio.trim();
  if (shopImage !== undefined) marketplaceProfile.shopImage = shopImage;
  if (address !== undefined) marketplaceProfile.address = address.trim();
  if (geoLocation !== undefined) marketplaceProfile.geoLocation = geoLocation;
  if (isActive !== undefined) marketplaceProfile.isActive = isActive;
  if (whatsapp_number !== undefined) {
    marketplaceProfile.whatsapp_number = parseWhatsAppNumberOrThrow(whatsapp_number, {
      required: false,
    });
  }

  marketplaceProfile.contactInfo = {
    name: user.username,
    phone: marketplaceProfile.contactInfo.phone || "",
    email: user.email || "",
  };

  await marketplaceProfile.save();

  invalidateCachedAccountStatus(user._id);

  return res.status(200).json(
    new ApiResponse(200, { profile: marketplaceProfile }, "Profile updated successfully")
  );
});

// 7️⃣ Get saved items
const getSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);

  const populatedUser = await User.findById(user._id)
    .select("-password")
    .populate({
      path: "savedItems",
      match: { status: "approved", isAvailable: true, isSold: false },
      populate: { path: "sellerId", select: "shopName shopImage contactInfo" },
    });

  return res.status(200).json(
    new ApiResponse(200, { savedItems: populatedUser?.savedItems ?? [] }, "Saved items retrieved successfully")
  );
});

// Add to saved items
const addToSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.body;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  const item = await Item.findById(itemId);
  if (!item) throw new ApiError(404, "Item not found");

  const isOwner = item.userId.toString() === user._id.toString();
  if (!isOwner) {
    if (item.status !== "approved" || !item.isAvailable || item.isSold) {
      throw new ApiError(400, "This product is not available to save");
    }
  }

  const alreadySaved = (user.savedItems ?? []).some((id) => id.toString() === itemId.toString());
  if (alreadySaved) throw new ApiError(400, "Item already saved");

  user.savedItems = user.savedItems ?? [];
  user.savedItems.push(itemId);
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, { savedItems: user.savedItems }, "Item saved successfully")
  );
});

// Remove from saved items
const removeFromSavedItems = asyncHandler(async (req, res) => {
  const user = await getUser(req.user._id);
  const { itemId } = req.params;

  if (!itemId || !mongoose.isValidObjectId(itemId)) {
    throw new ApiError(400, "Valid item ID is required");
  }

  user.savedItems = (user.savedItems ?? []).filter((id) => id.toString() !== itemId);
  await user.save();

  return res.status(200).json(
    new ApiResponse(200, { savedItems: user.savedItems }, "Item removed successfully")
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

function assertSuperAdmin(req) {
  if (!req.user?.isAdmin) {
    throw new ApiError(403, "Only super admin can perform this action");
  }
}

// Super Admin: pending listing requests (awaiting approval)
const getAdminPendingListings = asyncHandler(async (req, res) => {
  assertSuperAdmin(req);
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
  const filter = { status: "pending", isSold: false };
  const skip = (page - 1) * limit;

  const items = await Item.find(filter)
    .populate("sellerId", "shopName shopImage contactInfo address")
    .populate("userId", "username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  const totalItems = await Item.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        items,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(totalItems / limit) || 1,
          totalItems,
          itemsPerPage: limit,
        },
      },
      "Pending listings retrieved successfully"
    )
  );
});

const approveAdminListing = asyncHandler(async (req, res) => {
  assertSuperAdmin(req);
  const { productId } = req.params;
  if (!productId || !mongoose.isValidObjectId(productId)) {
    throw new ApiError(400, "Valid product ID is required");
  }

  const item = await Item.findById(productId);
  if (!item) throw new ApiError(404, "Listing not found");
  if (item.status !== "pending") {
    throw new ApiError(400, "Only pending listings can be approved");
  }

  item.status = "approved";
  item.rejectionReason = null;
  item.isAvailable = true;
  await item.save();

  const populated = await Item.findById(item._id)
    .populate("sellerId", "shopName shopDescription shopImage contactInfo address geoLocation")
    .populate("userId", "username email profileImage");

  return res.status(200).json(
    new ApiResponse(200, { item: populated }, "Listing approved successfully")
  );
});

const rejectAdminListing = asyncHandler(async (req, res) => {
  assertSuperAdmin(req);
  const { productId } = req.params;
  const reason = req.body?.rejectionReason?.trim() || "";

  if (!productId || !mongoose.isValidObjectId(productId)) {
    throw new ApiError(400, "Valid product ID is required");
  }

  const item = await Item.findById(productId);
  if (!item) throw new ApiError(404, "Listing not found");
  if (!["pending", "approved"].includes(item.status)) {
    throw new ApiError(400, "Only pending or approved listings can be rejected");
  }

  item.status = "rejected";
  item.rejectionReason = reason || "Rejected by admin";
  item.isAvailable = false;
  await item.save();

  return res.status(200).json(
    new ApiResponse(200, { item }, "Listing rejected successfully")
  );
});

const deleteAdminListing = asyncHandler(async (req, res) => {
  assertSuperAdmin(req);
  const { productId } = req.params;
  if (!productId || !mongoose.isValidObjectId(productId)) {
    throw new ApiError(400, "Valid product ID is required");
  }

  const item = await Item.findById(productId);
  if (!item) throw new ApiError(404, "Listing not found");

  await MarketplaceProfile.updateMany(
    {},
    { $pull: { items: productId, savedItems: productId } }
  );

  await Item.findByIdAndDelete(productId);

  return res.status(200).json(
    new ApiResponse(200, {}, "Listing deleted successfully")
  );
});

// Super Admin: all marketplace listings (any status), with poster info
const getAdminAllListings = asyncHandler(async (req, res) => {
  assertSuperAdmin(req);
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
  const { status } = req.query;
  const filter = {};
  if (status && status !== "all" && ["pending", "approved", "rejected"].includes(status)) {
    filter.status = status;
  }

  const skip = (page - 1) * limit;
  const items = await Item.find(filter)
    .populate("sellerId", "shopName shopImage contactInfo")
    .populate("userId", "username email profileImage")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  const totalItems = await Item.countDocuments(filter);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        items,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(totalItems / limit) || 1,
          totalItems,
          itemsPerPage: limit,
        },
      },
      "All listings retrieved successfully"
    )
  );
});
/**
 * GET /marketplace/seller/:sellerId/profile
 * Public: View any active seller's full profile with stats + listings
 */
const getPublicSellerProfile = asyncHandler(async (req, res) => {
  const { sellerId } = req.params;

  if (!sellerId || !mongoose.isValidObjectId(sellerId)) {
    throw new ApiError(400, "Valid seller ID is required");
  }

  const sellerProfile = await MarketplaceProfile.findById(sellerId)
    .populate("userId", "username email profileImage createdAt")
    .populate({
      path: "items",
      match: { status: "approved", isAvailable: true, isSold: false },
      select: "title price images category subcategory condition createdAt",
      options: { sort: { createdAt: -1 }, limit: 20 },
    });

  if (!sellerProfile) throw new ApiError(404, "Seller profile not found");
  if (!sellerProfile.isActive) throw new ApiError(403, "This seller profile is inactive");

  // --- Stats ---
  const totalListings = await Item.countDocuments({
    sellerId: sellerProfile._id,
    status: "approved",
  });

  const soldCount = await Item.countDocuments({
    sellerId: sellerProfile._id,
    isSold: true,
  });

  const categoryBreakdown = await Item.aggregate([
    {
      $match: {
        sellerId: sellerProfile._id,
        status: "approved",
        isAvailable: true,
        isSold: false,
      },
    },
    { $group: { _id: "$category", count: { $sum: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);

  const memberSince = sellerProfile.createdAt
    ? new Date(sellerProfile.createdAt).getFullYear()
    : null;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        profile: {
          _id: sellerProfile._id,
          shopName: sellerProfile.shopName,
          shopDescription: sellerProfile.shopDescription,
          sellerBio: sellerProfile.sellerBio,
          shopImage: sellerProfile.shopImage,
          address: sellerProfile.address,
          whatsapp_number: sellerProfile.whatsapp_number || "",
          contactInfo: {
            name: sellerProfile.contactInfo?.name,
            email: sellerProfile.contactInfo?.email,
            // phone omitted for privacy; expose only if you want
          },
          isActive: sellerProfile.isActive,
          memberSince,
          user: sellerProfile.userId,
        },
        stats: {
          totalListings,
          soldCount,
          activeListings: sellerProfile.items?.length ?? 0,
          categoryBreakdown,
        },
        listings: sellerProfile.items ?? [],
      },
      "Seller profile retrieved successfully"
    )
  );
});

/**
 * GET /marketplace/profile/me/full
 * Auth required: View MY OWN full profile (includes pending/rejected items + all stats)
 */
const getMyFullProfile = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const sellerProfile = await MarketplaceProfile.findOne({ userId })
    .populate("userId", "username email profileImage createdAt")
    .populate({
      path: "items",
      select: "title price images category subcategory condition status isAvailable isSold createdAt rejectionReason",
      options: { sort: { createdAt: -1 } },
    });

  if (!sellerProfile) throw new ApiError(404, "Marketplace profile not found");

  const totalListings = await Item.countDocuments({ userId });
  const approvedCount = await Item.countDocuments({ userId, status: "approved" });
  const pendingCount = await Item.countDocuments({ userId, status: "pending" });
  const rejectedCount = await Item.countDocuments({ userId, status: "rejected" });
  const soldCount = await Item.countDocuments({ userId, isSold: true });

  const categoryBreakdown = await Item.aggregate([
    { $match: { userId: new mongoose.Types.ObjectId(userId), status: "approved" } },
    { $group: { _id: "$category", count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  const memberSince = sellerProfile.createdAt
    ? new Date(sellerProfile.createdAt).getFullYear()
    : null;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        profile: {
          _id: sellerProfile._id,
          shopName: sellerProfile.shopName,
          shopDescription: sellerProfile.shopDescription,
          sellerBio: sellerProfile.sellerBio,
          shopImage: sellerProfile.shopImage,
          address: sellerProfile.address,
          whatsapp_number: sellerProfile.whatsapp_number || "",
          contactInfo: sellerProfile.contactInfo,
          isActive: sellerProfile.isActive,
          memberSince,
          user: sellerProfile.userId,
        },
        stats: {
          totalListings,
          approvedCount,
          pendingCount,
          rejectedCount,
          soldCount,
          categoryBreakdown,
        },
        listings: sellerProfile.items ?? [],
      },
      "Your full marketplace profile retrieved successfully"
    )
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
  deleteMyListing,
  getAdminPendingListings,
  getAdminAllListings,
  approveAdminListing,
  rejectAdminListing,
  deleteAdminListing,
  getPublicSellerProfile, 
  getMyFullProfile 
};