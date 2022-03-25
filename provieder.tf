# Previous execution of "aws configure" is needed
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Default provider, it will be used when no provider is declared in the resource.
provider "aws" {
  region  = var.aws_region["source"]
  profile = "default"
}

# Provider for Source Bucket
provider "aws" {
  alias   = "source"
  region  = var.aws_region["source"]
  profile = "default"
}

# Provider for Destination Bucket
provider "aws" {
  alias   = "destination"
  region  = var.aws_region["destination"]
  profile = "default"
}