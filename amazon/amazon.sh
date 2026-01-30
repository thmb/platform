#!/bin/bash

# =============================================================================
# PREREQUISITES
# =============================================================================
# 
# After AWS account creation:
# 1. Log into AWS Console as root user
# 2. Go to IAM > Users > Create user
# 3. Create a user (e.g., "admin") with "AdministratorAccess" policy
# 4. Generate access keys for the user (Security credentials tab)
# 5. Configure AWS CLI with the admin credentials:
#    $ aws configure
#    AWS Access Key ID: [paste key]
#    AWS Secret Access Key: [paste secret]
#    Default region name: sa-east-1
#    Default output format: json
# 6. Verify CLI access: aws sts get-caller-identity
# 7. Run this script to create service users (terraform, github) and state bucket
#
# =============================================================================

TERRAFORM_USER="terraform"
GITHUB_USER="github"
STATE_BUCKET="raio-storage-state"

# =============================================================================
# TERRAFORM USER
# =============================================================================

# Create User
echo "Creating $TERRAFORM_USER IAM user..."
aws iam create-user --user-name $TERRAFORM_USER 2>/dev/null || echo "User $TERRAFORM_USER already exists"

# Attach Policies
echo "Attaching managed policies to $TERRAFORM_USER user..."

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

aws iam attach-user-policy \
  --user-name $TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Create Access Key
echo "Creating access key for $TERRAFORM_USER user..."
aws iam create-access-key --user-name $TERRAFORM_USER > ${TERRAFORM_USER}-credentials.json

echo ""
echo "✅ Setup complete!"
echo ""
echo "$TERRAFORM_USER user credentials saved to: ${TERRAFORM_USER}-credentials.json"
echo "AWS_ACCESS_KEY_ID: $(jq -r '.AccessKey.AccessKeyId' ${TERRAFORM_USER}-credentials.json)"
echo "AWS_SECRET_ACCESS_KEY: $(jq -r '.AccessKey.SecretAccessKey' ${TERRAFORM_USER}-credentials.json)"
echo ""
echo "⚠️  IMPORTANT: Store these credentials securely and delete ${TERRAFORM_USER}-credentials.json after saving them!"

# =============================================================================
# GITHUB USER
# =============================================================================

# Create User
echo "Creating $GITHUB_USER IAM user..."
aws iam create-user --user-name $GITHUB_USER 2>/dev/null || echo "User $GITHUB_USER already exists"

# Attach Policies
echo "Attaching managed policies to $GITHUB_USER user..."

aws iam attach-user-policy \
  --user-name $GITHUB_USER \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Create Access Key
echo "Creating access key for $GITHUB_USER user..."
aws iam create-access-key --user-name $GITHUB_USER > ${GITHUB_USER}-credentials.json

echo ""
echo "✅ Setup complete!"
echo ""
echo "$GITHUB_USER user credentials saved to: ${GITHUB_USER}-credentials.json"
echo "AWS_ACCESS_KEY_ID: $(jq -r '.AccessKey.AccessKeyId' ${GITHUB_USER}-credentials.json)"
echo "AWS_SECRET_ACCESS_KEY: $(jq -r '.AccessKey.SecretAccessKey' ${GITHUB_USER}-credentials.json)"
echo ""
echo "⚠️  IMPORTANT: Store these credentials securely and delete ${GITHUB_USER}-credentials.json after saving them!"

# =============================================================================
# STATE BUCKET
# =============================================================================

# Create State Bucket
aws s3 mb s3://$STATE_BUCKET --region sa-east-1

# Enable Versioning (history)
aws s3api put-bucket-versioning \
  --bucket $STATE_BUCKET \
  --versioning-configuration Status=Enabled

# Enable Encryption
aws s3api put-bucket-encryption \
  --bucket $STATE_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block Public Access
aws s3api put-public-access-block \
  --bucket $STATE_BUCKET \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"