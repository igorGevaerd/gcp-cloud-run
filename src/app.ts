import express from "express";

const app = express();

app.get("/", (_req, res) => {
  res.json({ message: "Hello World" });
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

export default app;
