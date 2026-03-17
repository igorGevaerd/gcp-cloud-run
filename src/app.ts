import express, { Request, Response, NextFunction } from "express";
import { readFileSync } from "fs";
import { join } from "path";

const landingPage = readFileSync(
  join(__dirname, "views", "landing.html"),
  "utf8",
);

function log(
  level: "INFO" | "WARNING" | "ERROR",
  message: string,
  extra?: Record<string, unknown>,
) {
  console.log(JSON.stringify({ severity: level, message, ...extra }));
}

const app = express();

app.use((req: Request, res: Response, next: NextFunction) => {
  res.on("finish", () => {
    log("INFO", "request", {
      method: req.method,
      path: req.path,
      status: res.statusCode,
    });
  });
  next();
});

app.get("/", (_req, res) => {
  res.send(landingPage);
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/random-int", (_req, res) => {
  res.json({ value: Math.floor(Math.random() * 100) + 1 });
});

const NAMES = [
  "Alice",
  "Bob",
  "Carol",
  "David",
  "Emma",
  "Frank",
  "Grace",
  "Henry",
  "Isabel",
  "James",
  "Karen",
  "Liam",
  "Mia",
  "Noah",
  "Olivia",
  "Paul",
  "Quinn",
  "Rachel",
  "Sam",
  "Tara",
  "Uma",
  "Victor",
  "Wendy",
  "Xander",
  "Yara",
  "Zoe",
];

app.get("/random-name-string", (_req, res) => {
  res.json({ name: NAMES[Math.floor(Math.random() * NAMES.length)] });
});

export default app;
