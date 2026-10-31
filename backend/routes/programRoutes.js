const express = require('express');
const { listPrograms, getProgramById } = require('../controller/programController');
const {
  registerForProgram,
  cancelRegistration,
} = require('../controller/registrationController');
const {
  submitFeedback,
  getFeedbackForProgram,
} = require('../controller/feedbackController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Program browsing
router.get('/', listPrograms);
router.get('/:id', getProgramById);

// Program registration & cancellation
router.post('/:id/register', protect, registerForProgram);
router.delete('/:id/register', protect, cancelRegistration);

// Program feedback
router.post('/:id/feedback', protect, submitFeedback);
router.get('/:id/feedback', getFeedbackForProgram);

module.exports = router;
