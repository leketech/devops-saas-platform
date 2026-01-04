# Blue/Green Deployment Strategy

This directory contains the configuration for implementing Blue/Green deployments with canary traffic and auto rollback on SLO breach for the multi-tenant SaaS API.

## Components

### 1. Blue/Green Deployment
- **Rollout Strategy**: Uses Argo Rollouts for Blue/Green deployments
- **Services**: 
  - Active service (blue) - currently serving traffic
  - Preview service (green) - new version for testing
- **Promotion**: Controlled promotion from preview to active
- **Analysis**: Pre and post promotion analysis to validate health

### 2. Canary Traffic
- **Gradual Rollout**: Traffic shifts gradually from 10% to 100%
- **Pause Points**: Built-in pauses to observe metrics at each step
- **Analysis Integration**: Continuous validation during rollout
- **Traffic Splitting**: Configured via service mesh routing

### 3. Auto Rollback on SLO Breach
- **SLO Monitoring**: Success rate, error rate, and latency metrics
- **Threshold Validation**: Configurable thresholds for each metric
- **Automatic Rollback**: Immediate rollback when SLOs are breached
- **Analysis Templates**: Reusable templates for SLO validation

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Traffic       │───▶│  Load Balancer   │───▶│  Active (Blue)  │
│   Ingress       │    │   (Routing)      │    │  Service        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Argo Rollouts   │───▶│  Preview (Green)│
                       │  Controller      │    │  Service        │
                       └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  Analysis       │
                       │  Templates      │
                       └──────────────────┘
```

## Configuration Files

### Blue/Green Deployment
- `blue-green-deployment.yaml`: Argo Rollout with Blue/Green strategy
- Uses active/preview services for traffic switching
- Includes pre/post promotion analysis

### Canary Deployment
- `canary-deployment.yaml`: Argo Rollout with Canary strategy
- Gradual traffic shifting (10% → 25% → 50% → 100%)
- Multiple analysis templates for different metrics

### Auto Rollback Configuration
- `auto-rollback-config.yaml`: SLO-based analysis templates
- Configurable thresholds for error rate, latency, and success rate
- Automatic rollback triggers when SLOs are breached

## SLO Validation

### Success Rate
- **Threshold**: ≥95% successful requests
- **Query**: 1 - (error requests / total requests)
- **Window**: 2-minute rate calculation

### Error Rate
- **Threshold**: <5% error requests
- **Query**: error requests / total requests
- **Window**: 2-minute rate calculation

### Latency
- **Threshold**: <1.0 second (95th percentile)
- **Query**: 95th percentile of request duration
- **Window**: 2-minute rate calculation

## Deployment Process

### Blue/Green Deployment Steps
1. Deploy new version to preview environment
2. Run pre-promotion analysis on preview service
3. If analysis passes, promote preview to active
4. Run post-promotion analysis on active service
5. If analysis fails, rollback to previous version

### Canary Deployment Steps
1. Start with 10% traffic to new version
2. Pause and observe metrics for 2 minutes
3. Gradually increase traffic (25% → 50% → 100%)
4. Run SLO validation at each step
5. If SLOs breached, automatically rollback

## Rollback Triggers

### Automatic Rollback Conditions
- Error rate exceeds threshold (e.g., >5%)
- Success rate falls below threshold (e.g., <95%)
- Latency exceeds threshold (e.g., >1 second p95)
- Health check failures
- Resource exhaustion

### Rollback Process
1. Detection of SLO breach
2. Immediate traffic shift back to stable version
3. Termination of canary/preview deployment
4. Notification of rollback event
5. Post-rollback analysis

## Monitoring and Observability

### Metrics Collection
- Request success/error rates
- Response time percentiles
- Resource utilization
- Health check status

### Alerting
- SLO breach notifications
- Rollback event alerts
- Deployment status updates
- Performance degradation alerts

## Security Considerations

- Service accounts with minimal required permissions
- Network policies restricting traffic between services
- Encrypted communication between services
- Secrets management for configuration

## Best Practices

1. **Testing**: Thorough testing in preview environment before promotion
2. **Monitoring**: Comprehensive metrics collection and analysis
3. **Thresholds**: Carefully chosen SLO thresholds based on business requirements
4. **Observability**: Detailed logging and tracing for debugging
5. **Recovery**: Fast rollback capabilities to minimize downtime impact