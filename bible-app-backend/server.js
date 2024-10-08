const express = require('express');
const http = require('http');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const socketHandler = require('./socket');

// Initialize environment variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Use middleware
app.use(cors());
app.use(express.json());

// Define routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/bookmarks', require('./routes/bookmarks'));
app.use('/api/highlights', require('./routes/highlights'));
app.use('/api/users', require('./routes/users')); // Use user routes under /api/usersconst 
app.use('/api/groups', require('./routes/groups')); // Use group routes under /api/groupsconst 
app.use('/api/direct', require('./routes/directMessages'));

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Handle socket connections
socketHandler(io);

// Start the server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
