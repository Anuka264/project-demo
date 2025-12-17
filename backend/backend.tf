terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create the S3 bucket that will *later* be used as a backend
resource "aws_s3_bucket" "s3_remote_backend" {
  bucket = "devops-automation-project-demo-11122334-anuka"

  lifecycle {
  prevent_destroy = false
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.s3_remote_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.s3_remote_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#Create the DynamoDB table for locking
resource "aws_dynamodb_table" "synamodb_lock_table" {
 name         = "terraform-locks"
 billing_mode = "PAY_PER_REQUEST"
 hash_key     = "LockID"

 attribute {
   name = "LockID"
   type = "S"
 }
}