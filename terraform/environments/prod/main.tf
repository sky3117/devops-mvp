terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "taskmanager-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "taskmanager-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "ap-south-1"
}
variable "db_password" {
  type      = string
  sensitive = true
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = "production"
  az_count    = 3
}

module "eks" {
  source             = "../../modules/eks"
  environment        = "production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_desired_size  = 3
  node_min_size      = 3
  node_max_size      = 10
  node_instance_type = "t3.large"
}

module "rds" {
  source                 = "../../modules/rds"
  environment            = "production"
  private_subnet_ids     = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.vpc.app_security_group_id]
  db_password            = var.db_password
  db_instance_class      = "db.t3.medium"
}

module "s3" {
  source      = "../../modules/s3"
  environment = "production"
}

output "cluster_name" { value = module.eks.cluster_name }
output "db_endpoint" { value = module.rds.endpoint }
output "backup_bucket" { value = module.s3.backup_bucket_name }
