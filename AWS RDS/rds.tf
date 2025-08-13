# RDS Subnet Group
resource "aws_db_subnet_group" "mariadb-subnets" {
  name        = "mariadb-subnets"
  description = "Amazon RDS subnet group"
  subnet_ids  = [
    aws_subnet.levelupvpc-private-1.id,
    aws_subnet.levelupvpc-private-2.id
  ]

  tags = {
    Name = "mariadb-subnets"
  }
}

# RDS Parameter Group for MariaDB 10.6
resource "aws_db_parameter_group" "levelup-mariadb-parameters" {
  name        = "levelup-mariadb-parameters"
  family      = "mariadb10.6"  # ✅ matches engine version
  description = "Custom parameter group for MariaDB 10.6"

  parameter {
    name  = "max_allowed_packet"
    value = "16777216"
  }

  tags = {
    Name = "mariadb-parameters"
  }
}

# RDS Instance
resource "aws_db_instance" "levelup-mariadb" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mariadb"
  engine_version          = "10.6.21"
  instance_class          = "db.t3.micro"  # Free-tier eligible
  identifier              = "mariadb-instance"  # ✅ must be unique
  db_name                 = "mariadb"
  username                = "root"
  password                = "mariadb141"

  db_subnet_group_name    = aws_db_subnet_group.mariadb-subnets.name
  parameter_group_name    = aws_db_parameter_group.levelup-mariadb-parameters.name
  multi_az                = false
  vpc_security_group_ids  = [aws_security_group.allow-mariadb.id]
  backup_retention_period = 30
  availability_zone       = aws_subnet.levelupvpc-private-1.availability_zone
  skip_final_snapshot     = true

  tags = {
    Name = "levelup-mariadb"
  }
}

# Output the RDS endpoint
output "rds_endpoint" {
  value = aws_db_instance.levelup-mariadb.endpoint
}
