# Metrics and Logging Implementation

This directory contains the configuration and tools for implementing metrics and logging in the multi-tenant SaaS API.

## Components

### 1. Prometheus Metrics

The API exposes the following metrics:

#### RED Metrics (Rate, Error, Duration)
- **Rate**: `http_requests_total` - Total number of HTTP requests by path, method, and status
- **Error**: `http_requests_errors_total` - Total number of HTTP request errors by path, method, status, and tenant_id
- **Duration**: `http_request_duration_seconds` - Histogram of HTTP request durations

#### Additional Metrics
- `http_active_requests` - Current number of active HTTP requests
- `db_connections` - Database connection pool metrics
- `redis_operations_total` - Total Redis operations by operation type and status

### 2. Loki and Promtail for Log Aggregation

#### Loki
- Centralized log storage
- Configured to store logs from multi-tenant API containers
- Provides efficient log querying and visualization

#### Promtail
- Log collector that runs as a DaemonSet on each node
- Collects logs from container files and forwards to Loki
- Configured with pipeline stages to extract structured data

#### Structured Logging
- All logs include tenant_id for multi-tenancy isolation
- Logs are formatted as JSON for easy parsing
- Log levels (info, error, warn) are properly labeled

### 3. Grafana Dashboards

#### RED Dashboard
- Request Rate: Total requests per second
- Request Duration: 95th percentile response times
- Error Rate: Percentage of failed requests
- Active Requests: Current active requests
- API Requests by Tenant: Traffic distribution across tenants
- Pod Count: Current deployment replica count

#### Node Dashboard
- Node resource utilization
- Pod resource consumption
- Node health status

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Service   │───▶│  Prometheus      │───▶│   Grafana       │
│   (Metrics)     │    │  (Collection)    │    │   (Visualization)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
       │                        │                        │
       ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Structured Logs │───▶│   Promtail       │───▶│    Loki         │
│   (JSON)        │    │ (Log Collector)  │    │ (Log Storage)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Configuration Files

### API Changes
- `api/main.go` - Updated with Prometheus metrics collection
- `api/go.mod` - Added required dependencies (prometheus, zap logger)

### Metrics Stack
- `loki-config.yaml` - Loki configuration
- `promtail-config.yaml` - Promtail configuration
- `loki-deployment.yaml` - Loki deployment manifest
- `promtail-daemonset.yaml` - Promtail DaemonSet manifest
- `grafana-dashboards.yaml` - Grafana dashboard configuration

## Deployment

1. **Deploy the metrics stack**:
   ```bash
   kubectl apply -f loki-deployment.yaml
   kubectl apply -f promtail-daemonset.yaml
   kubectl apply -f grafana-dashboards.yaml
   ```

2. **Update the API deployment** to include the new metrics endpoints

3. **Access Grafana** to view the dashboards

## Monitoring Queries

### RED Metrics
- **Request Rate**: `sum(rate(http_requests_total[1m]))`
- **Error Rate**: `sum(rate(http_requests_errors_total[1m])) / sum(rate(http_requests_total[1m])) * 100`
- **Duration (P95)**: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1m])) by (le))`

### Tenant-Specific Metrics
- **Requests by Tenant**: `sum by (tenant_id) (rate(http_requests_total[1m]))`
- **Errors by Tenant**: `sum by (tenant_id) (rate(http_requests_errors_total[1m]))`

### Log Queries in Loki
- **All API logs**: `{app="multitenant-api"}`
- **Logs by tenant**: `{app="multitenant-api"} | json | tenant_id="tenant-123"`
- **Error logs**: `{app="multitenant-api"} |= "error"`
- **Logs by level**: `{app="multitenant-api"} | json | level="error"`

## Security and Isolation

- Tenant IDs are included in all logs for multi-tenancy isolation
- Metrics are labeled by tenant_id to ensure proper isolation
- Access to logs and metrics is controlled by Kubernetes RBAC