init-dev:
	terraform init -backend-config="../../matatika-config/aws-terraform/dev/matatika.tfbackend"

plan-dev:
	terraform plan -var-file="../../matatika-config/aws-terraform/dev/matatika.tfvars"

apply-dev:
	terraform apply -var-file="../../matatika-config/aws-terraform/dev/matatika.tfvars"

init-staging:
	terraform init -backend-config="../../matatika-config/aws-terraform/staging/matatika.tfbackend"

plan-staging:
	terraform plan -var-file="../../matatika-config/aws-terraform/staging/matatika.tfvars"

apply-staging:
	terraform apply -var-file="../../matatika-config/aws-terraform/staging/matatika.tfvars"

init-prod:
	terraform init -backend-config="../../matatika-config/aws-terraform/prod/matatika.tfbackend"

plan-prod:
	terraform plan -var-file="../../matatika-config/aws-terraform/prod/matatika.tfvars"

apply-prod:
	terraform apply -var-file="../../matatika-config/aws-terraform/prod/matatika.tfvars"
