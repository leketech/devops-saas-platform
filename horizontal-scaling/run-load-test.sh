#!/bin/bash

# Script to run k6 load tests against the multi-tenant API

set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting k6 load test for horizontal scaling verification..."

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "k6 is not installed. Please install k6 before running this script."
    echo "You can install k6 using: https://k6.io/docs/get-started/installation/"
    exit 1
fi

# Check if we're inside a Kubernetes pod or have access to the cluster
if kubectl get ns platform &> /dev/null; then
    echo "Running load test from inside the cluster..."
    k6 run /scripts/api-load-test.js --out influxdb=http://influxdb.platform.svc.cluster.local:8086/k6
else
    echo "Running load test from outside the cluster..."
    echo "Note: This test requires access to the cluster services."
    
    # Try to run the test with external access if available
    k6 run api-load-test.js
fi

echo "Load test completed. Check the results in the k6 output above."
echo "Monitor the HPA status with: kubectl get hpa -n platform"
echo "Monitor the deployment scale with: kubectl get deploy -n platform"