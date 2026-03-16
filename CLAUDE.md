# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev          # run locally with ts-node (no build step)
npm run build        # compile TypeScript to dist/
npm start            # run compiled output
npm test             # run Jest test suite
npm run lint         # ESLint over src/**/*.ts
npm run format:check # Prettier check over src/**/*.ts
```

## Architecture

Express 5 API written in TypeScript on Node.js 22, deployed to GCP Cloud Run.

### Source layout

- **`src/app.ts`** — creates the Express app and defines all routes; exported for use by tests
- **`src/index.ts`** — imports the app and starts the HTTP server (reads `PORT` env var, defaults to `8080`)
- **`src/__tests__/app.test.ts`** — Jest + supertest tests that import `app.ts` directly (no server needed)
- **Build output:** `dist/` (compiled from `src/` via `tsc`)

The Dockerfile uses a multi-stage build: compiles TypeScript in the builder stage, then copies only the compiled output and production dependencies to the final image.

### Routes

| Method | Path | Response |
|--------|------|----------|
| GET | `/` | Styled HTML landing page |
| GET | `/health` | `{ "status": "ok" }` (JSON) |
| GET | `/random-int` | `{ "value": <integer 1–100> }` (JSON) | requires `x-api-key` header |
| GET | `/random-name-string` | `{ "name": "<random name>" }` (JSON) | requires `x-api-key` header |

## Infrastructure (Terraform)

The `terraform/` directory manages all GCP infrastructure:

- **Artifact Registry** — Docker repository for container images
- **Cloud Run v2 service** — the application runtime (0–10 instances, 1 CPU / 512 MB); **private** (no `allUsers` invoker)
- **API Gateway** — public entry point in front of Cloud Run; enforces API key auth on protected routes
- **Service accounts** — one for the Cloud Run app, one for the API Gateway to invoke Cloud Run
- **API key** (`google_apikeys_key`) — restricted to the managed service; retrieve after apply with `terraform output -raw api_key`
- **API enablement** — Cloud Run, Artifact Registry, Cloud Resource Manager, API Gateway, Service Management, Service Control, API Keys

Key variables: `project_id`, `region` (default `us-central1`), `service_name` (default `gcp-cloud-run`).

After `terraform apply`, use `gateway_url` (not `service_url`) for all public traffic. The Cloud Run URL is internal only.

## CI/CD

Push to `main` triggers the CD pipeline (`.github/workflows/cd.yml`) with three sequential jobs:

1. **Terraform Apply** — provisions/updates GCP infra
2. **Build & Push** — builds the Docker image and pushes to Artifact Registry tagged with the Git SHA and `latest`
3. **Deploy to Cloud Run** — deploys the SHA-tagged image via `google-github-actions/deploy-cloudrun`

Other workflows: `terraform-ci.yml` (plan on PRs), `terraform-approve.yml`, `code-review.yml`, `claude.yml`.
