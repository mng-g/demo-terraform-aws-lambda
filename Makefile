# === CONFIGURATION ===
TF_PROJECT         := demo-terraform-aws-lambda
LAMBDA_DIR         := src
ZIP_FILE           := lambda.zip
WORKSPACES         := dev test prod
TF_VAR_project_name := demo-terraform-aws-lambda

# === DYNAMIC VARS (read from environment) ===
BACKEND_BUCKET     := $(TF_BACKEND_BUCKET)
BACKEND_REGION     := $(TF_BACKEND_REGION)
BACKEND_DDB_TABLE  := $(TF_BACKEND_DDB_TABLE)

# === HELP ===
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make init ENV=<env>         - Initialize terraform for given workspace"
	@echo "  make plan ENV=<env>         - Plan for given workspace"
	@echo "  make apply ENV=<env>        - Apply for given workspace"
	@echo "  make destroy ENV=<env>      - Destroy for given workspace"
	@echo "  make zip                    - Package Lambda function code"
	@echo "  make backend                - Generate backend.tf from environment vars"
	@echo "  make clean                  - Remove zip file"

# === BACKEND ===
.PHONY: backend
backend:
	./generate-backend.sh

# === ZIP ===
.PHONY: zip
zip:
	cd $(LAMBDA_DIR) && zip -r ../$(ZIP_FILE) .

# === INIT ===
init: zip backend
	@terraform init -input=false
	@echo "Initializing Terraform for environment: $(ENV)"
	@terraform workspace select $(ENV) || terraform workspace new $(ENV)

# 	@bash -c '\
# 		if [ -n "$(ENV)" ]; then \
# 			echo "Terraform workspace: $${DEPLOY_ENVIRONMENT:-$(ENV)}"; \
# 		else \
# 			if terraform workspace list | grep -q "$(ENV)"; then \
# 				echo "✅ Selecting workspace $(ENV)"; \
# 				terraform workspace select "$(ENV)"; \
# 			else \
# 				echo "🆕 Creating workspace $(ENV)"; \
# 				terraform workspace new "$(ENV)"; \
# 			fi; \
# 		fi'


# === PLAN ===
.PHONY: plan
plan:
# 	terraform workspace select $(ENV)
	@echo "Terraform workspace: $${DEPLOY_ENVIRONMENT:-$(ENV)}"
	terraform plan -var="project_name=$(TF_VAR_project_name)"

# === APPLY ===
.PHONY: apply
apply:
# 	terraform workspace select $(ENV)
	@echo "Terraform workspace: $${DEPLOY_ENVIRONMENT:-$(ENV)}"
	terraform apply -var="project_name=$(TF_VAR_project_name)" -auto-approve

# === DESTROY ===
.PHONY: destroy
destroy:
# 	terraform workspace select $(ENV)
	@echo "Terraform workspace: $${DEPLOY_ENVIRONMENT:-$(ENV)}"
	terraform destroy -var="project_name=$(TF_VAR_project_name)" -auto-approve

# === CLEAN ===
.PHONY: clean
clean:
	rm -f $(ZIP_FILE)
