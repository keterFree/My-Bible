const mongoose = require('mongoose');

const GroupSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true },
  restricted: { type: Boolean, default: false },  // Corrected to Boolean
  description: String,
  members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  leaders: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
});

module.exports = mongoose.model('Group', GroupSchema);
