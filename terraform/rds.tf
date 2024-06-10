resource "aws_db_instance" "postgres_rds" {
  identifier           = "postgres-rds"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16.2"
  db_name              = var.DB_NAME
  username             = var.DB_USERNAME
  password             = var.DB_PASSWORD
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.private_subnet_group.name
  skip_final_snapshot  = true
  publicly_accessible  = false

  tags = {
    Name = "PostgreSQL RDS"
  }
}
