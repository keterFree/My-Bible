const Event = require('../models/Event');
const mongoose = require('mongoose');

// Create a new event (setEvent)
const setEvent = async (req, res) => {
  try {
    const {
      title, description, theme, date, time, venue, keyGuests, program
    } = req.body;
    const planners = [req.user.id];
    
    // Validate that all required fields are provided
    if (!title || !description || !date || !time || !venue) {
      return res.status(400).send({ error: 'Please provide all required fields' });
    }

    // Create a new event document
    const newEvent = new Event({
      title,
      description,
      theme,
      date,
      time,
      venue,
      keyGuests,
      planners,
      program
    });

    // Save the event to the database
    await newEvent.save();

    res.status(201).send(newEvent); // Return the created event
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).send({ error: 'An error occurred while creating the event' });
  }
};

// Retrieve all events (getEvents)
const getEvents = async (req, res) => {
  try {
    const events = await Event.find()
      .populate('planners', 'name') // Populate planners with their name
      .sort({ date: 1 }); // Sort events by date

    res.status(200).send(events); // Return the list of events
  } catch (error) {
    console.error('Error retrieving events:', error);
    res.status(500).send({ error: 'An error occurred while retrieving the events' });
  }
};

// Retrieve an event by date (getEventByDate)
const getEventByDate = async (req, res) => {
  try {
    const { date } = req.params;

    // Find the event by the provided date
    const event = await Event.findOne({ date })
      .populate('planners', 'name') // Populate planners with their name
      .exec();

    if (!event) {
      return res.status(404).send({ error: 'No event found for this date' });
    }

    res.status(200).send(event); // Return the event details
  } catch (error) {
    console.error('Error retrieving event:', error);
    res.status(500).send({ error: 'An error occurred while retrieving the event' });
  }
};

// Add a program item to an event (addProgramItem)
const addProgramItem = async (req, res) => {
  try {
    const { eventId } = req.params;
    const { startTime, endTime, description } = req.body;

    // Validate the required fields for the program item
    if (!startTime || !endTime || !description) {
      return res.status(400).send({ error: 'Please provide all required fields for the program item' });
    }

    // Find the event by its ID
    const event = await Event.findById(eventId);
    if (!event) {
      return res.status(404).send({ error: 'Event not found' });
    }

    // Add the new program item to the program array
    event.program.push({ startTime, endTime, description });

    // Save the updated event
    await event.save();

    res.status(200).send(event); // Return the updated event
  } catch (error) {
    console.error('Error adding program item:', error);
    res.status(500).send({ error: 'An error occurred while adding the program item' });
  }
};

module.exports = {
  setEvent,
  getEvents,
  getEventByDate,
  addProgramItem
};
