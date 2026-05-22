import mongoose from "mongoose";
import User from "../../models/auth/user.js";
import { MarketplaceProfile } from "../../models/marketplace/marketplace.model.js";
import { Item } from "../../models/marketplace/item.model.js";
import ChatRoom from "../../models/community_chat/ChatRoom.js";
import Message from "../../models/community_chat/Message.js";
import AIChat from "../../models/ai_chatbot/aiChat.js";
import AIMessage from "../../models/ai_chatbot/aiMessage.js";

/**
 * Permanently remove a user and all related data from the database.
 */
export async function blockAndDeleteUser(userId) {
  if (!mongoose.isValidObjectId(userId)) {
    throw new Error("Invalid user ID");
  }

  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");
  if (user.isAdmin) throw new Error("Cannot block admin accounts");

  const uid = user._id.toString();

  // Marketplace
  const sellerItems = await Item.find({ userId: uid }).select("_id");
  const itemIds = sellerItems.map((i) => i._id);
  if (itemIds.length > 0) {
    await User.updateMany(
      { savedItems: { $in: itemIds } },
      { $pull: { savedItems: { $in: itemIds } } }
    );
  }
  await Item.deleteMany({ userId: uid });
  await MarketplaceProfile.deleteMany({ userId: uid });

  // Community chat — messages, rooms created by user, membership
  await Message.deleteMany({ sender: uid });
  const createdRooms = await ChatRoom.find({ admin: uid }).select("_id");
  for (const room of createdRooms) {
    await Message.deleteMany({ roomId: room._id });
    await ChatRoom.findByIdAndDelete(room._id);
  }
  await ChatRoom.updateMany(
    { members: uid },
    { $pull: { members: uid } }
  );

  // AI chats
  const chats = await AIChat.find({ userId: uid }).select("_id");
  const chatIds = chats.map((c) => c._id);
  if (chatIds.length) {
    await AIMessage.deleteMany({ chatId: { $in: chatIds } });
    await AIChat.deleteMany({ userId: uid });
  }

  await User.findByIdAndDelete(uid);

  return { success: true, deletedUserId: uid };
}
