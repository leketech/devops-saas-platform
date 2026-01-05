# Makefile for SaaS Platform

.PHONY: test build docker-build docker-run clean

# Build the application
build:
	cd application && go build -o ../bin/saas-platform-app .

# Run tests
test:
	cd application && go test -v ./...

# Build Docker image
docker-build:
	docker build -t saas-platform-app .

# Run the application in Docker
docker-run: docker-build
	docker run -p 8080:8080 saas-platform-app

# Clean build artifacts
clean:
	rm -f bin/saas-platform-app

# Run linting
lint:
	# Lint Go code
	cd application && go vet ./...
	cd application && golint ./... || echo "golint not installed, skipping..."

# Run all checks
check: lint test

# Initialize the project
init:
	cd application && go mod tidy