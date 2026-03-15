import express from 'express';

const app = express();
const port = parseInt(process.env.PORT || '8080');

app.get('/', (_req, res) => {
  res.json({ message: 'Hello World' });
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
