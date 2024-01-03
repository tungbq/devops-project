require('dotenv').config();
const express = require('express');
const app = express();
const { Pool } = require('pg');
require('dotenv').config();

// PostgreSQL database connection setup
const pool = new Pool({
	user: process.env.PGUSER,
	password: process.env.PGPASSWORD,
	database: process.env.PGDATABASE,
	host: process.env.PGHOST || 'localhost',
	port: process.env.PGPORT || 5432,
});

// Define API routes
app.get('/api/tasks', async (req, res) => {
	try {
		const { rows } = await pool.query('SELECT * FROM tasks');
		res.json(rows);
	} catch (error) {
		res.status(500).json({ error: 'Server error `${error}`' });
	}
});

// Other CRUD operations (POST, PUT, DELETE) for tasks

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
	console.log(`Server running on port ${PORT}`);
});

module.exports = { app, pool }; // Export app and other necessary elements
