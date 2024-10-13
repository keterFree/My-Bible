const timeout = require('connect-timeout'); // Import the timeout middleware
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const twilio = require('twilio');

// Initialize Twilio client
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
const client = twilio(accountSid, authToken);

// Middleware to handle timeout errors
function haltOnTimedOut(req, res, next) {
    if (!req.timedout) next();
}

// Register a new user
exports.register = [
    timeout('20s'), // Set a 20-second timeout
    async (req, res, next) => {
        const { name, phone, password } = req.body;
        try {
            let user = await User.findOne({ phone });
            if (user) {
                return res.status(400).json({ msg: 'User already exists' });
            }
            user = new User({ name, phone, password });
            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(password, salt);
            await user.save();
            const payload = { user: { id: user.id } };
            jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' }, (err, token) => {
                if (err) throw err;
                res.json({ token });
            });
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];

// Login user
exports.login = [
    timeout('20s'),
    async (req, res, next) => {
        const { phone, password } = req.body;
        try {
            const user = await User.findOne({ phone });
            if (!user) {
                return res.status(400).json({ msg: 'Invalid credentials' });
            }
            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                return res.status(400).json({ msg: 'Invalid credentials' });
            }
            const payload = { user: { id: user.id, name: user.name, phone: user.phone, tier:user.tier} };
            jwt.sign(
                payload,
                process.env.JWT_SECRET,
                { expiresIn: '365d' }, // Token valid for 365 days
                (err, token) => {
                    if (err) throw err;
                    res.json({ token }); // Return the token
                }
            );
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];

// Get all user details
exports.getUserDetails = [
    timeout('20s'),
    async (req, res, next) => {
        try {
            const userId = req.user.id;
            const user = await User.findById(userId).select('-password'); // Exclude password

            if (!user) {
                return res.status(404).json({ msg: 'User not found' });
            }

            res.json(user);
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];

// Update user details
exports.updateUserDetails = [
    timeout('20s'),
    async (req, res, next) => {
        const { name, phone, password, oldPassword } = req.body;
        try {
            const userId = req.user.id;
            let user = await User.findById(userId);

            if (!user) {
                return res.status(404).json({ msg: 'User not found' });
            }

            // If password change is requested, verify the old password first
            if (oldPassword && password) {
                const isMatch = await bcrypt.compare(oldPassword, user.password);
                if (!isMatch) {
                    return res.status(400).json({ msg: 'Old password is incorrect' });
                }

                // Hash and update new password
                const salt = await bcrypt.genSalt(10);
                user.password = await bcrypt.hash(password, salt);
            }

            // Update other fields only if they are provided in the request
            if (name) user.name = name;
            if (phone) user.phone = phone;

            await user.save();
            // Create new JWT token with updated user details
            const payload = { user: { id: user.id, name: user.name, phone: user.phone } };
            jwt.sign(
                payload,
                process.env.JWT_SECRET,
                { expiresIn: '365d' }, // Token valid for 365 days
                (err, token) => {
                    if (err) throw err;
                    res.json({ token, msg: 'User details updated successfully' }); // Return the new token and success message
                }
            );
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];

// Send password reset code via Twilio
exports.sendResetCode = [
    timeout('20s'),
    async (req, res, next) => {
        const { phone } = req.body;
        try {
            let user = await User.findOne({ phone });

            if (!user) {
                return res.status(400).json({ msg: 'User not found' });
            }

            // Generate a reset code (6-digit random number)
            const resetCode = Math.floor(100000 + Math.random() * 900000);

            // Store the reset code hashed in the user object
            user.resetCode = await bcrypt.hash(resetCode.toString(), 10);
            user.resetCodeExpires = Date.now() + 3600000; // Code valid for 1 hour
            await user.save();

            try {
                // Use Twilio to send reset code via SMS
                await client.verify.services(verifyServiceSid)
                    .verifications
                    .create({ to: user.phone, channel: 'sms' });
            } catch (error) {
                console.error("Twilio error: ", error);
                return res.status(500).json({ msg: 'Failed to send reset code' });
            }

            res.json({ msg: 'Reset code sent' });
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];

// Verify reset code and reset password
exports.verifyResetCodeAndResetPassword = [
    timeout('20s'),
    async (req, res, next) => {
        const { phone, resetCode, newPassword } = req.body;

        try {
            let user = await User.findOne({ phone });

            if (!user || !user.resetCodeExpires || user.resetCodeExpires < Date.now()) {
                return res.status(400).json({ msg: 'Invalid or expired reset code' });
            }

            // Check if the reset code matches
            const isMatch = await bcrypt.compare(resetCode, user.resetCode);
            if (!isMatch) {
                return res.status(400).json({ msg: 'Invalid reset code' });
            }

            // Hash new password and update user
            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(newPassword, salt);

            // Clear the reset code fields
            user.resetCode = undefined;
            user.resetCodeExpires = undefined;
            await user.save();

            res.json({ msg: 'Password reset successful' });
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server Error');
        }
    },
    haltOnTimedOut
];
