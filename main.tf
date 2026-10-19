provider "aws" {
  region = "us-east-1"
}
# vpc 
resource "aws_vpc" "custom-vpc" {
  cidr_block = var.aws_vpc_cidr
  enable_dns_support   = true
  tags = {
    Name = "custom-vpc"
  }
}
#public subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.custom-vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

#private subnets
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

#internet gateway
resource "aws_internet_gateway" "custom-igw" {
  vpc_id = aws_vpc.custom-vpc.id
  tags = {
    Name = "custom-igw"
  }
}

#route table
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

#nat gateway
resource "aws_eip" "custom-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "custom-nat-gateway" {
  allocation_id = aws_eip.custom-eip.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "custom-nat-gateway"
  }
}

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

#security group
resource "aws_security_group" "custom-sg" {
  name        = "custom-sg"
  description = "SSH access to the bastion host"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
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
}

resource "aws_security_group" "private-instance-sg" {
  name        = "private-instance-sg"
  description = "SSH access from the bastion host and HTTP access from the ALB"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.custom-sg.id]
  }

  ingress {
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
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to the application load balancer"
  vpc_id      = aws_vpc.custom-vpc.id

  ingress {
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
}

#ec2 instance
resource "aws_instance" "bastion-host" {
  ami                         = var.ami_id # Amazon Linux 2 AMI
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.custom-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.custom-keypair.key_name

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_instance" "private-instance-1" {
  ami                    = var.ami_id # Amazon Linux 2 AMI
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

resource "aws_key_pair" "custom-keypair" {
  key_name   = "custom-keypair"
  public_key = file(pathexpand("~/.ssh/custom-keypair.pub"))
}

output "bastion_public_ip" {
  value = aws_instance.bastion-host.public_ip
}

output "private_instance_ip" {
  value = aws_instance.private-instance-1.private_ip
}

#target group
resource "aws_lb_target_group" "custom-target-group" {
  name        = "custom-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.custom-vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "private-instance-1-tg-attachment" {
  target_group_arn = aws_lb_target_group.custom-target-group.arn
  target_id        = aws_instance.private-instance-1.id
  port             = 80
}

#load balancer
resource "aws_lb" "custom-load-balancer" {
  name               = "custom-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

  tags = {
    Name = "custom-load-balancer"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.custom-load-balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.custom-target-group.arn
  }
}

output "load_balancer_dns_name" {
  value = aws_lb.custom-load-balancer.dns_name
}