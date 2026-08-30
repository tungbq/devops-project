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

# Runs as a non-root user, by numeric UID:GID rather than name — node:22-alpine's
# "node" user is 1000:1000, and a numeric ID is what tools like Kubernetes'
# runAsNonRoot pod security check actually need to resolve reliably (hadolint
# DL3066), unlike a username that only resolves via this image's /etc/passwd.
USER 1000:1000

EXPOSE 3000
CMD ["node", "src/index.js"]
