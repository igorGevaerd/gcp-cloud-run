import express, { Request, Response, NextFunction } from "express";

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
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>GCP Cloud Run</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #0f1117;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      color: #e2e8f0;
    }

    .card {
      text-align: center;
      padding: 3rem 4rem;
      background: #1a1f2e;
      border: 1px solid #2d3748;
      border-radius: 1.5rem;
      box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
      max-width: 480px;
      width: 90%;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
      background: #0d47a1;
      color: #90caf9;
      font-size: 0.75rem;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      padding: 0.3rem 0.75rem;
      border-radius: 999px;
      margin-bottom: 1.5rem;
    }

    .badge::before {
      content: "";
      display: block;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #4fc3f7;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.3; }
    }

    h1 {
      font-size: 2.5rem;
      font-weight: 700;
      background: linear-gradient(135deg, #60a5fa, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 0.75rem;
      line-height: 1.2;
    }

    p {
      color: #718096;
      font-size: 1rem;
      margin-bottom: 2rem;
      line-height: 1.6;
    }

    .pills {
      display: flex;
      gap: 0.5rem;
      justify-content: center;
      flex-wrap: wrap;
    }

    .pill {
      background: #2d3748;
      color: #a0aec0;
      font-size: 0.8rem;
      font-weight: 500;
      padding: 0.35rem 0.85rem;
      border-radius: 999px;
      border: 1px solid #4a5568;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">Cloud Run</div>
    <h1>Hello World</h1>
    <p>Express · TypeScript · GCP</p>
    <div class="pills">
      <span class="pill">Node.js 22</span>
      <span class="pill">Express 5</span>
      <span class="pill">Docker</span>
      <span class="pill">Terraform</span>
    </div>
  </div>
</body>
</html>`);
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
