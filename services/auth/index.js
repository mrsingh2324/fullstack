
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_, res) => res.json({ status: 'ok', service: 'auth' }));

app.post('/login', (req, res) => {
  const { username } = req.body || {};
  if (!username) return res.status(400).json({ error: 'username required' });
  // dummy token
  res.json({ token: Buffer.from(username).toString('base64') });
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log('Auth service on', port));
