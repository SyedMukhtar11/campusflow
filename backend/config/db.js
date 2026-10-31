const mongoose = require('mongoose');

/**
 * Connects to MongoDB with connection event listeners and graceful fallback.
 * If the primary URI (e.g. Atlas cluster) cannot be reached due to network
 * or IP whitelist restrictions, it automatically falls back to local MongoDB
 * (mongodb://127.0.0.1:27017/CampusFlow) so development never halts.
 *
 * @param {string} primaryUri - MongoDB connection string from environment.
 * @returns {Promise<mongoose.Connection>}
 */
const connectDb = async (primaryUri) => {
  mongoose.set('strictQuery', true);

  // Monitor connection events for reliability and easy debugging
  mongoose.connection.on('connected', () => {
    const host = mongoose.connection.host;
    const dbName = mongoose.connection.name;
    console.log(`[Database] MongoDB connected: ${host}/${dbName}`);
  });

  mongoose.connection.on('error', (err) => {
    console.error(`[Database] MongoDB connection error: ${err.message}`);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('[Database] MongoDB connection disconnected');
  });

  try {
    console.log('[Database] Connecting to MongoDB...');
    await mongoose.connect(primaryUri);
    return mongoose.connection;
  } catch (primaryError) {
    const localUri = 'mongodb://127.0.0.1:27017/CampusFlow';

    // If already targeting local, or if local uri is the same, rethrow
    if (primaryUri === localUri) {
      throw primaryError;
    }

    console.warn(
      `[Database] Warning: Failed to connect to primary MongoDB URI (${primaryError.message}).`
    );
    console.warn(`[Database] Attempting fallback to local MongoDB at ${localUri}...`);

    try {
      await mongoose.connect(localUri, {
        serverSelectionTimeoutMS: 3000,
      });
      console.log('[Database] Fallback to local MongoDB succeeded.');
      return mongoose.connection;
    } catch (fallbackError) {
      console.error(
        '[Database] Both primary and local MongoDB connections failed.'
      );
      throw primaryError;
    }
  }
};

module.exports = connectDb;
