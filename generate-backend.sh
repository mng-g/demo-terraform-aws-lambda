#!/bin/bash

# Exit on errors
set -e

# Ensure variables are set
: "${TF_BACKEND_BUCKET:?Missing TF_BACKEND_BUCKET}"
: "${TF_BACKEND_REGION:?Missing TF_BACKEND_REGION}"
: "${TF_BACKEND_DDB_TABLE:?Missing TF_BACKEND_DDB_TABLE}"
: "${TF_BACKEND_KEY:?Missing TF_BACKEND_KEY}"

# Generate backend.tf dynamically
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "${TF_BACKEND_BUCKET}"
    key            = "${TF_BACKEND_KEY}"
    region         = "${TF_BACKEND_REGION}"
    dynamodb_table = "${TF_BACKEND_DDB_TABLE}"
    encrypt        = true
  }
}
EOF

echo "✅ backend.tf generated."
