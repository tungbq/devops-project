import React, { useState, useEffect } from 'react';

const App = () => {
	const [tasks, setTasks] = useState([]);

	useEffect(() => {
		fetch('process.env.REACT_APP_API_URL' + '/api/tasks') // Fetch tasks from the backend
			.then((res) => res.json())
			.then((data) => setTasks(data))
			.catch((error) => console.error('Error:', error));
	}, []);

	return (
		<div>
			<h1>Task Management</h1>
			<ul>
				{tasks.map((task) => (
					<li key={task.id}>{task.title}</li>
					// Other task details rendering...
				))}
			</ul>
		</div>
	);
};

export default App;
