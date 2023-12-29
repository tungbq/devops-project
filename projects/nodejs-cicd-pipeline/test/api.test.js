// api.test.js

const request = require('supertest');
const { app, pool } = require('../app'); // Replace with your actual setup

describe('API Routes', () => {
	let server;

	beforeAll(() => {
		server = app.listen(3000); // Use a test-specific port or other strategies
	});

	afterAll((done) => {
		server.close(done);
	});

	describe('GET /api/tasks', () => {
		it('should return tasks from the database', async () => {
			// Mock the database query response
			const mockData = [
				{ id: 1, task: 'Task 1' },
				{ id: 2, task: 'Task 2' },
			];
			const mockQuery = jest.fn().mockResolvedValue({ rows: mockData });
			pool.query = mockQuery;

			// Perform a request to your endpoint
			const response = await request(app).get('/api/tasks');

			expect(response.status).toBe(200);
			expect(response.body).toEqual(mockData);
		});

		it('should handle server errors', async () => {
			// Mock the database query to throw an error
			const mockQueryError = jest
				.fn()
				.mockRejectedValue(new Error('Database error'));
			pool.query = mockQueryError;

			// Perform a request to your endpoint
			const response = await request(app).get('/api/tasks');

			expect(response.status).toBe(500);
			expect(response.body).toEqual({ error: 'Server error `Database error`' });
		});
	});

	// Add similar test blocks for other CRUD operations
});
