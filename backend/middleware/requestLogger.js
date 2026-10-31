/**
 * Lightweight HTTP request logger middleware.
 * Outputs readable log entries with method, path, status, and response time.
 */
const requestLogger = (req, res, next) => {
  const start = Date.now();
  const timestamp = new Date().toISOString();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const status = res.statusCode;
    const statusColor =
      status >= 500 ? '\x1b[31m' : // Red
      status >= 400 ? '\x1b[33m' : // Yellow
      status >= 300 ? '\x1b[36m' : // Cyan
      '\x1b[32m';                  // Green
    const resetColor = '\x1b[0m';

    console.log(
      `[${timestamp}] ${req.method} ${req.originalUrl || req.url} ${statusColor}${status}${resetColor} (${duration}ms)`
    );
  });

  next();
};

module.exports = requestLogger;
