# EventNest (.NET) — Docker Compose Stack

One-command local stack for the .NET EventNest application: four microservices
(auth, event, tag, rsvp), a YARP API gateway, and the React UI, backed by
PostgreSQL, Redis, and RabbitMQ.

This repository is the **compose bundle** — it only contains the Docker
orchestration. The application sources live in two separate repositories,
cloned next to this file:

```
EventNest-DotNetRec/
├── docker-compose.yml
├── docker/
│   ├── ui.Dockerfile
│   └── nginx.conf
├── EventNest/        (git clone — .NET microservices + gateway)
└── EventNest-UI/     (git clone — React SPA)
```

## Prerequisites

- Docker Desktop (Docker Compose v2)
- Host ports `5000` (API) and `5173` (UI) free

## Quickstart

```powershell
git clone https://github.com/Nikhilesh515/EventNest-DotNetRec.git
cd EventNest-DotNetRec

# Application sources (required — this repo only contains the compose stack)
git clone -b feat/FrontendRequirementChanges/NodeDotNetParity https://github.com/Nikhilesh515/EventNest.git    EventNest
git clone -b feat/LoginRegister/NodeDotNetParity           https://github.com/Nikhilesh515/EventNest-UI.git EventNest-UI

docker compose up --build -d
```

The first build downloads the .NET 10 SDK/runtime images and installs UI
dependencies, so it takes several minutes. Later runs are fast.

Each service applies its EF Core migrations and seeds on startup, so the
database is ready by the time the containers report healthy.

## Services

| Service | URL / Port | Notes |
|---|---|---|
| UI | http://localhost:5173 | nginx-served SPA; reverse-proxies `/api` to the gateway |
| API Gateway | http://localhost:5000 | single API entry point; `/health` aggregates every service check |
| Auth / Event / Tag / RSVP services | internal only | REST 5001–5004, gRPC 51001–51004 on the compose network |
| PostgreSQL | internal only | one server, four databases: `eventnest_auth`, `eventnest_event`, `eventnest_tag`, `eventnest_rsvp` |
| Redis | internal only | permission cache (ephemeral) |
| RabbitMQ | internal only | provisioned for the deferred async-messaging design (no publisher/consumer wired yet) |

Seeded admin account: `admin@eventnest.io` / `Admin@123`.

## Common commands

```powershell
docker compose up --build -d                                      # start in background
docker compose logs -f gateway                                    # follow gateway logs
docker compose ps                                                 # status
docker compose down                                               # stop, keep data
docker compose down -v                                            # stop and wipe database + broker volumes
docker compose exec postgres psql -U postgres -d eventnest_auth   # database shell
```

## Updating the stack

```powershell
git -C EventNest pull
git -C EventNest-UI pull
docker compose up --build -d
```

A plain `docker compose up` reuses existing images; pass `--build` after pulling.

## How it works

- `ui` builds the React app with Vite and serves it from nginx. Requests to
  `/api` are reverse-proxied to `gateway:5000`, so the browser talks to a
  single origin and cookies behave as in production.
- `gateway` is the only published API port. It waits for all four services to
  report healthy before it starts.
- Every service runs EF Core `MigrateAndSeed()` on startup (idempotent). There
  is **no one-shot migrate service** — unlike the Node/Express bundle.
- Infrastructure (PostgreSQL, Redis, RabbitMQ) is never published to the host.

## Configuration

All settings have working defaults. To override, copy `.env.example` to `.env`
next to `docker-compose.yml`:

| Variable | Default | Notes |
|---|---|---|
| `JWT_SECRET_KEY` | local dev secret | Must be at least 32 characters; the backend's placeholder secret is rejected outside Development |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `postgres` / `postgres` | |
| `RABBITMQ_USER` / `RABBITMQ_PASS` | `guest` / `guest` | |
| `CORS_ALLOWED_ORIGIN_0` / `_1` | `http://localhost:5173` / `https://localhost:5173` | |
| `COOKIE_SECURE` | `false` | Set to `true` when serving over HTTPS |
| `ASPNETCORE_ENVIRONMENT` | `Production` | |

## Troubleshooting

- **First build is slow** — it pulls the .NET 10 SDK/runtime images and runs
  `npm ci`; subsequent builds reuse the layer cache.
- **A service exits at startup** — almost always `JWT_SECRET_KEY`: it must be
  at least 32 characters and must not be the placeholder from the backend's
  `appsettings.json`.
- **Port 5000 already in use** — don't run this bundle and the backend
  repository's own `EventNest/docker-compose.yml` at the same time; both
  publish `5000`.
- **Starting over** — `docker compose down -v` deletes the volumes; the four
  databases are recreated and re-seeded on the next start.
- **Refresh cookie** — it defaults to non-`Secure` so login works over local
  HTTP. Set `COOKIE_SECURE=true` when serving behind HTTPS.

Verified against EventNest branch `feat/FrontendRequirementChanges/NodeDotNetParity`
and EventNest-UI branch `feat/LoginRegister/NodeDotNetParity`.
