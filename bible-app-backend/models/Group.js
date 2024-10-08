const mongoose = require('mongoose');

const GroupSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    description: String,
    members: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    leaders: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }] // Only leaders can send messages in some groups
  });
  
  module.exports = mongoose.model('Group', GroupSchema);
  