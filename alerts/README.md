# Alerting System

This directory contains the configuration and tools for implementing alerting in the multi-tenant SaaS API.

## Components

### 1. Prometheus Alert Rules

The system includes pre-configured alert rules for critical scenarios:

#### API Alerts
- **APIHigh5xxErrorRate**: Alerts when more than 5% of requests result in 5xx errors
- **APILatencyHigh**: Alerts when 95th percentile of API latency exceeds 1 second
- **PodNotReady**: Alerts when pods remain not ready for more than 5 minutes

#### Infrastructure Alerts
- **PodCrashLooping**: Alerts when pods restart more than 3 times in 10 minutes
- **HighCPUUsage**: Alerts when CPU usage exceeds 80%
- **HighMemoryUsage**: Alerts when memory usage exceeds 85%

#### Database Alerts
- **DBConnectionsExhausted**: Alerts when more than 90% of database connections are in use

### 2. Alertmanager Configuration

The Alertmanager handles alert routing and grouping with:

- Different notification channels for critical, warning, and default alerts
- Grouping by alert name, severity, and category
- Configurable repeat intervals to avoid alert spam
- Webhook and email notification support

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Prometheus    │───▶│  Alertmanager    │───▶│   Notification  │
│   (Rules)       │    │  (Routing)       │    │   Channels      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
       │                        │                        │
       ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Metrics       │    │   Alerts         │    │   Webhooks/     │
│   (Collection)  │    │   (Processing)   │    │   Email         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Configuration Files

### Alert Rules
- `alert-rules.yaml` - Contains all Prometheus alert rule definitions
- Covers API, infrastructure, and database scenarios

### Alertmanager
- `alertmanager-config.yaml` - Configuration for alert routing and grouping
- `alertmanager-deployment.yaml` - Kubernetes deployment for Alertmanager

## Alert Details

### 5xx Error Spike Alert
- **Name**: APIHigh5xxErrorRate
- **Condition**: More than 5% of requests result in 5xx errors
- **Duration**: Alert fires after 2 minutes of sustained high error rate
- **Severity**: Critical
- **Labels**: severity=critical, category=api

### Pod Crash Loop Alert
- **Name**: PodCrashLooping
- **Condition**: Pod restarts more than 3 times in 10 minutes
- **Duration**: Alert fires after 5 minutes of sustained restarts
- **Severity**: Warning
- **Labels**: severity=warning, category=infrastructure

### DB Connections Exhausted Alert
- **Name**: DBConnectionsExhausted
- **Condition**: More than 90% of database connections are in use
- **Duration**: Alert fires after 3 minutes of sustained high usage
- **Severity**: Critical
- **Labels**: severity=critical, category=database

## Deployment

1. **Deploy the alerting configuration**:
   ```bash
   kubectl apply -f alert-rules.yaml
   kubectl apply -f alertmanager-config.yaml
   kubectl apply -f alertmanager-deployment.yaml
   ```

2. **Configure Prometheus** to use the alert rules from the ConfigMap

3. **Set up notification endpoints** for webhooks and email

## Alert Management

### Grouping
- Alerts are grouped by alert name, severity, and category
- Critical alerts have shorter group wait times (10s vs 30s)
- Different repeat intervals based on severity

### Routing
- Critical alerts sent to critical webhook endpoint
- Warning alerts sent to warning webhook endpoint
- Default alerts sent to general webhook endpoint
- Email notifications available as backup

## Customization

The alert rules can be customized by modifying the expressions and thresholds in `alert-rules.yaml` to match your specific requirements.