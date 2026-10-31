const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const authRoutes = require('./routes/authRoutes');
const programRoutes = require('./routes/programRoutes');
const registrationRoutes = require('./routes/registrationRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const requestLogger = require('./middleware/requestLogger');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Global middleware
app.use(cors());
app.use(express.json());

// Enable HTTP request logging in non-test environments
if (process.env.NODE_ENV !== 'test') {
  app.use(requestLogger);
}

// Root endpoint
app.get('/', (_req, res) => {
  res.json({
    name: 'CampusFlow API',
    version: '1.0.0',
    status: 'ok',
    docs: '/openapi.yaml',
  });
});

// Health check endpoint (checks service & database health)
app.get('/health', (_req, res) => {
  const dbStates = ['disconnected', 'connected', 'connecting', 'disconnecting'];
  const stateIndex = mongoose.connection.readyState;
  const dbStatus = dbStates[stateIndex] || 'unknown';

  res.status(200).json({
    status: 'ok',
    database: dbStatus,
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/auth', authRoutes);
app.use('/programs', programRoutes);
app.use('/registrations', registrationRoutes);
app.use('/notifications', notificationRoutes);

// 404 Route Not Found
app.use((req, res) => {
  res.status(404).json({ message: `Route ${req.method} ${req.path} not found` });
});

// Centralized Error Handling Middleware
app.use(errorHandler);

module.exports = app;
