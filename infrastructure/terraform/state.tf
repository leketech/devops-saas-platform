# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "saas-terraform-state"

  tags = {
    Name        = "terraform-state"
    Environment = "shared"
    Purpose     = "terraform-backend"
  }
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
    }
  }
}

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "s3-encryption-key"
  }
}

resource "aws_kms_alias" "s3_encryption_key_alias" {
  name          = "alias/s3-terraform-state"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}

# Block public access to S3 bucket

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "shared"
    Purpose     = "terraform-backend"
  }
}
