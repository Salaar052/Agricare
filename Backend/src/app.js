// File: src/app.js

import express from "express"
import cors from "cors"
import cookieParser from "cookie-parser"

const app = express()

// ============================================
// CORS Configuration
// ============================================
const corsOptions = {
    origin: process.env.ORIGIN_URI || '*', // Allow all origins in development
    credentials: true,
    optionsSuccessStatus: 200
}

app.use(cors(corsOptions))

// ============================================
// Middleware
// ============================================
app.use(express.json({limit: "16kb"}));
app.use(express.urlencoded({extended:true, limit: "16kb"}));
app.use(cookieParser());
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// ============================================
// Import Routes
// ============================================
import aiChatbotRouter from "./routes/ai_chatbot/aiChatRoutes.js";
import marketplaceRouter from "./routes/marketplace/marketplace.routes.js"
import cropRecommendationRouter from "./routes/cropRecommendation.routes.js"
import authRouter from "./routes/auth/authentication.js"
import uploadRouter from "./routes/marketplace/upload.routes.js"
import community_chatRouter from "./routes/community_chat/chatRoutes.js"; // 🔥 ADDED


// ============================================
// Mount Routes
// ============================================

app.use("/api/v1/aichatbot", aiChatbotRouter)
app.use("/api/v1/marketplace", marketplaceRouter)
app.use("/api/v1/auth", authRouter)
app.use("/api/v1/crop-recommendation", cropRecommendationRouter)
app.use('/api/v1/upload', uploadRouter);
app.use("/api/v1/chat", community_chatRouter); // 🔥 ADDED Community Chat Routes

// Backward compatibility with old API (optional)
// Maps old endpoint to new endpoint
app.post("/api/recommend-crop", (req, res, next) => {
  req.url = "/api/v1/crop-recommendation/recommend";
  cropRecommendationRouter(req, res, next);
});

// ============================================
// Root Endpoint
// ============================================
app.get('/', (req, res) => {
  res.json({
    message: 'AgriCare Backend API',
    version: '2.0',
    status: 'running',
    endpoints: {
      auth: '/api/v1/auth',
      marketplace: '/api/v1/marketplace',
      cropRecommendation: '/api/v1/crop-recommendation',
      aiChatbot: '/api/v1/aichatbot',
      communityChat: '/api/v1/chat', // 🔥 ADDED
      health: '/api/v1/crop-recommendation/health'
    },
    timestamp: new Date().toISOString()
  });
});

// ============================================
// Error Handlers
// ============================================

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    method: req.method,
    available_endpoints: [
      'GET  /',
      'GET  /api/v1/crop-recommendation/health',
      'POST /api/v1/crop-recommendation/recommend',
      'GET  /api/v1/crop-recommendation/crops',
      'POST /api/v1/crop-recommendation/test',
      'POST /api/recommend-crop (legacy)',
      '...  /api/v1/farmers/*',
      '...  /api/v1/marketplace/*',
      '...  /api/v1/aichatbot/*',
      '...  /api/v1/chat/*' // 🔥 ADDED
    ],
    timestamp: new Date().toISOString()
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('💥 Unhandled Error:', err);
  res.status(err.statusCode || 500).json({
    error: 'Internal server error',
    message: err.message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    timestamp: new Date().toISOString()
  });
});

export { app }