const Program = require('../models/programSchema');
const Feedback = require('../models/feedbackSchema');
const asyncHandler = require('../utils/asyncHandler');

const ALLOWED_CATEGORIES = [
  'Content',
  'Speaker / Instructor',
  'Venue / Platform',
  'Organisation',
  'Other',
];

/**
 * @desc    Submit feedback for a program
 * @route   POST /programs/:id/feedback
 * @access  Private / Authenticated
 */
exports.submitFeedback = asyncHandler(async (req, res) => {
  const programId = req.params.id;
  const { rating, category, email, comment } = req.body || {};

  const program = await Program.findOne({ id: programId });
  if (!program) {
    return res.status(404).json({ message: 'Program not found' });
  }

  if (!rating || !category || !email || !comment) {
    return res.status(400).json({
      message: 'rating, category, email and comment are required',
    });
  }

  const numericRating = Number(rating);
  if (!Number.isInteger(numericRating) || numericRating < 1 || numericRating > 5) {
    return res.status(400).json({ message: 'Rating must be an integer between 1 and 5' });
  }

  if (!ALLOWED_CATEGORIES.includes(category)) {
    return res.status(400).json({
      message: `Category must be one of: ${ALLOWED_CATEGORIES.join(', ')}`,
    });
  }

  const trimmedComment = String(comment).trim();
  if (trimmedComment.length < 10) {
    return res.status(400).json({ message: 'Please write at least 10 characters' });
  }
  if (trimmedComment.length > 300) {
    return res.status(400).json({ message: 'Feedback cannot exceed 300 characters' });
  }

  const normalizedEmail = String(email).toLowerCase().trim();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(normalizedEmail)) {
    return res.status(400).json({ message: 'Enter a valid email' });
  }

  const entry = await Feedback.create({
    user: req.user?._id,
    programId,
    rating: numericRating,
    category,
    email: normalizedEmail,
    comment: trimmedComment,
  });

  res.status(201).json({
    message: 'Thank you for your feedback!',
    feedback: entry,
  });
});

/**
 * @desc    Get all feedback entries for a program
 * @route   GET /programs/:id/feedback
 * @access  Public
 */
exports.getFeedbackForProgram = asyncHandler(async (req, res) => {
  const programId = req.params.id;
  const program = await Program.findOne({ id: programId });
  if (!program) {
    return res.status(404).json({ message: 'Program not found' });
  }

  const list = await Feedback.find({ programId }).sort({ createdAt: -1 });
  res.status(200).json(list);
});
