variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "db_instance_class" {
  default = "db.t3.micro"
}
variable "db_name" {
  default = "taskdb"
}
variable "db_username" {
  default = "taskuser"
}
variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier             = "${var.environment}-taskmanager-db"
  engine                 = "postgres"
  engine_version         = "16.15"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids
  multi_az               = var.environment == "production"
  backup_retention_period = var.environment == "production" ? 7 : 1
  skip_final_snapshot    = var.environment != "production"
  deletion_protection    = var.environment == "production"

  tags = { Environment = var.environment }
}

output "endpoint" { value = aws_db_instance.main.endpoint }
output "db_name" { value = aws_db_instance.main.db_name }
