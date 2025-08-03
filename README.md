# 🚀 demo-terraform-aws-lambda

This project demonstrates how to deploy AWS Lambda functions using Terraform with a **remote backend** powered by **S3** and **DynamoDB** for secure, team-friendly state management. It supports **isolated workspaces** for `dev`, `test`, and `prod`.

---

## 🌱 Prerequisites

- AWS CLI installed and configured
- Terraform installed
- Make installed (for using the Makefile)
- AWS credentials with permissions to manage S3, DynamoDB, Lambda, IAM, API Gateway, etc.

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

# Key (path) to the Terraform state file in S3.
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

## ▶️ Workspace-based Environment Management

This project uses **Terraform workspaces** to manage `dev`, `test`, and `prod`.

---

## 🛠️ Makefile Usage

```bash
# Generate backend.tf file
make backend

# Initialize environment (create workspace if it doesn’t exist)
make init ENV=dev

# Plan infrastructure changes
make plan ENV=dev

# Apply infrastructure
make apply ENV=dev

# Destroy resources
make destroy ENV=dev

# Clean zip file
make clean
```

---

## 🧪 Test Your Deployed API

After applying Terraform, you can test the Lambda API endpoints:

```bash
# Health check
curl "$(terraform output -raw api_url)/healthz"

# S3 test
curl "$(terraform output -raw api_url)/api/s3-test"

# RDS test
curl "$(terraform output -raw api_url)/api/rds-test"
```

---

## 🔧 Lambda Output

Each Lambda endpoint returns a JSON response. Example outputs:

### Health check
```json
{"status": "ok"}
```

### S3 test
```json
{
  "bucket": "your-bucket-name",
  "success": true,
  "files": ["file1.txt", "file2.txt"],
  "error": null
}
```

### RDS test
```json
{
  "success": true,
  "db_version": "PostgreSQL 14.5 on ...",
  "error": null
}
```

If there is an error (missing env, connection failure, etc), the output will look like:
```json
{
  "success": false,
  "error": "...error message..."
}
```

---

## ✅ Verify Backend Resources

```bash
aws s3api list-buckets
aws dynamodb list-tables
aws dynamodb describe-table --table-name "$TF_BACKEND_DDB_TABLE"
```

---

## ⚠️ Note on psycopg2-binary for Lambda

To use the `psycopg2-binary` library with AWS Lambda (Python 3.11), you must build it in an environment compatible with Lambda's Amazon Linux OS. The following Docker command was used to build the dependency in the correct format:

```bash
docker run --rm -v "$PWD/src":/var/task amazonlinux:2023 /bin/bash -c "
  yum install -y python3.11 python3.11-devel gcc postgresql-devel &&
  python3.11 -m ensurepip &&
  python3.11 -m pip install --upgrade pip &&
  python3.11 -m pip install psycopg2-binary -t /var/task
"
```

This ensures that the Lambda deployment package contains a version of `psycopg2-binary` that works on AWS Lambda Python 3.11 runtimes.

---

## 🧹 Cleanup

### Destroy Terraform-managed infrastructure

```bash
make destroy ENV=dev
```

### Remove backend resources manually (⚠️ irreversible)

```bash
aws s3 rb "s3://$TF_BACKEND_BUCKET" --force
aws dynamodb delete-table --table-name "$TF_BACKEND_DDB_TABLE"
```

---

## 💡 Best Practices

* ✅ Use Terraform workspaces for true environment separation
* ✅ Commit `.terraform.lock.hcl` to lock provider versions
* ❌ Do **not** commit `.terraform/`, `.tfstate`, or `lambda.zip`
* 🧪 Run `terraform fmt` and `terraform validate` before each commit
* 🔒 Enable logging and monitoring (e.g., CloudWatch) for production Lambda functions
* 🔁 Add GitHub Actions for CI/CD automation
