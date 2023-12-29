import React, { useState, useEffect } from 'react';
import config from './config';

const App = () => {
	const [tasks, setTasks] = useState([]);
	console.log('API URL:', config.backendUrl);

	useEffect(() => {
		fetch(`${config.backendUrl}/api/tasks`) // Fetch tasks from the backend
			.then((res) => res.json())
			.then((data) => setTasks(data))
			.catch((error) => console.error('Error:', error));
	}, []);

	return (
		<div>
			<h1>Task Management</h1>
			<h1>`${config.backendUrl}`</h1>
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
