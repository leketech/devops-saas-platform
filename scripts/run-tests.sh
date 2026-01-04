#!/bin/bash

# Script to run unit tests for the SaaS platform application

set -e  # Exit immediately if a command exits with a non-zero status

echo "Starting unit tests..."

# Change to the application directory
cd application

# Run Go tests
echo "Running Go tests..."
go test -v ./...

echo "All tests passed!"