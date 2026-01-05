# Failure Scenarios Runbook

This runbook provides step-by-step procedures for responding to various failure scenarios in the multi-tenant SaaS API.

## 1. Pod Failure Response Procedure

### Initial Detection
1. **Check monitoring dashboard** for pod availability alerts
2. **Verify pod status**:
   ```bash
   kubectl get pods -n platform -l app=multitenant-api
   kubectl describe pod <pod-name> -n platform
   ```
3. **Check pod logs**:
   ```bash
   kubectl logs <pod-name> -n platform --previous
   ```

### Assessment
4. **Determine failure scope**:
   ```bash
   kubectl get pods -n platform -l app=multitenant-api --sort-by=.status.phase
   ```
5. **Check node status** if multiple pods are failing:
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

### Immediate Actions
6. **If single pod failure** - allow auto-restart by Kubernetes
7. **If multiple pods failing**:
   ```bash
   # Check resource usage
   kubectl top pods -n platform
   kubectl top nodes
   ```
8. **If resource exhaustion detected**:
   ```bash
   # Temporarily scale up deployment
   kubectl scale deployment multitenant-api -n platform --replicas=6
   ```

### Resolution
9. **Analyze root cause** from logs and metrics
10. **If application issue** - consider rollback to previous version
11. **If resource issue** - adjust resource limits/requests
12. **Scale back to normal** after resolution:
    ```bash
    kubectl scale deployment multitenant-api -n platform --replicas=2
    ```

## 2. AZ Outage Response Procedure

### Initial Detection
1. **Check CloudWatch** for AZ-specific metrics
2. **Verify node status**:
   ```bash
   kubectl get nodes -L topology.kubernetes.io/zone
   ```
3. **Check AZ-specific metrics** in monitoring dashboard

### Assessment
4. **Determine affected AZs**:
   ```bash
   kubectl get nodes -o json | jq '.items[] | select(.status.conditions[] | select(.type == "Ready" and .status == "False")) | .metadata.labels["topology.kubernetes.io/zone"]'
   ```
5. **Check pod distribution**:
   ```bash
   kubectl get pods -n platform -l app=multitenant-api -o json | jq '.items[] | {name: .metadata.name, zone: .spec.nodeName | "node-" + .[0:2]}'
   ```

### Immediate Actions
6. **Verify remaining capacity**:
   ```bash
   kubectl top nodes | grep -v <affected-zone>
   ```
7. **Scale up in healthy AZs**:
   ```bash
   kubectl scale deployment multitenant-api -n platform --replicas=6
   ```
8. **Monitor traffic distribution** in ALB console

### Resolution
9. **Wait for AZ recovery** or migrate workloads permanently if needed
10. **Redistribute pods** after AZ recovery:
    ```bash
    # Taint affected nodes temporarily to reschedule pods
    kubectl taint nodes <affected-node> az-outage=true:NoSchedule
    ```
11. **Verify health** before removing taints:
    ```bash
    kubectl taint nodes <affected-node> az-outage=true:NoSchedule-
    ```

## 3. Database Failover Response Procedure

### Initial Detection
1. **Check database connectivity alerts** in monitoring
2. **Verify RDS status** in AWS Console
3. **Check application logs** for database errors:
   ```bash
   kubectl logs -n platform -l app=multitenant-api --since=5m | grep -i error
   ```

### Assessment
4. **Check RDS failover events**:
   ```bash
   aws rds describe-events --source-identifier <db-instance-identifier> --source-type db-instance --start-time $(date -d '5 minutes ago' --iso-8601=seconds)
   ```
5. **Verify connection metrics** in monitoring dashboard

### Immediate Actions
6. **Implement circuit breaker** if application supports it
7. **Enable read-only mode** temporarily if implemented
8. **Monitor failover progress** in AWS Console

### Resolution
9. **After failover complete**:
   ```bash
   # Restart application pods to refresh connections
   kubectl rollout restart deployment multitenant-api -n platform
   ```
10. **Verify connectivity**:
    ```bash
    kubectl logs -n platform -l app=multitenant-api --tail=20 | grep -i connected
    ```
11. **Monitor performance** after failover

## 4. Bad Deploy Response Procedure

### Initial Detection
1. **Monitor deployment progress**:
   ```bash
   kubectl get pods -n platform -l app=multitenant-api --watch
   ```
2. **Check error rate** in monitoring dashboard
3. **Verify application logs**:
   ```bash
   kubectl logs -n platform -l app=multitenant-api --tail=20
   ```

### Assessment
4. **Compare metrics** before and after deployment
5. **Check for error patterns**:
   ```bash
   kubectl logs -n platform -l app=multitenant-api --since=10m | grep -i error | wc -l
   ```
6. **Verify deployment status**:
   ```bash
   kubectl rollout status deployment/multitenant-api -n platform
   ```

### Immediate Actions
7. **Pause deployment** if in progress:
   ```bash
   kubectl rollout pause deployment/multitenant-api -n platform
   ```
8. **If severe issue detected** - initiate immediate rollback:
   ```bash
   kubectl rollout undo deployment/multitenant-api -n platform
   ```
9. **Monitor rollback progress**:
   ```bash
   kubectl rollout status deployment/multitenant-api -n platform
   ```

### Resolution
10. **Verify rollback success**:
    ```bash
    kubectl get pods -n platform -l app=multitenant-api
    kubectl describe deployment multitenant-api -n platform
    ```
11. **Analyze failed deployment** for root cause
12. **Fix issue** and prepare corrected deployment

## General Incident Response

### Communication
1. **Notify incident response team** immediately
2. **Update status page** if customer-facing impact
3. **Provide regular updates** every 15 minutes during incident

### Documentation
4. **Record timeline** of events and actions taken
5. **Capture relevant logs** and metrics
6. **Document root cause** and resolution steps

### Post-Incident
7. **Schedule post-mortem** within 24-48 hours
8. **Create action items** to prevent similar incidents
9. **Update runbooks** based on lessons learned