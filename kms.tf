#Create a Multi Region Key
resource "aws_kms_key" "S3EncryptionKey" {
  provider = aws.source

  description             = "S3 Encryption Key"
  deletion_window_in_days = 15
  multi_region            = true
  tags                    = merge(var.project-tags, { Name = "${var.resource-name-tag}-kms" }, )
}

#Source Key Alias
resource "aws_kms_alias" "S3EncryptionKey_Alias" {
  provider = aws.source

  name          = "alias/S3EncryptionKey-${var.aws_region["source"]}"
  target_key_id = aws_kms_key.S3EncryptionKey.key_id
}

#Replicate key to another region
resource "aws_kms_replica_key" "S3EncryptionKey_Replica" {
  provider = aws.destination

  description             = "S3 Encryption Replica key"
  deletion_window_in_days = 15
  primary_key_arn         = aws_kms_key.S3EncryptionKey.arn
  tags                    = merge(var.project-tags, { Name = "${var.resource-name-tag}-kms" }, )
}

#Destination Key Alias
resource "aws_kms_alias" "S3EncryptionKey_Replica_Alias" {
  provider = aws.destination

  name          = "alias/S3EncryptionKey-${var.aws_region["destination"]}"
  target_key_id = aws_kms_replica_key.S3EncryptionKey_Replica.key_id
}