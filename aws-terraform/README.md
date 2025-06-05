# 🛠️ Terraform Infrastructure

This repository manages AWS infrastructure using [Terraform](https://www.terraform.io/). 
It supports multiple environments (e.g. `dev`, `stage`, `prod`) that share the same infrastructure code.
Environment-specific configuration is handled through variable files (`./config/.tfvars`) and backend configuration (`./config/.tfbackend`).

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


### 1. Initialize Terraform

Before the first use, initialize the working directory and backend from `aws-terraform` directory:

```bash
terraform init -backend-config="./config/dev.tfbackend"
```

Example contents of terraform.tfbackend:

```hcl
bucket = "matatika-dev-tf-state"
key    = "dev.tfstate"
region = "eu-west-2"
```

### 2. Plan Infrastructure
``` bash
terraform plan -var-file="./config/dev.tfvars"
```

### 3. Apply Infrastructure
```bash
terraform apply -var-file="./config/dev.tfvars"
```

### 4. Destroy Infrastructure
```bash
terraform destroy -var-file="tfvars/dev.tfvars"
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

## Prerequisites

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
terraform init -backend-config="./config/dev.tfbackend"
terraform plan  -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"
```