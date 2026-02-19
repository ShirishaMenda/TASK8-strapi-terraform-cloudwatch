resource "aws_db_subnet_group" "rds_subnet" {
  name = "strapi-db-subnet"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}


resource "aws_db_instance" "postgres" {
  identifier        = "strapi-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "postgres"
  password = "postgres123"

  db_name = "strapidb"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name

  skip_final_snapshot = true
}
