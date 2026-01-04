Deployment steps for ACM certificate (dev)

1) Initialize and review the plan (already done previously):

```powershell
Set-Location 'C:\Users\Leke\dev_saas\devops-saas-platform\infrastructure\terraform\envs\dev'
terraform init -input=false
terraform plan -out=tfplan -input=false
```

2) Apply the plan (creates Route53 validation records and requests the ACM cert):

```powershell
terraform apply "tfplan" -input=false -auto-approve
```

3) Get the created certificate ARN (copy this to update the Kubernetes Ingress):

```powershell
terraform output -raw acm_certificate_arn
```

4) Update the Ingress manifest `infrastructure/kubernetes/example-ingress-tls.yaml`:

- Replace the placeholder `REPLACE_WITH_ACM_CERT_ARN` in the `alb.ingress.kubernetes.io/certificate-arn` annotation with the value from step 3.

5) Apply the Ingress to the cluster (ALB will then use the ACM cert):

```powershell
# ensure kubeconfig points to the desired cluster
kubectl apply -f infrastructure/kubernetes/example-ingress-tls.yaml
```

Notes:
- DNS nameservers are already delegated at the registrar; Route53 validation records are created automatically by Terraform.
- ACM DNS validation can take a short while to complete; `terraform apply` will create validation records and wait for validation.
