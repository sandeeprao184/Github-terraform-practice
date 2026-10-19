variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "IPv4 CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "IPv4 CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "IPv4 CIDR block for private subnet 1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "IPv4 CIDR block for private subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "ami_id" {
  description = "AMI ID valid in the selected AWS region"
  type        = string
  default     = "ami-0567589d25e06853e"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "aws_public_key" {
  description = "SSH public key for the AWS key pair"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_cidr" {
  description = "Trusted public IPv4 CIDR allowed to SSH to the bastion host"
  type        = string
}
