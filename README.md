# GCP Cloud Run API

TypeScript REST API built with Express 5, containerised with Docker, and deployed to GCP Cloud Run via Terraform. Public traffic is routed through GCP API Gateway, which enforces API key authentication on protected routes.

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 22 |
| Framework | Express 5 |
| Language | TypeScript 5 |
| Container | Docker (multi-stage build) |
| Platform | GCP Cloud Run (private) + API Gateway (public) |
| IaC | Terraform ≥ 1.4 · google/google-beta provider ~> 6.0 |
| CI | GitHub Actions · reviewdog |

## Architecture

```
Client
  └── API Gateway (public — enforces API key on protected routes)
        └── Cloud Run (private — only reachable from the gateway)
              └── Express app (:8080)
```

The Cloud Run service has no public invoker — all traffic must go through the API Gateway. The gateway validates the `x-api-key` header before forwarding requests to the protected routes.

## Project Structure

```
.
├── src/
│   ├── index.ts            # entry point — creates server, binds PORT
│   ├── app.ts              # Express app (routes)
│   └── __tests__/
│       └── app.test.ts     # Jest + supertest tests
├── terraform/
│   ├── main.tf             # Cloud Run, Artifact Registry, API Gateway, IAM
│   ├── variables.tf        # project_id, region, service_name, image_tag
│   ├── outputs.tf          # gateway_url, service_url, api_key, image_url, registry_url
│   └── versions.tf         # provider constraints
├── docs/
│   ├── diagram.py          # generates docs/gcp-infrastructure.png
│   └── gcp-infrastructure.png
├── Dockerfile
└── .github/workflows/
    ├── cd.yml              # deploy pipeline (terraform → build → deploy)
    ├── terraform-ci.yml    # plan on PRs touching terraform/
    ├── terraform-approve.yml
    ├── code-review.yml     # tests · ESLint · tsc · Prettier
    └── claude.yml
```

## API Endpoints

| Method | Path | Auth | Response |
|---|---|---|---|
| GET | `/` | None | Styled HTML landing page |
| GET | `/health` | None | `{ "status": "ok" }` |
| GET | `/random-int` | API key | `{ "value": <integer 1–100> }` |
| GET | `/random-name-string` | API key | `{ "name": "<random name>" }` |

**Protected routes** require an `x-api-key` header. Requests without a valid key are rejected by the API Gateway before reaching the service.

```bash
curl -H "x-api-key: <your-key>" https://<gateway_url>/random-int
```

Retrieve the key after deployment:

```bash
terraform -chdir=terraform output -raw api_key
```

## Prerequisites

- Node.js 22+
- Docker
- Terraform ≥ 1.4 (for infrastructure)
- `gcloud` CLI authenticated (for infrastructure)

## Local Development

```bash
npm install

npm run dev          # run with ts-node — no build step required
npm run build        # compile TypeScript → dist/
npm start            # run compiled output from dist/
```

The server reads `PORT` from the environment and defaults to `8080`.

## Testing & Linting

```bash
npm test             # Jest unit tests (ts-jest)
npm run lint         # ESLint
npm run format:check # Prettier check
npx tsc --noEmit     # type-check without emitting files
```

## Docker

```bash
# Build
docker build -t gcp-cloud-run-api .

# Run (mirrors Cloud Run behaviour)
docker run -p 8080:8080 gcp-cloud-run-api
```

The Dockerfile uses a multi-stage build: compiles TypeScript in the builder stage, then copies only `dist/` and production dependencies to the final image.

## Infrastructure (Terraform)

All GCP resources live in `terraform/`. Required variables:

| Variable | Description | Default |
|---|---|---|
| `project_id` | GCP project ID | — |
| `region` | GCP region | `us-central1` |
| `service_name` | Name shared by all resources | `gcp-cloud-run` |
| `image_tag` | Docker image tag to deploy | `latest` |

```bash
cd terraform

terraform init

terraform apply \
  -var="project_id=YOUR_PROJECT_ID" \
  -var="region=us-central1"
```

After `apply`, Terraform prints:

| Output | Description |
|---|---|
| `gateway_url` | **Public entry point** — use this URL for all requests |
| `api_key` | API key for protected routes (sensitive) |
| `service_url` | Internal Cloud Run URL (not publicly accessible) |
| `artifact_registry_repository_url` | Base URL for `docker push` |
| `image_url` | Full image URL currently deployed |

GCP services enabled by Terraform: Cloud Run, Artifact Registry, Cloud Resource Manager, API Gateway, Service Management, Service Control, API Keys.

### Push an image manually

```bash
# Authenticate Docker with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag and push
docker tag gcp-cloud-run-api \
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/gcp-cloud-run/gcp-cloud-run:latest

docker push \
  us-central1-docker.pkg.dev/YOUR_PROJECT_ID/gcp-cloud-run/gcp-cloud-run:latest
```

## CI/CD

**`cd.yml`** — triggered on push to `main`:

1. **Terraform apply** — provisions/updates all GCP infrastructure
2. **Build & push** — Docker image pushed to Artifact Registry (tagged with Git SHA + `latest`)
3. **Deploy** — new image deployed to Cloud Run

**`code-review.yml`** — triggered on all PRs:

1. **Unit tests** — `npm test`
2. **ESLint** — inline PR annotations via reviewdog
3. **Type check** — `tsc --noEmit`
4. **Prettier** — format check

**`terraform-ci.yml`** — triggered on PRs that touch `terraform/`:

1. **Format check** — `terraform fmt -check`
2. **Init** — `terraform init -backend=false`
3. **Validate** — `terraform validate`
4. **Plan** — runs `terraform plan` and posts the output as a PR comment

Required GitHub secrets/variables:

| Name | Type | Description |
|---|---|---|
| `TF_VAR_PROJECT_ID` | Secret | GCP project ID |
| `GCP_SA_KEY` | Secret | Service account key JSON |
| `TF_VAR_REGION` | Variable | GCP region (defaults to `us-central1` if not set) |

## GCP Infrastructure

Resources provisioned by Terraform in `terraform/`. Diagram generated by [`docs/diagram.py`](docs/diagram.py).

![GCP Infrastructure](docs/gcp-infrastructure.png)
