
const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const AUTH_URL = process.env.AUTH_URL || 'http://auth:4000';
const BOOKS_URL = process.env.BOOKS_URL || 'http://books:5000';

app.get('/health', (_, res) => res.json({ status: 'ok', service: 'gateway' }));

app.post('/login', async (req, res) => {
  const r = await axios.post(`${AUTH_URL}/login`, req.body);
  res.json(r.data);
});

app.get('/books', async (_, res) => {
  const r = await axios.get(`${BOOKS_URL}/books`);
  res.json(r.data);
});

app.post('/books', async (req, res) => {
  const r = await axios.post(`${BOOKS_URL}/books`, req.body);
  res.json(r.data);
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log('Gateway on', port));
