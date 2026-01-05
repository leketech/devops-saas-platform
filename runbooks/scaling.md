# Scaling Runbook

This runbook provides step-by-step procedures for scaling the multi-tenant SaaS API based on load and performance requirements.

## Scaling Triggers

### Horizontal Pod Autoscaler (HPA) Triggers
- CPU utilization exceeds 70%
- API latency (95th percentile) exceeds 500ms
- Request queue depth exceeds threshold
- Error rate increases significantly

### Manual Scaling Triggers
- Anticipated traffic spikes (e.g., Black Friday, scheduled events)
- Performance degradation during load testing
- Planned maintenance requiring additional capacity
- Cost optimization (downscaling during low-traffic periods)

## Scaling Procedures

### 1. Horizontal Scaling (Pod Scaling)

#### Check Current Status
```bash
# Check HPA status
kubectl get hpa -n platform

# Check current pods
kubectl get pods -n platform -l app=multitenant-api

# Check resource utilization
kubectl top pods -n platform -l app=multitenant-api
```

#### Manual Scaling
```bash
# Scale up deployment
kubectl scale deployment multitenant-api -n platform --replicas=10

# Monitor scaling progress
kubectl get pods -n platform -l app=multitenant-api --watch
```

#### Check Scaling Events
```bash
# Check HPA events
kubectl describe hpa multitenant-api-hpa -n platform

# Check pod events
kubectl get events -n platform --sort-by='.lastTimestamp' | grep multitenant-api
```

### 2. Vertical Scaling (Resource Adjustment)

#### Check Resource Utilization
```bash
# Check current resource requests/limits
kubectl describe deployment multitenant-api -n platform

# Check actual resource usage
kubectl top pods -n platform -l app=multitenant-api

# Check for resource constraints
kubectl describe pods -n platform -l app=multitenant-api | grep -A 5 "Conditions"
```

#### Update Resource Requests/Limits
```bash
# Edit the deployment to adjust resources
kubectl patch deployment multitenant-api -n platform -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"requests":{"cpu":"200m","memory":"256Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]}}}}'
```

### 3. Cluster Autoscaling

#### Check Node Status
```bash
# Check current nodes
kubectl get nodes -L node.kubernetes.io/instance-type,topology.kubernetes.io/zone

# Check node resource utilization
kubectl top nodes

# Check for pending pods
kubectl get pods -n platform -l app=multitenant-api --field-selector=status.phase=Pending
```

#### Verify Cluster Autoscaler
```bash
# Check cluster autoscaler status
kubectl get pods -n kube-system | grep cluster-autoscaler

# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# Check for scale-up events
kubectl get events -n kube-system --field-selector=reason=TriggeredScaleUp
```

## Scaling Verification

### 1. Verify Pod Scaling
```bash
# Check deployment status
kubectl rollout status deployment/multitenant-api -n platform

# Verify pod readiness
kubectl get pods -n platform -l app=multitenant-api -o wide

# Check service endpoints
kubectl get endpoints multitenant-api-service -n platform
```

### 2. Monitor Performance After Scaling
```bash
# Check application metrics
curl -H "Authorization: Bearer <token>" http://api.globepay.space/metrics

# Verify health endpoints
kubectl port-forward -n platform svc/multitenant-api-service 8080:8080 &
curl http://localhost:8080/health
```

### 3. Validate Load Distribution
```bash
# Check if traffic is distributed evenly
kubectl logs -n platform -l app=multitenant-api --tail=100 | grep -c "request processed"

# Check for any pod imbalances
kubectl top pods -n platform -l app=multitenant-api
```

## Emergency Scaling Procedures

### Rapid Scale-Up for Traffic Spikes
```bash
# Immediate scale-up to handle traffic spike
kubectl scale deployment multitenant-api -n platform --replicas=20

# Monitor the scaling
kubectl get pods -n platform -l app=multitenant-api --watch

# Check if additional nodes are needed
kubectl get nodes
```

### Scale-Down for Cost Optimization
```bash
# Gradual scale-down during low-traffic periods
kubectl scale deployment multitenant-api -n platform --replicas=3

# Monitor for any performance degradation
kubectl top pods -n platform -l app=multitenant-api
```

## Multi-Tenant Scaling Considerations

### Tenant-Specific Scaling
```bash
# Monitor per-tenant metrics
kubectl logs -n platform -l app=multitenant-api | grep -E "tenant_id|request" | tail -100

# Check if specific tenants are causing load
kubectl exec -it <pod-name> -n platform -- curl "localhost:8080/metrics" | grep -E "tenant|request"
```

### Resource Isolation
```bash
# Verify resource quotas are not exceeded
kubectl describe resourcequota -n platform

# Check limit ranges
kubectl describe limitrange -n platform
```

## Scaling Troubleshooting

### If Scaling Doesn't Occur
1. **Check HPA configuration**:
   ```bash
   kubectl describe hpa multitenant-api-hpa -n platform
   ```

2. **Verify resource metrics are available**:
   ```bash
   kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq .
   kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods | jq .
   ```

3. **Check for resource constraints**:
   ```bash
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```

### If Scaling Causes Instability
1. **Check application logs**:
   ```bash
   kubectl logs -n platform -l app=multitenant-api --since=10m
   ```

2. **Verify resource requests/limits**:
   ```bash
   kubectl describe pods -n platform -l app=multitenant-api
   ```

3. **Check for pod scheduling issues**:
   ```bash
   kubectl describe pods -n platform -l app=multitenant-api | grep -A 10 "Events"
   ```

### If Cluster Doesn't Scale
1. **Check cluster autoscaler logs**:
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

2. **Verify node group configuration**:
   ```bash
   # Check if there are sufficient node group quotas
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <your-asg-name>
   ```

## Scaling Limits and Quotas

### Verify Current Limits
```bash
# Check resource quotas
kubectl describe resourcequota -n platform

# Check service quotas
aws service-quotas list-service-quotas --service-code ec2 --query 'Quotas[?starts_with(QuotaName, `Running On-Demand`) && ends_with(QuotaName, `Instances`)]'
```

### Request Quota Increases
```bash
# If quotas are insufficient, request increases
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code <quota-code> \
  --desired-value <new-value>
```

## Post-Scaling Validation

### 1. Performance Validation
- Verify response times are within acceptable limits
- Check error rates haven't increased
- Validate that all endpoints are functioning

### 2. Resource Validation
- Confirm resource utilization is optimal
- Verify no resource exhaustion
- Ensure cost efficiency

### 3. Availability Validation
- Confirm all pods are in ready state
- Verify service endpoints are healthy
- Test failover scenarios if applicable

## Scaling Best Practices

1. **Gradual Scaling**: Scale gradually to avoid overwhelming the system
2. **Monitor Metrics**: Continuously monitor key metrics during scaling
3. **Test Scaling**: Regularly test scaling procedures in non-production environments
4. **Set Appropriate Thresholds**: Configure HPA thresholds based on actual usage patterns
5. **Consider Costs**: Balance performance with cost optimization
6. **Document Patterns**: Track scaling patterns to improve automation