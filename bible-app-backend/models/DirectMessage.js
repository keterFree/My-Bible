const mongoose = require('mongoose');

const DirectMessageSchema = new mongoose.Schema({
  participants: [
    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
  ],
  messages: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Message' }]
});

module.exports = mongoose.model('DirectMessage', DirectMessageSchema);
