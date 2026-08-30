# Multi-stage build so devDependencies (jest, eslint, supertest) never ship
# in the runtime image — keeps the deployed image small and its attack
# surface (and Trivy scan surface) limited to what actually runs in prod.
FROM node:22-alpine AS build
WORKDIR /src
COPY package*.json ./
RUN npm ci
COPY . .

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /src/src ./src

# Build-time metadata surfaced at /  so a deploy's smoke test can confirm it
# is talking to the revision it just shipped, not a stale one.
ARG BUILD_VERSION=dev
ARG BUILD_COMMIT_SHA=unknown
ENV BUILD_VERSION=${BUILD_VERSION}
ENV BUILD_COMMIT_SHA=${BUILD_COMMIT_SHA}

# Runs as a non-root user (node:22-alpine already ships a "node" user) —
# containers should never run as root unless something specifically needs it.
USER node

EXPOSE 3000
CMD ["node", "src/index.js"]
