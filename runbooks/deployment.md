# Deployment Runbook

This runbook provides step-by-step procedures for deploying the multi-tenant SaaS API.

## Pre-Deployment Checklist

- [ ] Verify all tests pass in staging environment
- [ ] Confirm sufficient cluster resources for deployment
- [ ] Ensure backup procedures are in place
- [ ] Verify monitoring and alerting systems are operational
- [ ] Confirm rollback plan is ready and tested
- [ ] Notify stakeholders of scheduled maintenance window (if applicable)

## Deployment Process

### 1. Prepare the Deployment

1. **Pull latest code**:
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Build and push the new image**:
   ```bash
   # Build the new image
   docker build -t multitenant-api:v1.x.x .
   
   # Tag and push to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com
   docker tag multitenant-api:v1.x.x <account_id>.dkr.ecr.us-east-1.amazonaws.com/multitenant-api:v1.x.x
   docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/multitenant-api:v1.x.x
   ```

3. **Update deployment manifest**:
   ```bash
   # Update the image in the deployment file
   sed -i 's|image: multitenant-api:.*|image: <account_id>.dkr.ecr.us-east-1.amazonaws.com/multitenant-api:v1.x.x|' api/k8s-deployment.yaml
   ```

### 2. Deploy Using Blue/Green Strategy

1. **Deploy to preview environment** (if using blue-green):
   ```bash
   kubectl apply -f blue-green-deploy/blue-green-deployment.yaml
   ```

2. **Monitor preview deployment**:
   ```bash
   # Check rollout status
   kubectl get rollouts -n platform
   kubectl argo rollouts get rollout multitenant-api-rollout -n platform
   
   # Monitor pods
   kubectl get pods -n platform -l app=multitenant-api
   ```

3. **Validate preview deployment**:
   ```bash
   # Check logs
   kubectl logs -n platform -l app=multitenant-api --tail=20
   
   # Test health endpoint
   kubectl port-forward -n platform svc/multitenant-api-service-preview 8080:8080
   curl http://localhost:8080/health
   ```

### 3. Promote to Production (if using blue-green)

1. **Promote to active service**:
   ```bash
   kubectl argo rollouts promote multitenant-api-rollout -n platform
   ```

2. **Monitor promotion**:
   ```bash
   kubectl argo rollouts get rollout multitenant-api-rollout -n platform --watch
   ```

### 4. Canary Deployment (Alternative Method)

1. **Apply canary deployment**:
   ```bash
   kubectl apply -f blue-green-deploy/canary-deployment.yaml
   ```

2. **Monitor canary progress**:
   ```bash
   kubectl argo rollouts get rollout multitenant-api-canary-rollout -n platform --watch
   ```

## Post-Deployment Verification

1. **Verify deployment status**:
   ```bash
   kubectl get deployments -n platform
   kubectl get pods -n platform -l app=multitenant-api
   kubectl rollout status deployment/multitenant-api -n platform
   ```

2. **Check service availability**:
   ```bash
   kubectl get services -n platform
   kubectl get ingress -n platform
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

## Troubleshooting

### If deployment fails during rollout:
1. Check the rollout status: `kubectl argo rollouts get rollout <rollout-name> -n platform`
2. Check pod logs: `kubectl logs -n platform -l app=multitenant-api --previous`
3. Check events: `kubectl get events -n platform --sort-by='.lastTimestamp'`

### If health checks fail:
1. Verify the application is listening on the correct port
2. Check for configuration issues in environment variables
3. Verify database and Redis connectivity

### If resource limits are exceeded:
1. Check resource utilization: `kubectl top pods -n platform`
2. Adjust resource requests/limits if needed
3. Scale cluster nodes if necessary

## Rollback Trigger Conditions

- Health check failures persist for more than 5 minutes
- Error rate exceeds 5% during deployment
- Response time degrades by more than 50%
- Critical functionality is broken

## Completion Steps

1. **Update documentation** with new version information
2. **Notify stakeholders** of successful deployment
3. **Monitor application** for at least 30 minutes post-deployment
4. **Archive previous version** if using blue-green strategy