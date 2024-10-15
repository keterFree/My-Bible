const Group = require('../models/Group');
const User = require('../models/User');
const Message = require('../models/Message');

// Controller to fetch all groups
const getAllGroups = async (req, res) => {
  try {
    const groups = await Group.find()
      .populate('members', 'name')
      .populate('leaders', 'name')
      .populate('creator', 'name')
      .exec();
    res.status(200).json(groups);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching groups', error });
  }
};

// Controller to fetch a single group by ID
const getGroupById = async (req, res) => {
  try {
    const groupId = req.params.id;
    const group = await Group.findById(groupId)
      .populate('members', 'name')
      .populate('leaders', 'name')
      .populate('creator', 'name')
      .exec();
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }
    res.status(200).json(group);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching group', error });
  }
};

// Controller to create a new group
const createGroup = async (req, res) => {
  const { name, restricted, description, members, leaders } = req.body;
  const creator = req.user.id; // Authenticated user's ID

  try {
    const group = new Group({
      name,
      restricted: restricted || false,
      description,
      members: members || [creator],
      leaders: leaders || [creator],
      creator,
    });

    const savedGroup = await group.save();

    // Add the group ID to each member's and leader's groups list
    const usersToUpdate = new Set([
      ...(members || []),
      ...(leaders || []),
      creator,
    ]);

    await User.updateMany(
      { _id: { $in: [...usersToUpdate] }, groups: { $ne: savedGroup._id } }, // Avoid duplicates
      { $push: { groups: savedGroup._id } }
    );

    res.status(201).json(savedGroup);
  } catch (error) {
    if (error.code === 11000) {
      // Handle duplicate group name
      res.status(400).json({ message: 'Group name already exists' });
    } else {
      res.status(500).json({ message: `Error creating group ${error}`, error });
    }
  }
};



const addMembersOrLeaders = async (req, res) => {
  console.log('innitializing addition');
  const groupId = req.params.id; // Extract group ID from params

  console.log(`The group id: ${groupId}`)

  const { membersToAdd = [], leadersToAdd = [] } = req.body; // Extract request body
  const userId = req.user.id; // Authenticated user's ID

  try {
    // Find the group by ID
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if the authenticated user is a leader of the group
    if (!group.leaders.includes(userId)) {
      return res.status(403).json({ message: 'You are not authorized to modify this group' });
    }

    // Add new members, ensuring no duplicates
    group.members = Array.from(new Set([...group.members, ...membersToAdd]));

    // Add new leaders, ensuring no duplicates, and also add them to members
    leadersToAdd.forEach((leader) => {
      if (!group.leaders.includes(leader)) {
        group.leaders.push(leader);
      }
      if (!group.members.includes(leader)) {
        group.members.push(leader); // Ensure leaders are also members
      }
    });

    // Save the group
    const updatedGroup = await group.save();

    // Add the group ID to each user's groups list
    const usersToUpdate = [...membersToAdd, ...leadersToAdd];
    await User.updateMany(
      { _id: { $in: usersToUpdate }, groups: { $ne: groupId } }, // Avoid adding duplicate group IDs
      { $push: { groups: groupId } }
    );

    res.status(200).json(updatedGroup);
  } catch (error) {
    res.status(500).json({ message: 'Error updating group', error });
  }
};


// Controller to fetch all messages for a group
const getMessagesByGroup = async (req, res) => {
  try {
    const groupId = req.params.id; // Extract group ID from URL params

    // Fetch messages for the group, and populate the sender's details
    const messages = await Message.find({ group: groupId })
      .populate('sender', 'name') // Populate sender name
      .sort({ timestamp: 1 }) // Sort messages by timestamp
      .exec();

    if (!messages.length) {
      return res.status(404).json({ message: 'No messages found for this group' });
    }

    res.status(200).json(messages);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching messages', error });
  }
};


module.exports = {
  getAllGroups,
  getGroupById,
  createGroup,
  addMembersOrLeaders,
  getMessagesByGroup
};

