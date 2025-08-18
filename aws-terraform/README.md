# 🛠️ Terraform Infrastructure

This repository manages AWS infrastructure for `matatika-catalog` using [Terraform](https://www.terraform.io/). 
Infrastructure for `matatika-website` is still work in progress.
It supports multiple environments (e.g. `dev`, `stage`, `prod`) that share the same infrastructure code.
Environment-specific configuration is handled through variable files (`../matatika-config/aws-terraform/*.tfvars`) and backend configuration (`../matatika-config/aws-terraform/*.tfbackend`).

---

## ⚙️ Requirements

- Terraform (version specified in `./terraform-version`)
- Configured [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
- Access to the appropriate AWS account (administrator permissions) using a named profile or default credentials

---

## 🚀 Usage

For now infrastructure is only in `Dev` (`868651350637`) account.
You have to be authenticated in the target account.

You can use either `Access keys` from your IAM IC or use profiles.
To set up a profile, see [AWS docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html). In particular, run
`aws configure sso` with URL https://matatika.awsapps.com/start 
Then to use a given profile, attach `--profile` to the AWS command.
Every command can use this profile with `export AWS_DEFAULT_PROFILE=matatika-dev`


### 1. Initialize Terraform

Before the first use, initialize the working directory and backend from `aws-terraform` directory:

```bash
terraform init -backend-config="../../matatika-config/aws-terraform/dev/matatika.tfbackend"
```

Example contents of terraform.tfbackend:

```hcl
bucket = "matatika-dev-tf-state"
key    = "dev.tfstate"
region = "eu-west-2"
```

### 2. Plan Infrastructure
``` bash
terraform plan -var-file="../../matatika-config/aws-terraform/dev/matatika.tfvars"
```

### 3. Apply Infrastructure
```bash
terraform apply -var-file="../../matatika-config/aws-terraform/dev/matatika.tfvars"
```

### 4. Destroy Infrastructure
```bash
terraform destroy -var-file="../../matatika-config/aws-terraform/dev/matatika.tfvars"
```

### 5. Exec into Kubernetes cluster
Whoever has an access entry to EKS cluster in the Terraform can do the following:

```bash
aws eks update-kubeconfig --region eu-west-2 --name dev
kubectl get pods
```

---

## 🔧 AWS Credentials
You can authenticate using an AWS profile or `aws-vault`.

This requires administrator access permissions.

---

## 🔧 Prerequisites

Before running the Terraform, provision manually an AWS Secrets Manager secret under paths `/terraform/rds/credentials` and `/terraform/cloudflare/credentials`
(paths configurable in `.tfvars`) in your desired region (`eu-west-1`).

- `/terraform/rds/credentials` should have JSON structure with the following keys:`username` and `password`. Values should contain credentials to your RDS. 

- `/terraform/cloudflare/credentials` should be a string containing your
CloudFlare API key for ExternalDNS hosted zone management.

Manual provisioning is due to avoiding storing a secret
in the code or `.tfvars`.

---

## 📌 Notes
This project uses a single source of infrastructure code for all environments.

Environment-specific configurations are provided via `.tfvars` files and backend config.

Sensitive values should not be stored in `.tfvars` files committed to version control. Use Secrets Manager with `data` instead.

The current configuration does not yet use assume-role; it can be added later if required.

You can define separate `terraform.tfbackend` files per environment to isolate state files.

---

## 🧰 Example Commands (dev environment)
```bash
terraform init -backend-config="../matatika-config/aws-terraform/dev.tfbackend"
terraform plan  -var-file="../matatika-config/aws-terraform/dev.tfvars"
terraform apply -var-file="../matatika-config/aws-terraform/dev.tfvars"
```

# 🚀 Deploying app in your AWS infrastructure

## 🔧 Prerequisites

After provisioning the infrastructure:
- validate your subdomain with hosted zone adding CNAME record (outputted from Terraform/retrieve from AWS Console).
- plug ACM certificate ARN to Helm chart values. It can be automated with CI/CD later on.
- later on you'll have to provision new Auth0 application if the environment is new.

## ⚙️ Helm chart values for Ingress

AWS Load Balancer Controller needs a different handling that Azure one.
This requires adding more values to your Ingress resource -
you'll find a working ingress example for `Dev` under `example-ingress/dev-matatika-catalog-ingress.yaml`.

- `service`: `httpPort: 80`, `targetPort: 8080`
- `ingress.annotations`:
```
ingressClassName: alb
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-2:868651350637:certificate/b8cfc226-a9d8-4d44-9883-22886d60693c # this one is different per environment!
alb.ingress.kubernetes.io/healthcheck-path: /
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
```
