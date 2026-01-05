# Multi-stage build for the Multi-Tenant API

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o multitenant-api .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates
RUN addgroup -g 65532 nonroot && adduser -D -u 65532 -G nonroot nonroot

WORKDIR /root/

COPY --from=builder /app/multitenant-api .
# Copy config directory if it exists
RUN mkdir -p /root/config
# The config directory may not exist, so we don't fail if it doesn't

RUN chmod +x ./multitenant-api

# Create non-root user
USER nonroot

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./multitenant-api"]