#!/bin/bash

# Script to verify horizontal scaling of the multi-tenant API

set -e  # Exit immediately if a command exits with a non-zero status

echo "Verifying horizontal scaling setup..."

# Check if HPA exists
echo "Checking HPA configuration..."
kubectl get hpa multitenant-api-hpa -n platform || {
    echo "HPA multitenant-api-hpa not found in platform namespace"
    echo "Creating HPA..."
    kubectl apply -f hpa.yaml
}

# Check if cluster autoscaler is running
echo "Checking cluster autoscaler status..."
kubectl get deploy cluster-autoscaler -n kube-system || {
    echo "Cluster autoscaler deployment not found in kube-system namespace"
    echo "Creating cluster autoscaler..."
    kubectl apply -f cluster-autoscaler.yaml
}

# Check current deployment status
echo "Checking multi-tenant API deployment..."
kubectl get deploy multitenant-api -n platform

# Check current HPA status
echo "Checking HPA status..."
kubectl get hpa multitenant-api-hpa -n platform

# Check current pods
echo "Checking current pods..."
kubectl get pods -n platform -l app=multitenant-api

# Instructions for running the load test
echo ""
echo "To test horizontal scaling:"
echo "1. Run the k6 load test: k6 run api-load-test.js"
echo "2. Monitor scaling with: kubectl get hpa -n platform -w"
echo "3. Monitor pods with: kubectl get pods -n platform -w"
echo "4. Monitor nodes with: kubectl get nodes -w"
echo ""
echo "Expected behavior:"
echo "- As load increases, HPA should scale up pods based on CPU and latency metrics"
echo "- As pods are scheduled, cluster autoscaler should add nodes if needed"
echo "- The API should handle increased load with minimal performance degradation"
echo ""
echo "Monitor these metrics during the test:"
echo "- kubectl top pods -n platform"
echo "- kubectl top nodes"
echo "- kubectl describe hpa multitenant-api-hpa -n platform"