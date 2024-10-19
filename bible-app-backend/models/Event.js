const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  theme: { type: String, required: true },
  date: { type: Date, required: true },
  time: { type: String, required: true },
  venue: { type: String, required: true },
  keyGuests: [{ type: String }],  // Array of guest names
  planners: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  registered: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],  // Array of references to the User model
  program: [
    {
      startTime: { type: String, required: true, match: /^([01]\d|2[0-3]):([0-5]\d)$/ },  // HH:mm format
      endTime: { type: String, required: true, match: /^([01]\d|2[0-3]):([0-5]\d)$/ },  // HH:mm format
      description: { type: String, required: true }
    }
  ]
});

module.exports = mongoose.model('Event', eventSchema);
