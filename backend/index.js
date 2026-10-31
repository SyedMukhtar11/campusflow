require('dotenv').config();
const mongoose = require('mongoose');
const app = require('./app');
const connectDb = require('./config/db');
const seedPrograms = require('./seed/seedPrograms');

const PORT = process.env.PORT || 3000;

const start = async () => {
  if (!process.env.MONGODB_URI) {
    console.error('[Startup Error] MONGODB_URI is not set in environment or .env file');
    process.exit(1);
  }
  if (!process.env.JWT_SECRET) {
    console.error('[Startup Error] JWT_SECRET is not set in environment or .env file');
    process.exit(1);
  }

  // Connect to Database
  await connectDb(process.env.MONGODB_URI);

  // Seed default programs if collection is empty
  await seedPrograms();

  // Listen on 0.0.0.0 so emulator and local network can access
  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`[CampusFlow] Server listening on http://0.0.0.0:${PORT}`);
    console.log(`[CampusFlow] Health check available at http://localhost:${PORT}/health`);
  });

  // Graceful shutdown handling
  const shutdown = async (signal) => {
    console.log(`\n[CampusFlow] Received ${signal}. Closing server gracefully...`);
    server.close(async () => {
      console.log('[CampusFlow] HTTP server closed.');
      await mongoose.connection.close();
      console.log('[CampusFlow] MongoDB connection closed. Exiting process.');
      process.exit(0);
    });

    // Force shutdown after 5 seconds if graceful closing hangs
    setTimeout(() => {
      console.error('[CampusFlow] Could not close connections in time, forcefully shutting down');
      process.exit(1);
    }, 5000);
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
};

start().catch((error) => {
  console.error('[CampusFlow] Fatal startup error:', error);
  process.exit(1);
});
