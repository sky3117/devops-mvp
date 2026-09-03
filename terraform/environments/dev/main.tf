terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - prevents local state file conflicts in team environments
  backend "s3" {
    bucket         = "taskmanager-terraform-state-652063276755"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "taskmanager-terraform-locks" # state locking
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
  environment = "dev"
  az_count    = 2
}

module "eks" {
  source              = "../../modules/eks"
  environment         = "dev"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 3
  node_instance_type  = "t3.small"
}

module "rds" {
  source                  = "../../modules/rds"
  environment             = "dev"
  private_subnet_ids      = module.vpc.private_subnet_ids
  vpc_security_group_ids  = [module.vpc.app_security_group_id]
  db_password             = var.db_password
  db_instance_class       = "db.t3.micro"
}

module "s3" {
  source      = "../../modules/s3"
  environment = "dev"
}

output "cluster_name" { value = module.eks.cluster_name }
output "db_endpoint" { value = module.rds.endpoint }
output "backup_bucket" { value = module.s3.backup_bucket_name }
