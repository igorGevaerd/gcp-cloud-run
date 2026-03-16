import request from "supertest";
import app from "../app";

describe("GET /", () => {
  it("returns 200 with HTML", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/text\/html/);
    expect(res.text).toContain("Hello World");
  });
});

describe("GET /health", () => {
  it("returns ok status", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });

  it("returns JSON content-type", async () => {
    const res = await request(app).get("/health");
    expect(res.headers["content-type"]).toMatch(/application\/json/);
  });
});

describe("GET /random-int", () => {
  it("returns an integer between 1 and 100", async () => {
    const res = await request(app).get("/random-int");
    expect(res.status).toBe(200);
    expect(res.body.value).toBeGreaterThanOrEqual(1);
    expect(res.body.value).toBeLessThanOrEqual(100);
    expect(Number.isInteger(res.body.value)).toBe(true);
  });
});

describe("GET /random-name-string", () => {
  it("returns a non-empty name string", async () => {
    const res = await request(app).get("/random-name-string");
    expect(res.status).toBe(200);
    expect(typeof res.body.name).toBe("string");
    expect(res.body.name.length).toBeGreaterThan(0);
  });
});

describe("unknown routes", () => {
  it("returns 404", async () => {
    const res = await request(app).get("/not-found");
    expect(res.status).toBe(404);
  });
});
