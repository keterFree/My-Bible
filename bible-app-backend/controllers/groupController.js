// controllers/groupController.js

const Group = require('../models/Group'); // Import Group model

// Controller to fetch all groups
const getAllGroups = async (req, res) => {
  try {
    const groups = await Group.find().populate('members', 'name').populate('leaders', 'name').exec();
    res.status(200).json(groups);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching groups', error });
  }
};

// Controller to fetch a single group by ID
const getGroupById = async (req, res) => {
  try {
    const groupId = req.params.id;
    const group = await Group.findById(groupId).populate('members', 'name').populate('leaders', 'name').exec();
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }
    res.status(200).json(group);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching group', error });
  }
};

module.exports = {
  getAllGroups,
  getGroupById,
};
