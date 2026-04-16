
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const MONGO_URI = process.env.MONGO_URI;

const BookSchema = new mongoose.Schema({
  name: String
}, { timestamps: true });

const Book = mongoose.model('Book', BookSchema);

async function connect() {
  if (!MONGO_URI) {
    console.warn('MONGO_URI not set. Running without DB (in-memory responses).');
    return;
  }
  await mongoose.connect(MONGO_URI);
  console.log('Mongo connected');
}

app.get('/health', (_, res) => res.json({ status: 'ok', service: 'books' }));

app.get('/books', async (_, res) => {
  if (!MONGO_URI) return res.json([{ name: "Book1" }, { name: "Book2" }]);
  const books = await Book.find().lean();
  res.json(books);
});

app.post('/books', async (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ error: 'name required' });
  if (!MONGO_URI) return res.json({ name });
  const doc = await Book.create({ name });
  res.json(doc);
});

const port = process.env.PORT || 5000;
connect().then(() => {
  app.listen(port, () => console.log('Books service on', port));
});
