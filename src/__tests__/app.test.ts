import request from "supertest";
import app from "../app";

describe("GET /", () => {
  it("returns Hello World JSON", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ message: "Hello World" });
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

describe("unknown routes", () => {
  it("returns 404", async () => {
    const res = await request(app).get("/not-found");
    expect(res.status).toBe(404);
  });
});
