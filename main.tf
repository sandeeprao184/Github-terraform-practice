provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "custom-vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "custom-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# Private subnets
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "${var.region}a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "${var.region}b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "custom-igw" {
  vpc_id = aws_vpc.custom-vpc.id

  tags = {
    Name = "custom-igw"
  }
}

# Public route table
resource "aws_route_table" "custom-route-table" {
  vpc_id = aws_vpc.custom-vpc.id

  tags = {
    Name = "custom-route-table"
  }
}

resource "aws_route" "custom-route" {
  route_table_id         = aws_route_table.custom-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.custom-igw.id
}

resource "aws_route_table_association" "public-subnet-1-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.custom-route-table.id
}

resource "aws_route_table_association" "public-subnet-2-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.custom-route-table.id
}

# NAT Gateway
resource "aws_eip" "custom-eip" {
  domain = "vpc"

  tags = {
    Name = "custom-eip"
  }
}

resource "aws_nat_gateway" "custom-nat-gateway" {
  allocation_id = aws_eip.custom-eip.id
  subnet_id     = aws_subnet.public-subnet-1.id

  depends_on = [
    aws_internet_gateway.custom-igw
  ]

  tags = {
    Name = "custom-nat-gateway"
  }
}

# Private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.custom-vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "private-route" {
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.custom-nat-gateway.id
}

resource "aws_route_table_association" "private-subnet-1-association" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-subnet-2-association" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-route-table.id
}

# Bastion security group
resource "aws_security_group" "custom-sg" {
  name        = "custom-sg"
  description = "SSH access to the bastion host"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    description = "SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "custom-sg"
  }
}

# Application Load Balancer security group
resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to the application load balancer"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg"
  }
}

# Private instance security group
resource "aws_security_group" "private-instance-sg" {
  name        = "private-instance-sg"
  description = "SSH from bastion and HTTP from ALB"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    description     = "SSH from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.custom-sg.id]
  }

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-instance-sg"
  }
}

# EC2 key pair
resource "aws_key_pair" "custom-keypair" {
  key_name   = "custom-keypair"
  public_key = trimspace(var.aws_public_key)

  tags = {
    Name = "custom-keypair"
  }
}

# Bastion host
resource "aws_instance" "bastion-host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.custom-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.custom-keypair.key_name

  tags = {
    Name = "bastion-host"
  }
}

# Private EC2 instance
resource "aws_instance" "private-instance-1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private-subnet-1.id
  vpc_security_group_ids = [aws_security_group.private-instance-sg.id]
  key_name               = aws_key_pair.custom-keypair.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "Private instance 1 healthy" > /var/www/html/index.html
  EOF

  tags = {
    Name = "private-instance-1"
  }
}

# Application Load Balancer target group
resource "aws_lb_target_group" "custom-target-group" {
  name        = "custom-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.custom-vpc.id

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "custom-target-group"
  }
}

resource "aws_lb_target_group_attachment" "private-instance-1-tg-attachment" {
  target_group_arn = aws_lb_target_group.custom-target-group.arn
  target_id        = aws_instance.private-instance-1.id
  port             = 80
}

# Application Load Balancer
resource "aws_lb" "custom-load-balancer" {
  name               = "custom-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]

  subnets = [
    aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id
  ]

  tags = {
    Name = "custom-load-balancer"
  }
}

# HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.custom-load-balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.custom-target-group.arn
  }
}

# Outputs
output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion-host.public_ip
}

output "private_instance_ip" {
  description = "Private IP address of the private EC2 instance"
  value       = aws_instance.private-instance-1.private_ip
}

output "load_balancer_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.custom-load-balancer.dns_name
}
