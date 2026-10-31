const Program = require('../models/programSchema');
const asyncHandler = require('../utils/asyncHandler');

/**
 * @desc    List all programs with optional category and search filters
 * @route   GET /programs
 * @access  Public
 * @query   category (optional) - 'All', 'Workshop', 'Seminar', 'Career'
 * @query   q (optional) - Search string matching title or tagline
 */
exports.listPrograms = asyncHandler(async (req, res) => {
  const { category, q } = req.query;
  const filter = {};

  if (category && category !== 'All') {
    filter.category = category;
  }

  if (q && q.trim()) {
    const searchRegex = { $regex: q.trim(), $options: 'i' };
    filter.$or = [{ title: searchRegex }, { tagline: searchRegex }];
  }

  const programs = await Program.find(filter).sort({ startsInDays: 1, title: 1 });
  res.status(200).json(programs);
});

/**
 * @desc    Get a single program by its ID
 * @route   GET /programs/:id
 * @access  Public
 */
exports.getProgramById = asyncHandler(async (req, res) => {
  const program = await Program.findOne({ id: req.params.id });
  if (!program) {
    return res.status(404).json({ message: 'Program not found' });
  }
  res.status(200).json(program);
});
