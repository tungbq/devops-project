const express = require('express');
const cors = require('cors'); // For handling CORS (Cross-Origin Resource Sharing)
const app = express();

app.use(cors());

app.get('/api/data', (req, res) => {
	res.json({ message: 'Hello from the Node.js backend!' });
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
	console.log(`Server is running on port ${PORT}`);
});
