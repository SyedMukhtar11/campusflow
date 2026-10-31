const User = require('../models/userSchema');
const asyncHandler = require('../utils/asyncHandler');
const toUserPayload = require('../utils/userPayload');
const { signToken } = require('../services/tokenService');
const { seedWelcomeNotifications } = require('../services/notificationService');

/**
 * @desc    Register a new user
 * @route   POST /auth/signup
 * @access  Public
 */
exports.signup = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body || {};

  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Name, email and password are required' });
  }

  const trimmedName = String(name).trim();
  const normalizedEmail = String(email).toLowerCase().trim();

  if (trimmedName.length < 2) {
    return res.status(400).json({ message: 'Name must be at least 2 characters' });
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(normalizedEmail)) {
    return res.status(400).json({ message: 'Enter a valid email' });
  }

  if (String(password).length < 6) {
    return res.status(400).json({ message: 'Password must be at least 6 characters' });
  }

  const existing = await User.findOne({ email: normalizedEmail });
  if (existing) {
    return res.status(409).json({ message: 'An account with this email already exists' });
  }

  const user = await User.create({
    name: trimmedName,
    email: normalizedEmail,
    password,
  });

  // Seed welcome notifications for the newly registered user
  await seedWelcomeNotifications(user._id);

  // Generate JWT token so client can authenticate immediately
  const token = signToken(user._id);

  res.status(201).json({
    message: 'Account created successfully',
    token,
    user: toUserPayload(user),
  });
});

/**
 * @desc    Authenticate user & get token
 * @route   POST /auth/login
 * @access  Public
 */
exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  const normalizedEmail = String(email).toLowerCase().trim();
  const user = await User.findOne({ email: normalizedEmail }).select('+password');

  if (!user || !(await user.matchPassword(password))) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  res.status(200).json({
    token: signToken(user._id),
    user: toUserPayload(user),
  });
});

/**
 * @desc    Get current authenticated user profile
 * @route   GET /auth/me
 * @access  Private
 */
exports.getMe = asyncHandler(async (req, res) => {
  res.status(200).json({ user: toUserPayload(req.user) });
});

/**
 * @desc    Update current user profile (name and/or email)
 * @route   PUT /auth/me
 * @access  Private
 */
exports.updateMe = asyncHandler(async (req, res) => {
  const { name, email } = req.body || {};

  if (name !== undefined) {
    const trimmedName = String(name).trim();
    if (trimmedName.length < 2) {
      return res.status(400).json({ message: 'Name must be at least 2 characters' });
    }
    req.user.name = trimmedName;
  }

  if (email !== undefined) {
    const normalizedEmail = String(email).toLowerCase().trim();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(normalizedEmail)) {
      return res.status(400).json({ message: 'Enter a valid email' });
    }

    const existing = await User.findOne({
      email: normalizedEmail,
      _id: { $ne: req.user._id },
    });
    if (existing) {
      return res.status(409).json({ message: 'An account with this email already exists' });
    }
    req.user.email = normalizedEmail;
  }

  await req.user.save();
  res.status(200).json({ user: toUserPayload(req.user) });
});

/**
 * @desc    Delete current user account
 * @route   DELETE /auth/me
 * @access  Private
 */
exports.deleteMe = asyncHandler(async (req, res) => {
  await req.user.deleteOne();
  res.status(200).json({ message: 'Account deleted successfully' });
});
