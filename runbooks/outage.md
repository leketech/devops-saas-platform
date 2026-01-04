# Outage Runbook

This runbook provides step-by-step procedures for responding to service outages in the multi-tenant SaaS API.

## Outage Classification

### Critical Outage (P0)
- Complete service unavailability
- Data integrity at risk
- Security breach detected
- Affects all tenants

### Major Outage (P1)
- Service degradation for multiple tenants
- Significant functionality unavailable
- Performance significantly impacted

### Minor Outage (P2)
- Service degradation for specific tenants
- Non-critical functionality unavailable
- Performance slightly impacted

## Outage Detection

### Automated Detection
- Health check failures
- High error rate alerts (>5%)
- High latency alerts (>1s 95th percentile)
- Pod crash loop alerts
- Database connection alerts
- Node failure alerts

### Manual Detection
- Customer reports
- Monitoring dashboard anomalies
- Performance degradation notices
- Service degradation reports

## Incident Response Team

### Primary On-Call
- **Role**: Platform Engineer
- **Responsibility**: Initial incident response and triage

### Secondary On-Call
- **Role**: Senior Platform Engineer
- **Responsibility**: Escalation support and complex issue resolution

### Database Administrator
- **Role**: DBA
- **Responsibility**: Database-related outage resolution

### Security Engineer
- **Role**: Security Engineer
- **Responsibility**: Security-related incidents

## Outage Response Process

### Phase 1: Acknowledgment (0-5 minutes)

1. **Acknowledge alert** in monitoring system
2. **Verify outage** by checking multiple sources
3. **Classify outage** based on severity
4. **Initiate incident response** procedures
5. **Notify primary response team**

### Phase 2: Assessment (5-15 minutes)

1. **Check monitoring dashboards**:
   ```bash
   # Check overall health
   kubectl get pods -n platform -l app=multitenant-api
   kubectl get nodes
   kubectl get events -n platform --sort-by='.lastTimestamp' | head -20
   ```

2. **Check service status**:
   ```bash
   # Check deployment status
   kubectl get deployment multitenant-api -n platform
   
   # Check service endpoints
   kubectl get endpoints multitenant-api-service -n platform
   
   # Check ingress
   kubectl get ingress -n platform
   ```

3. **Check application logs**:
   ```bash
   # Check recent logs
   kubectl logs -n platform -l app=multitenant-api --since=10m
   
   # Check for errors
   kubectl logs -n platform -l app=multitenant-api --since=10m | grep -i error
   ```

### Phase 3: Isolation (15-30 minutes)

1. **Determine scope**:
   - Which tenants are affected?
   - Which services are impacted?
   - What is the geographic scope?

2. **Check infrastructure**:
   ```bash
   # Check node status
   kubectl get nodes -L topology.kubernetes.io/zone
   
   # Check cluster status
   kubectl cluster-info
   
   # Check for node issues
   kubectl describe nodes | grep -A 5 "Conditions"
   ```

3. **Check dependencies**:
   ```bash
   # Check database connectivity
   kubectl run debug --image=postgres:13 --rm -it --env="PGPASSWORD=<password>" -- psql -h postgres-service -U postgres -c "SELECT 1;"
   
   # Check Redis connectivity
   kubectl run debug --image=redis:6-alpine --rm -it -- redis-cli -h redis-service ping
   ```

### Phase 4: Mitigation (30-60 minutes)

#### If it's a Pod/Deployment Issue
```bash
# Restart deployment
kubectl rollout restart deployment/multitenant-api -n platform

# Monitor restart progress
kubectl get pods -n platform -l app=multitenant-api --watch
```

#### If it's a Node Issue
```bash
# Cordon affected node
kubectl cordon <node-name>

# Drain node if safe to do so
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Check for replacement nodes
kubectl get nodes
```

#### If it's a Database Issue
```bash
# Check database status
kubectl get pods -n platform -l app=postgres

# Restart database if needed
kubectl rollout restart statefulset/postgres -n platform

# Check database logs
kubectl logs -n platform -l app=postgres --tail=100
```

#### If it's a Network Issue
```bash
# Check network policies
kubectl get networkpolicies -n platform

# Check service configuration
kubectl describe svc multitenant-api-service -n platform
```

### Phase 5: Recovery (60+ minutes)

1. **Verify service restoration**:
   ```bash
   # Check pod status
   kubectl get pods -n platform -l app=multitenant-api
   
   # Test health endpoint
   curl -H "Authorization: Bearer <valid-jwt>" http://api.globepay.space/health
   
   # Check service availability
   kubectl port-forward -n platform svc/multitenant-api-service 8080:8080
   ```

2. **Run smoke tests**:
   ```bash
   # Test basic functionality
   curl -H "Authorization: Bearer <valid-jwt>" "http://api.globepay.space/api/data"
   ```

3. **Monitor for stability**:
   - Observe metrics for 15+ minutes
   - Verify no recurring errors
   - Confirm performance is acceptable

## Communication Plan

### Internal Communication
- **Slack/Teams**: Create incident channel
- **Status updates**: Every 15 minutes during active incident
- **Escalation**: When additional expertise is needed

### External Communication
- **Customer status page**: Update every 30 minutes
- **Email notifications**: For critical outages affecting customers
- **Executive updates**: For incidents lasting >1 hour

## Post-Outage Procedures

### 1. Documentation
- **Timeline**: Document exact sequence of events
- **Root cause**: Identify primary and contributing factors
- **Impact assessment**: Quantify business and customer impact
- **Resolution steps**: Document all actions taken

### 2. Analysis
- **Root cause analysis**: Deep dive into primary cause
- **Contributing factors**: Identify all factors that contributed
- **Detection time**: How long before the issue was detected
- **Response time**: How long to initiate response
- **Resolution time**: How long to fully resolve

### 3. Improvements
- **Action items**: Define improvements to prevent similar incidents
- **Process updates**: Update runbooks and procedures
- **Monitoring improvements**: Enhance detection capabilities
- **Automation opportunities**: Identify areas for automation

## Common Outage Scenarios

### Database Connection Exhaustion
**Symptoms**: High error rates, slow response times
**Resolution**:
```bash
# Check connection pool metrics
kubectl logs -n platform -l app=multitenant-api | grep -i "connection.*pool"

# Restart application to refresh connections
kubectl rollout restart deployment/multitenant-api -n platform
```

### Memory Exhaustion
**Symptoms**: Pod restarts, OOMKilled events
**Resolution**:
```bash
# Check memory usage
kubectl top pods -n platform -l app=multitenant-api

# Check pod status for OOMKilled
kubectl describe pods -n platform -l app=multitenant-api | grep -A 5 OOMKilled

# Increase memory limits
kubectl patch deployment multitenant-api -n platform -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

### Node Failure
**Symptoms**: Multiple pods on same node failing
**Resolution**:
```bash
# Check node status
kubectl get nodes

# Cordon failed node
kubectl cordon <failed-node-name>

# Check pod rescheduling
kubectl get pods -n platform -l app=multitenant-api --watch
```

### Network Partition
**Symptoms**: Service unavailable but pods running
**Resolution**:
```bash
# Check service endpoints
kubectl get endpoints multitenant-api-service -n platform

# Check network policies
kubectl describe networkpolicies -n platform

# Test connectivity
kubectl run debug --image=nicolaka/netshoot --rm -it -- sh
```

## Emergency Contacts

- **Primary On-Call**: [Phone number]
- **Secondary On-Call**: [Phone number]
- **Database Administrator**: [Phone number]
- **Security Engineer**: [Phone number]
- **AWS Support**: [Phone number]

## Escalation Matrix

| Time Elapsed | Level | Action |
|--------------|-------|---------|
| 0-30 mins | L1 | Primary on-call engineer |
| 30-60 mins | L2 | Secondary on-call engineer |
| 60-120 mins | L3 | Engineering management |
| 2+ hours | L4 | Executive leadership |

## Checklist for Outage Resolution

- [ ] Incident acknowledged and classified
- [ ] Response team notified
- [ ] Scope of outage determined
- [ ] Root cause identified
- [ ] Mitigation strategy implemented
- [ ] Service restored
- [ ] Stability confirmed
- [ ] Stakeholders notified
- [ ] Post-incident analysis scheduled
- [ ] Action items defined
- [ ] Runbooks updated