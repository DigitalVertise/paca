# syntax=docker/dockerfile:1
#
# Root Dockerfile used by the Render "paca" web service (dockerfilePath ./Dockerfile,
# dockerContext .). It builds the Go API from services/api — identical to
# services/api/Dockerfile, with paths prefixed for the repo-root build context.
# Render only builds from the repo root, so this file must stay in sync with
# services/api/Dockerfile.

# ── Build stage ──────────────────────────────────────────────────────────────
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS builder

WORKDIR /build

COPY services/api/go.mod services/api/go.sum ./
RUN go mod download

COPY services/api/ .

ARG TARGETOS
ARG TARGETARCH

ARG GOMAXPROCS=1
ARG GOMEMLIMIT=768MiB
ARG GOBUILD_P=1
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOMAXPROCS=$GOMAXPROCS GOMEMLIMIT=$GOMEMLIMIT \
	go build -p=$GOBUILD_P -ldflags="-s -w" -o api ./cmd/api

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM alpine:3.21

ARG PACA_VERSION=dev
ENV PACA_VERSION=$PACA_VERSION

RUN apk add --no-cache ca-certificates tzdata su-exec

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder /build/api .

COPY services/api/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN chown app:app /app/api

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["./api"]
