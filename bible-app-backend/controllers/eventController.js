const Event = require('../models/Event');
const mongoose = require('mongoose');

// Create a new event (setEvent)
const setEvent = async (req, res) => {
  try {
    const {
      title, description, theme, date, time, venue, keyGuests, planners, program
    } = req.body;

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

module.exports = {
  setEvent,
  getEvents,
  getEventByDate
};

// {
//     "title": "Church Anniversary",
//     "description": "Celebrating our 10th anniversary",
//     "theme": "Gratitude and Hope",
//     "date": "2024-12-01T09:00:00Z",
//     "time": "09:00 - 17:00",
//     "venue": "Main Church Hall",
//     "keyGuests": ["Bishop John", "Pastor Mary"],
//     "planners": ["605c72ad9e0d5f1e089e9f92", "605c72ad9e0d5f1e089e9f93"],
//     "program": [
//       {
//         "startTime": "09:00",
//         "endTime": "10:00",
//         "description": "Welcoming Remarks"
//       },
//       {
//         "startTime": "10:00",
//         "endTime": "11:00",
//         "description": "Worship"
//       },
//       {
//         "startTime": "11:00",
//         "endTime": "12:00",
//         "description": "Sermon by Bishop John"
//       }
//     ]
//   }
    
  