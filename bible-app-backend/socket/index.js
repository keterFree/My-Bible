const Message = require('../models/Message');
const DirectMessage = require('../models/DirectMessage');
const Group = require('../models/Group');

const socketHandler = (io) => {
  io.on('connection', (socket) => {
    console.log('New client connected');

    // Handle joining a group
    socket.on('joinGroup', ({ groupId }) => {
      socket.join(groupId);
      console.log(`User joined group: ${groupId}`);
    });

    // Handle sending group messages
    socket.on('sendGroupMessage', async ({ groupId, message, userId }) => {
      try {
        const group = await Group.findById(groupId);

        if (!group) {
          return socket.emit('error', { message: 'Group not found.' });
        }

        // Check if the group is restricted and whether the user is allowed to send messages
        const isLeader = group.leaders.includes(userId);
        if (group.restricted && !isLeader) {
          return socket.emit('error', { message: 'Only leaders can send messages in this group.' });
        }

        // Save the new message to the database
        const newMessage = new Message({
          content: message.content,
          sender: userId,
          group: groupId,
          timestamp: Date.now(),  // Ensure timestamp is the current time
        });

        const savedMessage = await newMessage.save();

        // Broadcast to all users in the group
        io.to(groupId).emit('receiveGroupMessage', savedMessage);
      } catch (err) {
        console.error('Error sending group message:', err);
        socket.emit('error', { message: 'Failed to send group message.' });
      }
    });

    // Handle direct/private messages
    socket.on('sendDirectMessage', async ({ directMessageId, message }) => {
      console.log(`${directMessageId}, says: ${message.content}, from: ${message.sender}`);

      try {
        const newMessage = new Message({
          content: message.content,
          sender: message.sender,
          timestamp: new Date(),
        });

        const savedMessage = await newMessage.save();

        // Update the DirectMessage conversation with the new message
        await DirectMessage.findByIdAndUpdate(directMessageId, {
          $push: { messages: savedMessage._id },
        }).then(console.log("updated messages list"));

        // Ensure both participants are in the private room identified by `directMessageId`
        socket.join(directMessageId);

        // Broadcast only to users in the specific directMessageId room
        io.to(directMessageId).emit('receiveDirectMessage', savedMessage);
      } catch (err) {
        console.error('Error sending direct message:', err);

        // Optional: send error acknowledgment to the sender
        socket.emit('error', { message: 'Failed to send direct message.' });
      }
    });

    // Handle client disconnects
    socket.on('disconnect', () => {
      console.log('Client disconnected');
    });
  });
};

module.exports = socketHandler;
