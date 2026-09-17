# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 -- build the React/Vite SPA to static dist/
# ============================================================
FROM node:22-alpine AS build
WORKDIR /app

COPY EventNest-UI/package.json EventNest-UI/package-lock.json ./
RUN npm ci

COPY EventNest-UI/ .
RUN npm run build

# ============================================================
# Stage 2 -- serve the SPA with nginx and reverse-proxy /api
# ============================================================
FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
