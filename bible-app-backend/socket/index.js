const Message = require('../models/Message');
const DirectMessage = require('../models/DirectMessage');

const socketHandler = (io) => {
  io.on('connection', (socket) => {
    console.log('New client connected');

    // Handle joining a group
    socket.on('joinGroup', ({ groupId }) => {
      socket.join(groupId);
      console.log(`User joined group: ${groupId}`);
    });

    // Handle sending messages
    socket.on('sendMessage', async ({ groupId, message }) => {
      try {
        const newMessage = new Message({
          content: message.content,
          sender: message.sender,
          group: groupId,
          timestamp: new Date(),
        });

        const savedMessage = await newMessage.save();

        // Broadcast to all users in the group
        io.to(groupId).emit('receiveMessage', savedMessage);
      } catch (err) {
        console.error('Error sending message:', err);
      }
    });

    // Handle private messages
    socket.on('sendDirectMessage', async ({ directMessageId, message }) => {
      try {
        const newMessage = new Message({
          content: message.content,
          sender: message.sender,
          timestamp: new Date(),
        });

        const savedMessage = await newMessage.save();

        await DirectMessage.findByIdAndUpdate(directMessageId, {
          $push: { messages: savedMessage._id },
        });

        io.to(directMessageId).emit('receiveDirectMessage', savedMessage);
      } catch (err) {
        console.error('Error sending direct message:', err);
      }
    });


    socket.on('disconnect', () => {
      console.log('Client disconnected');
    });
  });
};

module.exports = socketHandler;
