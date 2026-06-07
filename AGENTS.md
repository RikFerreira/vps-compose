# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This repo is responsible for deploying a VPS stack. The deployment is managed by GitHub Actions. All the services are managed independently in git repos. This repo is responsible for deploying the stack. The services are described in `docker-compose.yaml`. The service `nginx` is a reverse proxy that manages the network. All other services are Docker containers in external git repos. All external services must be accessible in this repo.

All external services described in `docker-compose.yaml` are developed in their own repos. They appear here as git submodules.

All imediate submodules in `services/` directory must be updated to the latest remote commit.

All grandson submodules are part of the development of each service. The development of their services is responsible for their own updates. This repo must not update all second-level and greater grandson submodules.

Refer to docker-compose.yaml and mentioned files for networking and service configuration.

### Basic CI workflow

1. Download all the submodules (recursively) (specific directories/services must not be hardcoded)
2. Update all the imediate submodules under `services/` to the latest remote commit

DO NOT UPDATE ALL GRANDSON SUBMODULES

## Services

At this moment, the services deployed are

- **nginx** — Public-facing reverse proxy. Bridges the `public` and `private` networks. Config lives in `nginx/nginx.conf` and `nginx/servers.conf`. Currently proxies `rikalves.com → blog:80`.
- **blog** — Hugo static site, built from `services/rikalves` (git submodule). Multi-stage Docker build: Hugo generates into `/src/public/`, then nginx:alpine serves it.
- **postgis** — `kartoza/postgis` (ARM64). On the `private` network only. Credentials via `.env` (never committed). Not currently wired to the blog — available for future geospatial features.

Networks: `public` (nginx only) and `private` (blog + postgis + nginx). The blog container is never directly exposed.

## Submodule Structure

```
vps-compose/
└── services/rikalves          ← tracked at latest remote (--remote on deploy)
    └── themes/ananke          ← grandson submodule; pinned version, do NOT --remote
```

Deployment always updates `services/rikalves` to its latest remote commit. Grandson submodules (e.g. `themes/ananke`) are only synced/inited — their pinned version recorded in `services/rikalves` is preserved.

## CI/CD

`.github/workflows/vps-deploy.yaml` triggers on push to `main` and runs on the self-hosted runner:
1. Checkout repo
2. Sync + update submodules (see policy above)
3. `docker compose up -d --build --force-recreate`

There is no staging environment — every push to `main` redeploys production.
