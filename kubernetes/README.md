# GitOps with ArgoCD

This directory contains the GitOps configuration for the SaaS platform using ArgoCD and the App-of-Apps pattern.

## Directory Structure

```
kubernetes/
├── base/
│   └── applications/           # Base ArgoCD applications
│       ├── app-of-apps.yaml   # Root application that manages all others
│       └── kustomization.yaml
└── overlays/
    ├── dev/                   # Development environment
    ├── staging/               # Staging environment
    └── prod/                  # Production environment
```

## App-of-Apps Pattern

The `app-of-apps.yaml` defines a root ArgoCD Application that manages all other applications in the platform. This follows the App-of-Apps pattern where a single application manages multiple child applications.

## Promotion Process

Promotion between environments happens through Git pull requests:
1. Make changes in the development environment
2. Create a pull request to promote changes to staging
3. Create another pull request to promote changes to production

## Usage

To register the root application with ArgoCD:

```bash
argocd app create saas-platform-apps \
  --repo https://github.com/your-org/devops-saas-platform \
  --path kubernetes/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace platform
```

Or apply directly with kubectl:

```bash
kubectl apply -f kubernetes/base/applications/app-of-apps.yaml
```