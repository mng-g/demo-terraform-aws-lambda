# 🚀 demo-terraform-aws-lambda

This project demonstrates how to deploy AWS Lambda functions using Terraform with a **remote backend** powered by **S3** and **DynamoDB** for secure, team-friendly state management.

---

## 🌱 Prerequisites

- AWS CLI installed and configured
- Terraform installed
- AWS credentials with permissions to manage S3, DynamoDB, Lambda, IAM, etc.

---

## ⚙️ Environment Variables

Before running any Terraform commands, set the following environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# Unique S3 bucket for remote state (must be globally unique)
export TF_BACKEND_BUCKET="mycompany-terraform-backend-2025"

# Region where resources will be created
export TF_BACKEND_REGION="us-east-1"

# DynamoDB table for state locking
export TF_BACKEND_DDB_TABLE="terraform-locks"

# Key (path) to the Terraform state file in S3
export TF_BACKEND_KEY="lambda_project/terraform.tfstate"
````

> 💡 You can save these in a file like `env.sh` and load with `source env.sh`.

---

## 🏗️ Remote Backend Setup (S3 + DynamoDB)

Create the required S3 bucket and DynamoDB table manually:

```bash
# Create the S3 bucket
aws s3api create-bucket \
  --bucket "$TF_BACKEND_BUCKET" \
  --region "$TF_BACKEND_REGION" \
  $( [ "$TF_BACKEND_REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$TF_BACKEND_REGION" )

# Create the DynamoDB table
aws dynamodb create-table \
  --table-name "$TF_BACKEND_DDB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --region "$TF_BACKEND_REGION"
```

---

## 🔧 Generate `backend.tf` Dynamically

This project includes a script to generate your `backend.tf` file using the environment variables you defined.

### ▶️ Run the backend.tf generator

```bash
chmod +x generate-backend.sh
./generate-backend.sh
```

---

## 🚀 Terraform Workflow

```bash
cd demo-terraform-aws-lambda

terraform init
terraform plan
terraform apply
```

---

## ✅ Verify Backend Resources

```bash
aws s3api list-buckets
aws dynamodb list-tables
aws dynamodb describe-table --table-name "$TF_BACKEND_DDB_TABLE"
```

---

## 🧹 Cleanup

### Destroy Terraform-managed infrastructure

```bash
terraform destroy
```

### Remove backend resources manually (⚠️ irreversible)

```bash
aws s3 rb "s3://$TF_BACKEND_BUCKET" --force
aws dynamodb delete-table --table-name "$TF_BACKEND_DDB_TABLE"
```

---

## 💡 Best Practices

* ✅ Commit `.terraform.lock.hcl` to lock provider versions
* ❌ Do **not** commit `.terraform/`, `.tfstate`, or build artifacts like `lambda.zip`
* 🧪 Run `terraform fmt` and `terraform validate` before each commit
* 🔒 Enable logging and monitoring (e.g., CloudWatch) for production Lambda functions
* 📦 Separate environments by using different keys (e.g., `envs/dev/terraform.tfstate`)

---