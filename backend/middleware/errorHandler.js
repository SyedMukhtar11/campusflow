const errorHandler = (err, req, res, next) => {
  if (res.headersSent) {
    return next(err);
  }

  // Handle Mongoose Schema Validation errors
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors)
      .map((e) => e.message)
      .join(', ');
    return res.status(400).json({ message });
  }

  // Handle Mongoose CastError (e.g. invalid ObjectId format like "reg_p2")
  if (err.name === 'CastError') {
    return res.status(400).json({
      message: `Invalid ID format for ${err.path}: "${err.value}"`,
    });
  }

  // Handle MongoDB Duplicate Key (code 11000)
  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern || {})[0] || 'field';
    return res.status(409).json({ message: `${field} already exists` });
  }

  // Handle JWT verification errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({ message: 'Not authorized, token failed' });
  }

  const status = err.statusCode || 500;
  if (status >= 500) {
    console.error(err);
  }
  res.status(status).json({
    message: err.message || 'Internal Server Error',
  });
};

module.exports = errorHandler;
