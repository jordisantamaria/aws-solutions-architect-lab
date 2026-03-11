# Lab 00: Initial Setup

## Description

This lab guides you through the initial configuration needed to work with AWS and Terraform. You will configure the base tools and create the infrastructure needed to manage Terraform state remotely.

## Prerequisites

- AWS account (Free Tier is sufficient to start)
- Terminal (bash/zsh)
- Text editor (VS Code recommended)

---

## Step 1: Install AWS CLI v2

### macOS

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Verify installation

```bash
aws --version
```

---

## Step 2: Configure AWS Credentials

### Option A: Basic configuration

```bash
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name: eu-west-1
# Default output format: json
```

### Option B: Use profiles (recommended)

```bash
aws configure --profile aws-lab
# Enter your credentials

# To use the profile:
export AWS_PROFILE=aws-lab

# Verify it works:
aws sts get-caller-identity --profile aws-lab
```

> **Best practice:** Never use root user credentials. Create an IAM user with administrator permissions for the labs.

---

## Step 3: Install Terraform

### macOS (with Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Linux

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Verify installation

```bash
terraform version
```

---

## Step 4: Create Remote Backend for Terraform State

### Why a remote backend?

By default, Terraform saves state (`terraform.tfstate`) in a local file. This has several problems:

1. **State locking:** Without locking, if two people run `terraform apply` at the same time, they can corrupt the state. DynamoDB provides distributed locking.
2. **Collaboration:** With local state, each team member has their own version. S3 centralizes the state for the entire team.
3. **Security:** The state file contains sensitive information (IPs, ARNs, sometimes passwords). S3 allows encryption and access control with IAM.
4. **Durability:** S3 offers 99.999999999% durability. A local disk can fail.
5. **Versioning:** With versioning on S3, you can recover previous states if something goes wrong.

### Deploy the backend

```bash
cd labs/00-setup

# Initialize Terraform (local backend for this first step)
terraform init

# Review the plan
terraform plan -var="project_name=aws-lab" -var="environment=dev"

# Apply
terraform apply -var="project_name=aws-lab" -var="environment=dev"
```

### Verify

```bash
# Verify the bucket exists
aws s3 ls | grep aws-lab

# Verify the DynamoDB table
aws dynamodb list-tables
```

---

## Step 5: Configure the Backend in Subsequent Labs

Once the bucket and table are created, the subsequent labs will use this backend. You will see a `backend.tf` file in each lab with the corresponding configuration.

```hcl
terraform {
  backend "s3" {
    bucket         = "aws-lab-dev-terraform-state"
    key            = "lab-XX/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "aws-lab-dev-terraform-lock"
    encrypt        = true
  }
}
```

---

## Cleanup

> **Important:** Do NOT destroy this lab until you have finished all the others, since the remote backend is needed for the rest of the labs.

```bash
terraform destroy -var="project_name=aws-lab" -var="environment=dev"
```

---

## File Structure

```
00-setup/
  main.tf          # Main resources (S3 bucket, DynamoDB table)
  variables.tf     # Input variables
  outputs.tf       # Output values
  README.md        # This file
```
