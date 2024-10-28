const express = require('express');
const http = require('http');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const socketHandler = require('./socket');
const morgan = require('morgan');
const helmet = require('helmet');

// Initialize environment variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Use middleware
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

// Define routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/bookmarks', require('./routes/bookmarks'));
app.use('/api/highlights', require('./routes/highlights'));
app.use('/api/users', require('./routes/users'));
app.use('/api/groups', require('./routes/groups'));
app.use('/api/direct', require('./routes/directMessages'));
app.use('/api/events', require('./routes/events'));
app.use('/api/services', require('./routes/services'));
app.use('/api/sermons', require('./routes/sermons'));
app.use('/api/devotions', require('./routes/devotions'));
app.use('/api/scriptures', require('./routes/scriptures'));
app.use('/api/images', require('./routes/images'));




// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Handle socket connections
socketHandler(io);

// Centralized error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        message: err.message || 'Internal Server Error',
        status: err.status || 500
    });
});

// Start the server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));