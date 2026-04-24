// ============================================
// FILE 2: src/index.js (UPDATED - Replace your existing index.js)
// ============================================
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";
import { app } from "./app.js";
import connectDB from "./db/index.js";
import cropRecommendationService from "./services/cropRecommendation/cropRecommendation.service.js";
import setupChatSocket from "./sockets/chatSocket.js";

// Load environment variables
dotenv.config({
  path: "./.env"
});

// Create HTTP server
const server = http.createServer(app);

// Setup Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.ORIGIN_URI || "*",
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling']
});

// Initialize Socket.IO handlers
setupChatSocket(io);

// Make io accessible to routes if needed
app.set('io', io);

// Express app error handler
app.on("error", (error) => {
  console.error("💥 Express App Error:", error);
});

// ============================================
// Graceful Shutdown Handlers
// ============================================
const gracefulShutdown = () => {
  console.log('\n⚠️  Shutdown signal received...');
  
  // Close Socket.IO connections
  io.close(() => {
    console.log('✅ Socket.IO connections closed');
  });
  
  // Close HTTP server
  server.close(() => {
    console.log('✅ HTTP server closed');
    process.exit(0);
  });

  // Force close after 10s
  setTimeout(() => {
    console.error('❌ Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

// ============================================
// Start Server
// ============================================
connectDB()
  .then(async () => {
    const PORT = process.env.PORT || 5000;
    const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5001';
    
    server.listen(PORT, "0.0.0.0", async () => {
      console.clear();
      console.log('\n' + '='.repeat(70));
      console.log('🌾 AgriCare Backend Server v2.0 - PRODUCTION READY');
      console.log('='.repeat(70));
      console.log(`✓ Server running on: http://0.0.0.0:${PORT}`);
      console.log(`✓ Socket.IO: Enabled and running`);
      console.log(`✓ ML Service: ${ML_SERVICE_URL}`);
      console.log(`✓ Database: Connected`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log('='.repeat(70));
      
      // Check ML service health
      console.log('\n🔍 Checking ML Service...');
      try {
        const mlHealth = await cropRecommendationService.checkMLHealth();
        if (mlHealth.available) {
          console.log('✅ ML Service is healthy and responding');
        } else {
          console.log('⚠️  ML Service is not available');
          console.log('   Start ML service or check ML_SERVICE_URL in .env');
        }
      } catch (error) {
        console.log('⚠️  Could not connect to ML Service');
      }
      
      console.log('\n📡 Available Endpoints:');
      console.log('\n   🏥 Health & Testing:');
      console.log(`      GET  http://0.0.0.0:${PORT}/`);
      console.log(`      GET  http://0.0.0.0:${PORT}/api/v1/crop-recommendation/health`);
      console.log(`      POST http://0.0.0.0:${PORT}/api/v1/crop-recommendation/test`);
      
      console.log('\n   🌾 Crop Recommendations:');
      console.log(`      POST http://0.0.0.0:${PORT}/api/v1/crop-recommendation/recommend`);
      console.log(`      GET  http://0.0.0.0:${PORT}/api/v1/crop-recommendation/crops`);
      console.log(`      POST http://0.0.0.0:${PORT}/api/recommend-crop (legacy)`);
      
      console.log('\n   👨‍🌾 Auth:');
      console.log(`      ...  http://0.0.0.0:${PORT}/api/v1/auth/*`);
      
      console.log('\n   🛒 Marketplace:');
      console.log(`      ...  http://0.0.0.0:${PORT}/api/v1/marketplace/*`);
      
      console.log('\n   💬 Community Chat (HTTP + Socket.IO):');
      console.log(`      ...  http://0.0.0.0:${PORT}/api/v1/chat/*`);
      console.log(`      WS:  ws://0.0.0.0:${PORT}/ (Socket.IO)`);
      
      console.log('\n🧪 Quick Tests:');
      console.log(`   curl http://0.0.0.0:${PORT}/api/v1/crop-recommendation/health`);
      console.log(`   curl -X POST http://0.0.0.0:${PORT}/api/v1/crop-recommendation/test`);
      
      console.log('\n📱 Flutter App Connection:');
      console.log(`   Android Emulator: http://10.0.2.2:${PORT}`);
      console.log(`   iOS Simulator:    http://localhost:${PORT}`);
      console.log(`   Real Device:      http://YOUR_PC_IP:${PORT}`);
      console.log(`   Socket.IO:        ws://10.0.2.2:${PORT} (Android)`);
      
      console.log('\n🔌 Socket.IO Events:');
      console.log(`   Client → Server:`);
      console.log(`      - joinRoom(roomId)`);
      console.log(`      - sendMessage({roomId, sender, message})`);
      console.log(`      - leaveRoom(roomId)`);
      console.log(`   Server → Client:`);
      console.log(`      - newMessage(message)`);
      console.log(`      - messageError(error)`);
      
      console.log('\n' + '='.repeat(70));
      console.log('✅ Server ready to accept requests!\n');
    });

    // Graceful shutdown handlers
    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);
  })
  .catch((err) => {
    console.error("❌ DB connection failed:", err);
    process.exit(1);
  });

// ============================================
// Uncaught Exception Handlers
// ============================================
process.on('uncaughtException', (err) => {
  console.error('💥 UNCAUGHT EXCEPTION:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 UNHANDLED REJECTION at:', promise);
  console.error('Reason:', reason);
  process.exit(1);
});