import express from 'express';

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import morgan from "morgan";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const logFilePath = path.join(__dirname, "logs.json");
const logStream = fs.createWriteStream(logFilePath, { flags: "a" });
// Custom JSON logger format
const jsonFormat = (tokens, req, res) => {
	const logEntry = {
		method: tokens.method(req, res),
		url: tokens.url(req, res),
		status: Number(tokens.status(req, res)),
		responseTime: `${tokens["response-time"](req, res)}ms`,
		timestamp: new Date().toISOString(),
		userAgent: req.headers["user-agent"]
	};
	const jsonLog = JSON.stringify(logEntry);
	console.log(jsonLog); // Log to console
	logStream.write(jsonLog + "\n"); // Write to file
	return ""; // Prevent morgan from logging it again
};
// Create logger middleware
const logger = morgan(jsonFormat, { stream: logStream });

const app = express();
const port = 3000;

// Use the logger middleware
app.use(logger);

app.get('/api/healthz', async (req, res) => {
	try {
		res.status(200).json({ icon: "🟢", status: 'healthy' });
	} catch (error) {
		console.error(error);
		res.status(500).json({ error: 'Internal Server Error' });
	}
});

app.get('/api/status', async (req, res) => {
	try {
		res.status(200).json({ icon: "✅", status: 'success' });
	} catch (error) {
		console.error(error);
		res.status(500).json({ error: 'Internal Server Error' });
	}
});

app.get('/api/version', async (req, res) => {
	try {
		res.status(200).json({ icon: "🧭", version: '1.0.0' });
	} catch (error) {
		console.error(error);
		res.status(500).json({ error: 'Internal Server Error' });
	}
});

app.get('/api/users', async (req, res) => {
	try {
		const users = [
			{ id: 1, name: 'John Doe' },
			{ id: 2, name: 'Jane Doe' },
		];
		res.status(200).json(users);
	} catch (error) {
		console.error(error);
		res.status(500).json({ error: 'Internal Server Error' });
	}
});

app.listen(port, () => {
	console.log(`Server running on port ${port}`);
});

export default app;
