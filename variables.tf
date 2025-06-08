variable "aws_region" {
  description = "Region in which the infrastructure will be deployed"
  type        = string
}

variable "credential_path" {
  description = "Contains the path to the credentials in local machine"
  type        = string
}

variable "instance_tenacy" {
  description = "Describes the instance tenacy"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Contains the cidr of the vpc"
  type        = string
}

variable "subnet_details" {
  description = "Contains info about subnet tag, subnet cidr"
  type = list(object({
    subnet_tag  = string
    subnet_cidr = string
  }))
}

variable "availability_zone" {
  description = "Contains the AZ in which infrastructure will be deployed"
  type        = string
  default     = "us-east-1a"
}

variable "igw_name" {
  description = "Name of the internet gateway"
  type        = string
}

variable "sg_name_public" {
  description = "Name of the security group attached to public instance"
  type        = string
}

variable "sg_name_private" {
  description = "Name of the security group attached to private instance"
  type        = string
}

variable "inbound_rule_source_public" {
  description = "Mention the source for inbound rule"
  type        = string
  default     = "0.0.0.0/0"
}

variable "outbound_rule_source_public" {
  description = "Mention the source for outbound rule"
  type        = string
}

variable "instance_type" {
  description = "Mention the type of instance to be deployed"
  type        = string
  default     = "t2.micro"
}

variable "instance_tag" {
  description = "Tag associated to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the key that will be attached to an EC2 instance"
  type        = string
}

variable "elastic_ip_tag" {
  description = "Tag associated to eip"
  type        = string
}

variable "nat_gateway_tag" {
  description = "Tag associated to nat gateway"
  type        = string
}

variable "public_cidr" {
  description = "Represents the cidr for public subnet"
  type        = string
}

variable "private_cidr" {
  description = "Represents the cidr for private subnet"
  type        = string
}

variable "public_subnet_tag" {
  description = "Represents the tag for public subnet"
  type        = string
}

variable "private_subnet_tag" {
  description = "Represents the tag for private subnet"
  type        = string
}
