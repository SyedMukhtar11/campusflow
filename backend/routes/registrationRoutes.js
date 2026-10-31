const express = require('express');
const {
  listMyRegistrations,
  getRegistration,
  cancelRegistration,
  toggleModuleCompletion,
} = require('../controller/registrationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', protect, listMyRegistrations);
router.get('/:programId', protect, getRegistration);
router.delete('/:programId', protect, cancelRegistration);
router.patch('/:programId/modules/:moduleIndex/toggle', protect, toggleModuleCompletion);

module.exports = router;
