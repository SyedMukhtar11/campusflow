const express = require('express');
const {
  listNotifications,
  markRead,
  markAllRead,
  deleteNotification,
  clearAll,
} = require('../controller/notificationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/', protect, listNotifications);
router.patch('/read-all', protect, markAllRead);
router.patch('/:id/read', protect, markRead);
router.delete('/:id', protect, deleteNotification);
router.delete('/', protect, clearAll);

module.exports = router;
