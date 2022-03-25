##AWS Region
#Use: var.aws_region["source"]
variable "aws_region" {
  type = map(string)
  default = {
    "source"      = "us-east-1",
    "destination" = "us-west-2"
  }
}

### Tags Variables ###
#Use: tags = merge(var.project-tags, { Name = "${var.resource-name-tag}-place-holder" }, )
variable "project-tags" {
  type = map(string)
  default = {
    service     = "S3Replication",
    environment = "POC"
    owner       = "example@mail.com"
  }
}

variable "resource-name-tag" {
  type    = string
  default = "S3Replication"
}