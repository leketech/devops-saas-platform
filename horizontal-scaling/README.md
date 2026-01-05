# Horizontal Scaling Implementation

This directory contains the configuration and tools for implementing horizontal scaling in the multi-tenant SaaS API.

## Components

### 1. Horizontal Pod Autoscaler (HPA)

The HPA configuration (`hpa.yaml`) scales the multi-tenant API pods based on:

- **CPU utilization**: Scales when average CPU usage exceeds 70%
- **Latency metrics**: Scales based on HTTP request duration (p95 > 500ms)
- **Scaling behavior**: Configured with stabilization windows to prevent flapping

### 2. Cluster Autoscaler

The cluster autoscaler (`cluster-autoscaler.yaml`) automatically adds/removes worker nodes based on:

- Pending pods that can't be scheduled due to resource constraints
- Node utilization thresholds
- Time-based scaling policies

### 3. Prometheus Metrics

The API exposes Prometheus metrics for latency tracking:

- `http_request_duration_seconds`: Histogram of request durations
- `http_requests_total`: Count of total requests
- `http_active_requests`: Current active requests gauge

### 4. Load Testing

The k6 load test (`api-load-test.js`) simulates traffic ramp-up from 10 to 1,000 concurrent users:

- **Ramp-up phases**: Gradually increases load over 10 minutes
- **Test endpoints**: Health check, data retrieval, and user creation
- **Thresholds**: 
  - <1% error rate
  - 95% of requests <500ms
  - 99% of requests <1000ms

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   k6 Load Test  │───▶│  API Endpoints   │───▶│  Multi-Tenant   │
│   (10-1000 u)   │    │   (Metrics)      │    │      API        │
└─────────────────┘    └──────────────────┘    ├─────────────────┤
                                              │  HPA (CPU/Lat)  │
                                              ├─────────────────┤
                                              │  Prometheus     │
                                              │  (Metrics)      │
                                              └─────────────────┘
                                                      │
                                                      ▼
                                              ┌─────────────────┐
                                              │ Cluster         │
                                              │ Autoscaler      │
                                              └─────────────────┘
                                                      │
                                                      ▼
                                              ┌─────────────────┐
                                              │ Worker Nodes    │
                                              │ (Auto-scaled)   │
                                              └─────────────────┘
```

## Verification Steps

1. **Deploy the configuration**:
   ```bash
   kubectl apply -f hpa.yaml
   kubectl apply -f cluster-autoscaler.yaml
   kubectl apply -f prometheus-configuration.yaml
   ```

2. **Run the load test**:
   ```bash
   k6 run api-load-test.js
   ```

3. **Monitor scaling**:
   ```bash
   # Monitor HPA
   kubectl get hpa -n platform -w
   
   # Monitor pods
   kubectl get pods -n platform -w
   
   # Monitor nodes
   kubectl get nodes -w
   
   # Monitor metrics
   kubectl top pods -n platform
   ```

## Expected Behavior

During the load test:
- As CPU usage exceeds 70% or latency increases, HPA scales up pods
- As more pods are scheduled, cluster autoscaler may add nodes
- Response times should remain stable despite increased load
- Error rates should stay below 1%

## Scaling Policies

### HPA Scaling Behavior
- **Scale-up**: Can double the number of pods within 60 seconds
- **Scale-down**: Conservative scaling down (10% decrease max per minute)
- **Stabilization**: Prevents rapid scaling fluctuations

### Cluster Autoscaler Configuration
- **Scale-up delay**: 10 minutes after pod becomes unschedulable
- **Scale-down delay**: 10 minutes after node utilization drops
- **Threshold**: 70% utilization before scaling down

## Monitoring and Observability

- Prometheus metrics endpoint: `/metrics`
- HPA status: `kubectl describe hpa multitenant-api-hpa -n platform`
- Pod metrics: `kubectl top pods -n platform`
- Node metrics: `kubectl top nodes`