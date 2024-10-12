const DirectMessage = require('../models/DirectMessage');
const Message = require('../models/Message'); // Assuming you have a Message model
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
    }).populate('messages'); // Populate the messages field with actual message data

    console.log(`currentUser: ${currentUser},otherUser: ${otherUser},directMessage:${directMessage}`);
    if (!directMessage) {
      // If no direct message exists, create a new one
      directMessage = new DirectMessage({
        participants: [currentUser, otherUser],
        messages: []
      });
      await directMessage.save();
    }

    // Respond with the direct message ID and its messages
    res.json({ directMessageId: directMessage._id, messages: directMessage.messages });
  } catch (error) {
    console.error('Error fetching or creating direct message:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

/**
 * Retrieves all messages associated with a direct message.
 * @param {Object} req - The request object.
 * @param {Object} res - The response object.
 */
exports.getMessagesByDirectMessageId = async (req, res) => {
  const { directMessageId } = req.params; // Get the directMessageId from the URL params

  try {
    // Find the direct message and populate its messages
    const directMessage = await DirectMessage.findById(directMessageId).populate('messages');
    
    if (!directMessage) {
      return res.status(404).json({ message: 'Direct message not found' });
    }

    // Respond with the messages of the direct message
    res.json({ messages: directMessage.messages });
  } catch (error) {
    console.error('Error retrieving messages:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
