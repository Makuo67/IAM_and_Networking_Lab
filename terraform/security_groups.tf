resource "aws_security_group" "public_nat" {
  name        = "public-nat-sg"
  description = "Public NAT SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-nat-sg"
  }
}

resource "aws_security_group" "private_compute" {
  name        = "private-compute-sg"
  description = "Private Compute SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow all traffic from itself"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow all traffic from sg-public-nat"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public_nat.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-compute-sg"
  }
}

resource "aws_security_group" "private_database" {
  name        = "private-db-sg"
  description = "Private Database SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MySQL from sg-private-compute"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private_compute.id]
  }

  ingress {
    description     = "PostgreSQL from sg-private-compute"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.private_compute.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-db-sg"
  }
}
