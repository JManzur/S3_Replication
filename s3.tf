# Generate a 5-digit random number
resource "random_id" "random" {
  byte_length = 2
}

#-------------------------------------
# Source S3 Bucket
#------------------------------------

#Create the Bucket
resource "aws_s3_bucket" "source_bucket" {
  provider = aws.source
  bucket   = "replication-source-${random_id.random.dec}"

  tags = merge(var.project-tags, { Name = "${var.resource-name-tag}-source" }, )
}

#Make the Bucket private
resource "aws_s3_bucket_acl" "source_bucket_acl" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id
  acl      = "private"
}

# Block all public access to bucket and objects
resource "aws_s3_bucket_public_access_block" "source_bucket_lock" {
  provider = aws.source
  bucket   = aws_s3_bucket.source_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Versioning on Source Bucket
resource "aws_s3_bucket_versioning" "source" {
  provider = aws.source

  bucket = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Enble Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  provider   = aws.source
  bucket     = aws_s3_bucket.source_bucket.bucket
  depends_on = [aws_kms_key.S3EncryptionKey]

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.S3EncryptionKey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#-------------------------------------
# Destination S3 Bucket
#------------------------------------

#Create the Bucket
resource "aws_s3_bucket" "destination_bucket" {
  provider = aws.destination
  bucket   = "replication-destination-${random_id.random.dec}"

  tags = merge(var.project-tags, { Name = "${var.resource-name-tag}-destination" }, )
}

#Make the Bucket private
resource "aws_s3_bucket_acl" "destination_bucket_acl" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination_bucket.id
  acl      = "private"
}

# Block all public access to bucket and objects
resource "aws_s3_bucket_public_access_block" "destination_bucket_lock" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Versioning on Destination Bucket
resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.destination

  bucket = aws_s3_bucket.destination_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Enble Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  provider = aws.destination

  bucket     = aws_s3_bucket.destination_bucket.bucket
  depends_on = [aws_kms_replica_key.S3EncryptionKey_Replica]

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_replica_key.S3EncryptionKey_Replica.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#-------------------------------------
# S3 Bucket Replication Configuration
#-------------------------------------

/* 
NOTE: Replicating existing objects is not supported by the Amazon S3 resource at this time (March 2022).
To replicate existing objest use the AWS CLI:
Ref.: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html
*/
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.source

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_kms_replica_key.S3EncryptionKey_Replica
  ]

  role   = aws_iam_role.S3Replication_policy_role.arn
  bucket = aws_s3_bucket.source_bucket.id

  rule {
    id     = "S3-Replication-Rule"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.destination_bucket.arn
      storage_class = "STANDARD"
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.S3EncryptionKey_Replica.arn
      }
    }
  }
}

#-------------------------------------
# Print Buckets name on console
#------------------------------------

output "source_bucket_name" {
  value       = aws_s3_bucket.source_bucket.bucket
  description = "Source Bucket Name"
  sensitive   = false
}

output "destination_bucket_name" {
  value       = aws_s3_bucket.destination_bucket.bucket
  description = "Destination Bucket Name"
  sensitive   = false
}