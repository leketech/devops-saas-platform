# Cost Controls & Operations

This document outlines the cost control mechanisms implemented for the multi-tenant SaaS platform to optimize resource usage and manage expenses.

## Cost Control Strategies

### 1. Spot Instances

#### Implementation
- Use AWS EC2 Spot Instances for non-critical workloads
- Configure EKS node groups with mixed instance types (On-Demand + Spot)
- Implement graceful handling of spot instance interruptions

#### Configuration
- Spot allocation strategy: diversified across multiple instance types
- Spot instance interruption handling with node drain and pod rescheduling
- Fallback to On-Demand instances when Spot capacity is unavailable

#### Benefits
- Up to 90% cost savings compared to On-Demand instances
- Maintains service availability through proper interruption handling
- Optimal for stateless applications like the multi-tenant API

### 2. Rightsizing

#### Resource Optimization
- Implement proper resource requests and limits for all containers
- Use Vertical Pod Autoscaler (VPA) to recommend optimal resource allocation
- Regular monitoring and adjustment based on actual usage patterns

#### Monitoring
- Track resource utilization metrics (CPU, memory) over time
- Identify over-provisioned and under-provisioned resources
- Set up alerts for resource usage anomalies

#### Automation
- Use Kubernetes Resource Quotas to prevent resource wastage
- Implement Horizontal Pod Autoscaler (HPA) for demand-based scaling
- Configure Pod Disruption Budgets (PDB) for availability during scaling

### 3. Budget Alerts

#### AWS Budgets Configuration
- Set up monthly cost budgets with alert thresholds (80%, 90%, 100% of budget)
- Configure real-time spending alerts via SNS notifications
- Implement budget tracking by service and application tags

#### Cost Allocation
- Use AWS resource tagging strategy for cost tracking:
  - `Environment`: dev, staging, prod
  - `Application`: multitenant-api, database, cache
  - `Team`: platform-team
  - `Project`: saas-platform
  - `Owner`: contact person for the resource

#### Alerting
- Configure budget alerts to be sent to finance and engineering teams
- Set up cost anomaly detection using AWS Cost Explorer
- Implement cost reporting and dashboards for visibility

### 4. Resource Quotas

#### Kubernetes Resource Quotas
- Limit total resource consumption per namespace
- Control the number of objects (pods, services, etc.) in each namespace
- Prevent individual tenants from consuming excessive resources

#### AWS Service Quotas
- Monitor and manage service limits (EC2 instances, EBS volumes, etc.)
- Request quota increases proactively based on growth projections
- Set up quota utilization alerts

## Implementation Details

### Spot Instance Configuration

#### EKS Node Group with Spot Instances
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-config
  namespace: kube-system
data:
  expander: least-waste
  balance-similar-node-groups: true
  scale-down-enabled: true
  scale-down-delay-after-add: 10m
  scale-down-unneeded-time: 10m
  scale-down-utilization-threshold: 0.7
  skip-nodes-with-local-storage: false
  skip-nodes-with-system-pods: false
```

#### Spot Interruption Handler
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: spot-interruption-handler
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: spot-interruption-handler
  template:
    metadata:
      labels:
        app: spot-interruption-handler
    spec:
      hostNetwork: true
      hostPID: true
      nodeSelector:
        lifecycle: Ec2Spot
      tolerations:
      - key: "lifecycle"
        operator: "Equal"
        value: "Ec2Spot"
        effect: "NoSchedule"
      containers:
      - name: spot-handler
        image: amazonlinux:2
        command:
        - sh
        - -c
        - |
          #!/bin/bash
          # Check for spot interruption notice
          while true; do
            if curl -f http://169.254.169.254/latest/meta-data/spot/instance-action; then
              echo "Spot interruption notice received, draining node..."
              kubectl cordon $(hostname)
              kubectl drain $(hostname) --ignore-daemonsets --delete-local-data
            fi
            sleep 5
          done
        securityContext:
          privileged: true
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

### Rightsizing Configuration

#### Vertical Pod Autoscaler (VPA)
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: multitenant-api-vpa
  namespace: platform
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: multitenant-api
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: api
      maxAllowed:
        cpu: 500m
        memory: 512Mi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

#### Resource Quotas
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: platform
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "50"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: platform
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
```

### Budget Alert Configuration

#### AWS Budgets (via Terraform)
```hcl
resource "aws_budgets_budget" "saas_platform_monthly" {
  name              = "saas-platform-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "5000.0"  # $5,000 USD monthly budget
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["finance@company.com", "engineering@company.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["finance@company.com", "engineering@company.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@company.com", "engineering@company.com"]
  }
}
```

## Cost Optimization Metrics

### Key Metrics to Track
- Cost per request
- Cost per tenant
- Resource utilization efficiency
- Spot instance savings percentage
- Rightsizing opportunities

### Monitoring Dashboard
- Real-time cost visualization
- Cost trend analysis
- Budget vs actual spending
- Resource utilization reports

## Best Practices

1. **Regular Reviews**: Monthly cost optimization reviews
2. **Resource Tagging**: Consistent tagging for cost allocation
3. **Right-sizing**: Regular analysis of resource usage
4. **Automation**: Automated cost controls and alerts
5. **Monitoring**: Continuous cost and usage monitoring
6. **Optimization**: Proactive identification of cost-saving opportunities