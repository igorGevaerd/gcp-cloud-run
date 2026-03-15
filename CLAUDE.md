# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev    # run locally with ts-node (no build step)
npm run build  # compile TypeScript to dist/
npm start      # run compiled output
```

## Architecture

Express API written in TypeScript, deployed to GCP Cloud Run.

- **Entry point:** `src/index.ts` — creates the Express app and starts the server
- **Port:** reads from `PORT` env var (defaults to `8080`, which is Cloud Run's default)
- **Build output:** `dist/` (compiled from `src/` via `tsc`)

The Dockerfile uses a multi-stage build: compiles TypeScript in the builder stage, then copies only the compiled output and production dependencies to the final image.
