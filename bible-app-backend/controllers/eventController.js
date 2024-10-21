const Event = require('../models/Event');
const mongoose = require('mongoose');

// Utility function to convert "HH:mm" string to total minutes since midnight
const timeStringToMinutes = (timeString) => {
  const [hours, minutes] = timeString.split(':').map(Number);
  return hours * 60 + minutes;
};

// Create a new event (setEvent)
const setEvent = async (req, res) => {
  try {
    const { title, description, theme, date, time, venue, keyGuests, program } = req.body;
    const planners = [req.user.id];

    if (!title || !description || !date || !time || !venue) {
      return res.status(400).send({ error: 'Please provide all required fields' });
    }

    const newEvent = new Event({
      title,
      description,
      theme,
      date,
      time,
      venue,
      keyGuests,
      planners,
      program,
    });

    await newEvent.save();
    res.status(201).send(newEvent);
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).send({ error: 'An error occurred while creating the event' });
  }
};

// Retrieve all events (getEvents)
const getEvents = async (req, res) => {
  try {
    const events = await Event.find().populate('planners', 'name').sort({ date: 1 });
    res.status(200).send(events);
  } catch (error) {
    console.error('Error retrieving events:', error);
    res.status(500).send({ error: 'An error occurred while retrieving the events' });
  }
};

// Retrieve an event by date (getEventByDate)
const getEventByDate = async (req, res) => {
  try {
    const { date } = req.params;
    const event = await Event.findOne({ date }).populate('planners', 'name').exec();

    if (!event) {
      return res.status(404).send({ error: 'No event found for this date' });
    }

    // Sort the program items by startTime
    event.program.sort((a, b) => timeStringToMinutes(a.startTime) - timeStringToMinutes(b.startTime));

    res.status(200).send(event);
  } catch (error) {
    console.error('Error retrieving event:', error);
    res.status(500).send({ error: 'An error occurred while retrieving the event' });
  }
};


// Retrieve an event by ID (getEventById)
const getEventById = async (req, res) => {
  try {
    const { eventId } = req.params;

    const event = await Event.findById(eventId).populate('planners', 'name').exec();

    if (!event) {
      return res.status(404).send({ error: 'Event not found' });
    }

    // Sort the program items by startTime
    event.program.sort((a, b) => timeStringToMinutes(a.startTime) - timeStringToMinutes(b.startTime));

    res.status(200).send(event);
  } catch (error) {
    console.error('Error retrieving event by ID:', error);
    res.status(500).send({ error: 'An error occurred while retrieving the event' });
  }
};


// Add a program item to an event (addProgramItem)
const addProgramItem = async (req, res) => {
  try {
    const { eventId } = req.params;
    const { startTime, endTime, description } = req.body;

    if (!startTime || !endTime || !description) {
      return res.status(400).send({ error: 'Please provide all required fields for the program item' });
    }

    const startMinutes = timeStringToMinutes(startTime);
    const endMinutes = timeStringToMinutes(endTime);

    if (startMinutes >= endMinutes) {
      return res.status(400).send({ error: 'End time must be after start time' });
    }

    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).send({ error: 'Event not found' });
    }

    const isOverlapping = event.program.some(item => {
      const existingStartMinutes = timeStringToMinutes(item.startTime);
      const existingEndMinutes = timeStringToMinutes(item.endTime);
      return (
        startMinutes < existingEndMinutes && endMinutes > existingStartMinutes
      );
    });

    if (isOverlapping) {
      return res.status(400).send({ error: 'The time range overlaps with an existing program item' });
    }

    event.program.push({ startTime, endTime, description });

    // Sort the program items by startTime
    event.program.sort((a, b) => timeStringToMinutes(a.startTime) - timeStringToMinutes(b.startTime));

    await event.save();

    res.status(200).send(event);
  } catch (error) {
    console.error('Error adding program item:', error);
    res.status(500).send({ error: 'An error occurred while adding the program item' });
  }
};

const editProgramItem = async (req, res) => {
  try {
    const { eventId, itemId } = req.params;
    const { startTime, endTime, description } = req.body;

    if (!startTime || !endTime || !description) {
      return res.status(400).send({ error: 'Please provide all required fields for the program item' });
    }

    const startMinutes = timeStringToMinutes(startTime);
    const endMinutes = timeStringToMinutes(endTime);

    if (startMinutes >= endMinutes) {
      return res.status(400).send({ error: 'End time must be after start time' });
    }

    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).send({ error: 'Event not found' });
    }

    event.program = event.program.filter(
      (item) =>
        !(
          startMinutes >= timeStringToMinutes(item.startTime) && startMinutes < timeStringToMinutes(item.endTime) ||
          endMinutes > timeStringToMinutes(item.startTime) && endMinutes <= timeStringToMinutes(item.endTime)
        )
    );

    // Remove the program item with the matching itemId to avoid duplicates
    event.program = event.program.filter((item) => item._id.toString() !== itemId);

    event.program.push({ _id: itemId, startTime, endTime, description });

    // Sort the program items by startTime
    event.program.sort((a, b) => timeStringToMinutes(a.startTime) - timeStringToMinutes(b.startTime));

    await event.save();

    res.status(200).send(event);
  } catch (error) {
    console.error('Error editing program item:', error);
    res.status(500).send({ error: 'An error occurred while editing the program item' });
  }
};


// Delete an event by ID (deleteEvent)
const deleteEvent = async (req, res) => {
  try {
    const { eventId } = req.params;

    const event = await Event.findByIdAndDelete(eventId);
    if (!event) {
      return res.status(404).send({ error: 'Event not found' });
    }

    res.status(200).send({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).send({ error: 'An error occurred while deleting the event' });
  }
};


// Export the new function along with existing ones
module.exports = {
  setEvent,
  getEvents,
  getEventByDate,
  getEventById,  // Added here
  addProgramItem,
  editProgramItem,
  deleteEvent,
};

