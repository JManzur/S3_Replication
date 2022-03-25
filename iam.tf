/* IAM Role: Allow S3 to assume the role for replication */

# S3 Replication Policy Document
data "aws_iam_policy_document" "policy_source" {
  statement {
    sid    = "GetSourceBucketConfiguration"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.source_bucket.arn}"
    ]
  }

  statement {
    sid    = "GetObjectDetails"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "${aws_s3_bucket.source_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "ReplicateToDestination"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = [
      "${aws_s3_bucket.destination_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "S3Decrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "${aws_kms_key.S3EncryptionKey.arn}"
    ]
  }

  statement {
    sid    = "S3Encrypt"
    effect = "Allow"
    actions = [
      "kms:Encrypt"
    ]
    resources = [
      "${aws_kms_replica_key.S3EncryptionKey_Replica.arn}"
    ]
  }
}

# S3 Assume Role Policy Document
data "aws_iam_policy_document" "role_source" {
  statement {
    sid    = "s3ReplicationAssume"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy
resource "aws_iam_policy" "S3Replication_policy" {
  name        = "S3Replication_policy"
  path        = "/"
  description = "S3 Replication"
  policy      = data.aws_iam_policy_document.policy_source.json
  tags        = merge(var.project-tags, { Name = "${var.resource-name-tag}-policy" }, )
}

# IAM Role
resource "aws_iam_role" "S3Replication_policy_role" {
  name               = "S3Replication_policy_role"
  assume_role_policy = data.aws_iam_policy_document.role_source.json
  tags               = merge(var.project-tags, { Name = "${var.resource-name-tag}-role" }, )
}

# Attach Role and Policy
resource "aws_iam_role_policy_attachment" "S3Replication_attach" {
  role       = aws_iam_role.S3Replication_policy_role.name
  policy_arn = aws_iam_policy.S3Replication_policy.arn
}