const mongoose = require('mongoose');
const Notification = require('../models/notificationSchema');
const asyncHandler = require('../utils/asyncHandler');

/**
 * @desc    Get all notifications for the current user
 * @route   GET /notifications
 * @access  Private
 */
exports.listNotifications = asyncHandler(async (req, res) => {
  const items = await Notification.find({ user: req.user._id }).sort({ createdAt: -1 });
  const unreadCount = items.filter((n) => !n.read).length;
  res.status(200).json({ unreadCount, notifications: items });
});

/**
 * @desc    Mark a single notification as read
 * @route   PATCH /notifications/:id/read
 * @access  Private
 */
exports.markRead = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Guard against non-ObjectId values (like temporary client IDs "reg_p2")
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ message: 'Notification not found' });
  }

  const item = await Notification.findOne({
    _id: id,
    user: req.user._id,
  });

  if (!item) {
    return res.status(404).json({ message: 'Notification not found' });
  }

  item.read = true;
  await item.save();
  res.status(200).json(item);
});

/**
 * @desc    Mark all notifications as read for current user
 * @route   PATCH /notifications/read-all
 * @access  Private
 */
exports.markAllRead = asyncHandler(async (req, res) => {
  await Notification.updateMany({ user: req.user._id, read: false }, { read: true });
  const items = await Notification.find({ user: req.user._id }).sort({ createdAt: -1 });
  res.status(200).json({ unreadCount: 0, notifications: items });
});

/**
 * @desc    Delete a notification by ID
 * @route   DELETE /notifications/:id
 * @access  Private
 */
exports.deleteNotification = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ message: 'Notification not found' });
  }

  const item = await Notification.findOneAndDelete({
    _id: id,
    user: req.user._id,
  });

  if (!item) {
    return res.status(404).json({ message: 'Notification not found' });
  }

  res.status(200).json({ message: 'Notification deleted successfully' });
});

/**
 * @desc    Clear all notifications for current user
 * @route   DELETE /notifications
 * @access  Private
 */
exports.clearAll = asyncHandler(async (req, res) => {
  await Notification.deleteMany({ user: req.user._id });
  res.status(200).json({
    message: 'All notifications cleared successfully',
    unreadCount: 0,
    notifications: [],
  });
});
