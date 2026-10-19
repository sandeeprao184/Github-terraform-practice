variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "The IPv4 CIDR block for the first public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_2_cidr" {
  description = "The IPv4 CIDR block for the second public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "The IPv4 CIDR block for the first private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "The IPv4 CIDR block for the second private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0567589d25e06853e" # Amazon Linux 2 AMI (HVM), SSD Volume Type
}

variable "instance_type" {
  description = "The type of instance to use for the EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "aws_public_key" {
  description = "SSH public key for the AWS key pair"
  type        = string
  sensitive   = true
}
