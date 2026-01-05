# Multi-stage build for the SaaS Platform application

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY application/ .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o saas-platform-app .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
RUN addgroup -g 65532 nonroot && adduser -D -u 65532 -G nonroot nonroot

WORKDIR /root/

COPY --from=builder /app/saas-platform-app .

RUN chmod +x ./saas-platform-app

# Create non-root user
USER nonroot

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["./saas-platform-app"]