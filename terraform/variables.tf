variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "data-platform"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "az_a" {
  description = "First availability zone"
  type        = string
  default     = "eu-west-1a"
}

variable "az_b" {
  description = "Second availability zone"
  type        = string
  default     = "eu-west-1b"
}

variable "enable_nat_gateway" {
  description = "Whether to create the NAT Gateway and its Elastic IP (they incur hourly charges)"
  type        = bool
  default     = false
}
