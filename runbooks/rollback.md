# Rollback Runbook

This runbook provides step-by-step procedures for rolling back the multi-tenant SaaS API to a previous stable version.

## Rollback Trigger Conditions

Rollback is initiated when:
- Health checks fail for more than 5 minutes
- Error rate exceeds 5% during deployment
- Response time degrades by more than 50%
- Critical functionality is broken
- SLOs are breached during deployment
- Database connectivity issues occur
- Security vulnerabilities are detected

## Pre-Rollback Checklist

- [ ] Document current state and error conditions
- [ ] Ensure backup of current configuration exists
- [ ] Notify stakeholders of rollback procedure
- [ ] Confirm previous version is stable and available
- [ ] Verify rollback target version has been tested

## Rollback Process

### 1. Immediate Response

1. **Assess the situation**:
   ```bash
   # Check rollout status
   kubectl argo rollouts get rollout multitenant-api-rollout -n platform
   
   # Check recent events
   kubectl get events -n platform --sort-by='.lastTimestamp' | head -20
   
   # Check pod status
   kubectl get pods -n platform -l app=multitenant-api
   ```

2. **If using Argo Rollouts** (Blue/Green or Canary):
   ```bash
   # Abort the rollout immediately
   kubectl argo rollouts abort multitenant-api-rollout -n platform
   
   # Check status after abort
   kubectl argo rollouts get rollout multitenant-api-rollout -n platform
   ```

### 2. Manual Rollback (if Argo Rollouts is not available)

1. **Rollback to previous version**:
   ```bash
   # Rollback deployment
   kubectl rollout undo deployment/multitenant-api -n platform
   
   # Monitor rollback progress
   kubectl rollout status deployment/multitenant-api -n platform
   ```

2. **Verify rollback status**:
   ```bash
   # Check deployment status
   kubectl get deployment multitenant-api -n platform -o yaml
   
   # Check pod status
   kubectl get pods -n platform -l app=multitenant-api
   ```

### 3. Blue/Green Specific Rollback

1. **If using Blue/Green deployment**:
   ```bash
   # Switch traffic back to stable service
   kubectl patch rollout multitenant-api-rollout -n platform -p '{"spec":{"strategy":{"blueGreen":{"activeService":"multitenant-api-service-stable"}}}'
   ```

2. **Scale down preview deployment**:
   ```bash
   # Scale down preview pods to 0
   kubectl scale deployment multitenant-api-preview -n platform --replicas=0
   ```

### 4. Canary Specific Rollback

1. **If using Canary deployment**:
   ```bash
   # Abort the canary rollout
   kubectl argo rollouts abort multitenant-api-canary-rollout -n platform
   
   # Abort and promote stable version
   kubectl argo rollouts promote multitenant-api-canary-rollout -n platform --abort
   ```

## Post-Rollback Verification

1. **Verify stable version is running**:
   ```bash
   # Check deployment image
   kubectl get deployment multitenant-api -n platform -o jsonpath='{.spec.template.spec.containers[0].image}'
   
   # Verify all pods are running previous version
   kubectl get pods -n platform -l app=multitenant-api -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | uniq
   ```

2. **Check application health**:
   ```bash
   # Check pod status
   kubectl get pods -n platform -l app=multitenant-api
   
   # Check service endpoints
   kubectl get endpoints multitenant-api-service -n platform
   
   # Test health endpoint
   kubectl port-forward -n platform svc/multitenant-api-service 8080:8080
   curl http://localhost:8080/health
   ```

3. **Monitor application metrics**:
   - Verify health endpoints are responding
   - Check application logs for errors
   - Monitor resource utilization
   - Validate API response times

4. **Run smoke tests**:
   ```bash
   # Example smoke test
   curl -H "Authorization: Bearer <valid-jwt-token>" http://api.globepay.space/health
   ```

## Database Rollback (if needed)

1. **Check if database migration was part of deployment**:
   ```bash
   # If using database migrations, you may need to revert
   # Example for schema changes (if applicable):
   # NOTE: Replace <password> with the actual database password
   kubectl run -it --rm rollback-job --image=postgres:13 --env="PGPASSWORD=<password>" --command -- psql -h postgres-service -U postgres -d saas_db -c "BEGIN; -- your rollback SQL; COMMIT;"
   ```

## Troubleshooting

### If rollback fails:
1. Check for resource constraints: `kubectl top nodes`
2. Check for image pull issues: `kubectl describe pods -n platform`
3. Verify previous image is available in registry
4. Check RBAC permissions for rollback operations

### If application doesn't stabilize after rollback:
1. Check configuration maps and secrets
2. Verify database connectivity
3. Review application logs for errors
4. Check resource limits and requests

### If traffic routing doesn't revert:
1. Check service configurations
2. Verify ingress rules
3. Check load balancer status

## Rollback Completion Steps

1. **Document the rollback**:
   - Record the reason for rollback
   - Document any errors encountered
   - Note the time to complete rollback

2. **Notify stakeholders** of rollback completion

3. **Monitor application** for at least 30 minutes post-rollback

4. **Analyze root cause** of the deployment failure

5. **Plan for next deployment** with fixes for identified issues

6. **Update runbooks** if any procedures need refinement

## Communication Plan

- **Immediate**: Notify engineering team of rollback initiation
- **During**: Provide status updates every 10 minutes
- **Post-rollback**: Notify all stakeholders of successful rollback
- **Post-mortem**: Schedule review meeting to analyze failure cause