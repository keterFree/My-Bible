// controllers/directMessages.js
const DirectMessage = require('../models/DirectMessage');
const User = require('../models/User'); // Assuming you have a User model

/**
 * Fetches an existing direct message between two users or creates a new one if none exists.
 * @param {Object} req - The request object.
 * @param {Object} res - The response object.
 */
exports.fetchOrCreateDirectMessage = async (req, res) => {
  const { currentUser, otherUser } = req.body; // Expect two user IDs from the request

  try {
    // Check if a direct message already exists between the two users
    let directMessage = await DirectMessage.findOne({
      participants: { $all: [currentUser, otherUser] }
    });

    if (!directMessage) {
      // If no direct message exists, create a new one
      directMessage = new DirectMessage({
        participants: [currentUser, otherUser],
        messages: []
      });
      await directMessage.save();
    }

    // Respond with the direct message ID
    res.json({ directMessageId: directMessage._id });
  } catch (error) {
    console.error('Error fetching or creating direct message:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
