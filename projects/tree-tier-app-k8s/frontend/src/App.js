import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
	const [data, setData] = useState('');

	useEffect(() => {
		fetchData();
	}, []);

	const fetchData = async () => {
		try {
			const response = await fetch('/api/data');
			const jsonData = await response.json();
			setData(jsonData.message);
		} catch (error) {
			console.error('Error fetching data:', error);
		}
	};

	return (
		<div className='App'>
			<header className='App-header'>
				<h1>React App</h1>
				<p>Data from Node.js Backend:</p>
				<p>{data}</p>
			</header>
		</div>
	);
}

export default App;
