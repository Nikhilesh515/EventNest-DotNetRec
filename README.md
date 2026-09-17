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
└── EventNest-UI/     (git clone — React/Vite SPA)
```

## Prerequisites

- Docker Desktop (Docker Compose v2)
- Host ports `5000` and `5173` free

## Getting started

```powershell
git clone https://github.com/Nikhilesh515/EventNest-DotNetRec.git
cd EventNest-DotNetRec

# Application sources (required — this repo only contains the compose stack)
git clone -b feat/FrontendRequirementChanges/NodeDotNetParity https://github.com/Nikhilesh515/EventNest.git    EventNest
git clone -b feat/LoginRegister/NodeDotNetParity           https://github.com/Nikhilesh515/EventNest-UI.git EventNest-UI

docker compose up --build -d
```

The first build downloads the .NET 10 SDK/runtime images and takes a while.
Each service applies its EF Core migrations and seeds on startup, so the
database is ready when the containers report healthy.

## Services

| Service | URL / Port | Notes |
|---|---|---|
| UI | http://localhost:5173 | nginx serves the built SPA and proxies `/api` to the gateway |
| API Gateway | http://localhost:5000 | single API entry point; `/health` aggregates all service checks |
| PostgreSQL | internal only | 4 databases: `eventnest_auth`, `eventnest_event`, `eventnest_tag`, `eventnest_rsvp` |
| Redis | internal only | permission cache (ephemeral) |
| RabbitMQ | internal only | provisioned for the deferred async-messaging design (unused today) |

Seeded admin account: `admin@eventnest.io` / `Admin@123`.

## Commands

```powershell
docker compose up --build -d                                  # start in background
docker compose logs -f gateway                                # follow gateway logs
docker compose ps                                             # status
docker compose down                                           # stop, keep data
docker compose down -v                                        # stop, wipe database + broker volumes
docker compose exec postgres psql -U postgres -d eventnest_auth   # DB shell
```

## Configuration

All settings have working defaults. To override, copy `.env.example` to `.env`
in this directory and edit:

| Variable | Default | Notes |
|---|---|---|
| `JWT_SECRET_KEY` | dev-only secret | Must be at least 32 characters; the backend placeholder is rejected outside Development |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `postgres` / `postgres` | |
| `RABBITMQ_USER` / `RABBITMQ_PASS` | `guest` / `guest` | |
| `CORS_ALLOWED_ORIGIN_0` / `_1` | `http://localhost:5173` / `https://localhost:5173` | |
| `COOKIE_SECURE` | `false` | Set to `true` when serving over HTTPS |
| `ASPNETCORE_ENVIRONMENT` | `Production` | |

## Notes

- Don't run this stack while the backend repository's own
  `EventNest/docker-compose.yml` stack is running — both bind host port `5000`.
- The refresh-token cookie defaults to `Secure=false` so login works over plain
  HTTP on localhost. Behind HTTPS, set `COOKIE_SECURE=true`.
- RabbitMQ is intentionally kept (decision D8) even though no publisher or
  consumer is wired yet.
