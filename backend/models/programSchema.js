const mongoose = require('mongoose');

const programSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true },
    title: { type: String, required: true, trim: true },
    tagline: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    category: {
      type: String,
      enum: ['Workshop', 'Seminar', 'Career'],
      default: 'Workshop',
    },
    date: { type: String, default: '' },
    time: { type: String, default: '' },
    location: { type: String, default: '' },
    capacity: { type: Number, required: true, min: 1 },
    registered: { type: Number, default: 0, min: 0 },
    about: { type: String, default: '' },
    learnPoints: { type: [String], default: [] },
    whatYouWillDo: { type: [String], default: [] },
    recommendation: { type: String, default: '' },
    duration: { type: String, default: '' },
    fee: { type: String, default: 'Free' },
    supportedBy: { type: String, default: '' },
    
    learningPath: { type: [String], default: [] },
    lastDateToApply: { type: String, default: '' },
    startDate: { type: String, default: '' },
    endDate: { type: String, default: '' },
    completionRewards: { type: [String], default: [] },
    eligibility: { type: [String], default: [] },
    icon: { type: String, default: 'lightbulb' },
    color: { type: String, default: '#4F46E5' },
    progress: { type: Number, default: 0 },
    institution: { type: String, default: 'CampusFlow' },
    institutionShort: { type: String, default: 'CF' },
    nextSubmission: { type: String, default: '' },
  },
  { timestamps: true }
);

programSchema.set('toJSON', {
  transform(_doc, ret) {
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const Program = mongoose.model('Program', programSchema);

module.exports = Program;
