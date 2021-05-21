variable "name" {
    default = "kong4fargate"
}
variable "environment" {
    default = "prod"
}
variable "additional_tags" {
    description = "Extra AWS Resource tags"
    default = { "Name" : "Kong4Fargate" }
}
variable "region" {
    description = "AWS Region"
    default = "us-east-2"
}
variable "aws_access_key" {
    description = "AWS Access Key ID"
}
variable "aws_secret_key" {
    description = "AWS Access Key Secret" 
}
variable "availability_zones" {
    description = "AWS VPC Availability Zones"
    default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}
variable "ecs_service_security_groups" {
    default = []
}
variable "cidr" {
    description = "AWS VPC Subnet Allocation"
    default = "192.19.0.0/16"
}
variable "public_subnets" {
    description = "Public | AWS Availability Zone Subnet CIDR List"
    default = ["192.19.0.0/24", "192.19.1.0/24", "192.19.2.0/24"]
}
variable "private_subnets" {
    description = "Private | AWS Availability Zone Subnet CIDR List"
    default = ["192.19.10.0/24", "192.19.11.0/24", "192.19.12.0/24"]
}