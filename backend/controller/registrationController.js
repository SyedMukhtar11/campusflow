const Program = require('../models/programSchema');
const Registration = require('../models/registrationSchema');
const Notification = require('../models/notificationSchema');
const asyncHandler = require('../utils/asyncHandler');
const { createRegistrationNotification } = require('../services/notificationService');

/**
 * @desc    Register current user for a program
 * @route   POST /programs/:id/register
 * @access  Private
 */
exports.registerForProgram = asyncHandler(async (req, res) => {
  const programId = req.params.id;
  const program = await Program.findOne({ id: programId });
  if (!program) {
    return res.status(404).json({ message: 'Program not found' });
  }

  const already = await Registration.findOne({ user: req.user._id, programId });
  if (already) {
    return res.status(409).json({ message: 'You are already registered for this program' });
  }

  // Atomically check capacity and increment registered count
  const updated = await Program.findOneAndUpdate(
    { id: programId, $expr: { $lt: ['$registered', '$capacity'] } },
    { $inc: { registered: 1 } },
    { returnDocument: 'after' }
  );

  if (!updated) {
    return res.status(409).json({ message: 'Event full' });
  }

  let reg;
  try {
    reg = await Registration.create({
      user: req.user._id,
      programId,
      completedModules: [],
      progress: 0,
      status: 'ongoing',
    });
  } catch (error) {
    // Revert the seat count increment if creating registration record fails
    await Program.findOneAndUpdate({ id: programId }, { $inc: { registered: -1 } });
    if (error.code === 11000) {
      return res.status(409).json({ message: 'You are already registered for this program' });
    }
    throw error;
  }

  await createRegistrationNotification(req.user._id, updated);

  res.status(201).json({
    message: 'Registration confirmed',
    program: updated,
    registration: {
      id: reg._id.toString(),
      programId: reg.programId,
      completedModules: reg.completedModules,
      progress: reg.progress,
      status: reg.status,
      registeredAt: reg.createdAt,
    },
  });
});

/**
 * @desc    Cancel a user's registration for a program
 * @route   DELETE /programs/:id/register or DELETE /registrations/:programId
 * @access  Private
 */
exports.cancelRegistration = asyncHandler(async (req, res) => {
  const programId = req.params.id || req.params.programId;

  const existing = await Registration.findOneAndDelete({
    user: req.user._id,
    programId,
  });

  if (!existing) {
    return res.status(404).json({ message: 'Registration not found' });
  }

  // Atomically decrement seats (down to minimum 0)
  const updated = await Program.findOneAndUpdate(
    { id: programId, registered: { $gt: 0 } },
    { $inc: { registered: -1 } },
    { returnDocument: 'after' }
  );

  // Send cancellation notification
  await Notification.create({
    user: req.user._id,
    title: 'Registration Cancelled',
    message: `Your registration for ${updated ? updated.title : programId} was cancelled.`,
    icon: 'event_busy',
  });

  res.status(200).json({
    message: 'Registration cancelled successfully',
    program: updated,
  });
});

/**
 * @desc    List all programs registered by the current user with progress and status
 * @route   GET /registrations
 * @access  Private
 */
exports.listMyRegistrations = asyncHandler(async (req, res) => {
  const registrations = await Registration.find({ user: req.user._id }).sort({
    createdAt: -1,
  });
  const programIds = registrations.map((r) => r.programId);
  const programs = await Program.find({ id: { $in: programIds } });
  const byId = Object.fromEntries(programs.map((p) => [p.id, p]));

  res.status(200).json(
    registrations.map((r) => ({
      id: r._id.toString(),
      programId: r.programId,
      completedModules: r.completedModules || [],
      progress: r.progress || 0,
      status: r.status || 'ongoing',
      completedAt: r.completedAt || null,
      registeredAt: r.createdAt,
      program: byId[r.programId] || null,
    }))
  );
});

/**
 * @desc    Get registration details for a single program
 * @route   GET /registrations/:programId
 * @access  Private
 */
exports.getRegistration = asyncHandler(async (req, res) => {
  const { programId } = req.params;
  const reg = await Registration.findOne({ user: req.user._id, programId });
  if (!reg) {
    return res.status(404).json({ message: 'Registration not found' });
  }

  const program = await Program.findOne({ id: programId });

  res.status(200).json({
    id: reg._id.toString(),
    programId: reg.programId,
    completedModules: reg.completedModules || [],
    progress: reg.progress || 0,
    status: reg.status || 'ongoing',
    completedAt: reg.completedAt || null,
    registeredAt: reg.createdAt,
    program: program || null,
  });
});

/**
 * @desc    Toggle a module's completed state for an ongoing program
 * @route   PATCH /registrations/:programId/modules/:moduleIndex/toggle
 * @access  Private
 */
exports.toggleModuleCompletion = asyncHandler(async (req, res) => {
  const { programId, moduleIndex } = req.params;
  const index = parseInt(moduleIndex, 10);

  if (isNaN(index) || index < 0) {
    return res.status(400).json({ message: 'Module index must be a non-negative integer' });
  }

  const program = await Program.findOne({ id: programId });
  if (!program) {
    return res.status(404).json({ message: 'Program not found' });
  }

  const totalModules = (program.learningPath && program.learningPath.length) > 0
    ? program.learningPath.length
    : 1;

  if (program.learningPath && index >= program.learningPath.length) {
    return res.status(400).json({
      message: `Module index out of range (program has ${program.learningPath.length} modules)`,
    });
  }

  const registration = await Registration.findOne({
    user: req.user._id,
    programId,
  });

  if (!registration) {
    return res.status(404).json({
      message: 'You are not registered for this program. Please register first.',
    });
  }

  const completed = new Set(registration.completedModules || []);
  let actionTaken;
  if (completed.has(index)) {
    completed.delete(index);
    actionTaken = 'unmarked';
  } else {
    completed.add(index);
    actionTaken = 'marked_complete';
  }

  const completedList = Array.from(completed).sort((a, b) => a - b);
  const progress = Math.min(100, Math.round((completedList.length / totalModules) * 100));
  const newStatus = progress === 100 ? 'completed' : 'ongoing';

  registration.completedModules = completedList;
  registration.progress = progress;
  const wasNotCompleted = registration.status !== 'completed';
  registration.status = newStatus;
  registration.completedAt = newStatus === 'completed' ? (registration.completedAt || new Date()) : null;

  await registration.save();

  // If newly reached 100%, trigger celebration notification
  if (newStatus === 'completed' && wasNotCompleted) {
    await Notification.create({
      user: req.user._id,
      title: 'Program Completed! 🎉',
      message: `Congratulations! You completed all modules for ${program.title}. Check your profile for completion rewards.`,
      icon: 'celebration',
    });
  }

  res.status(200).json({
    message: `Module ${index + 1} ${actionTaken === 'marked_complete' ? 'marked as complete' : 'unmarked'}`,
    action: actionTaken,
    registration: {
      id: registration._id.toString(),
      programId: registration.programId,
      completedModules: registration.completedModules,
      progress: registration.progress,
      status: registration.status,
      completedAt: registration.completedAt,
      registeredAt: registration.createdAt,
    },
  });
});
