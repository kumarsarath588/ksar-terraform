variable "region" {
    description = "Aws region"
    default     = "us-west-1"
}

variable "ami_id" {}

variable "instance_type" {}

variable "vpc_subnet_id" {}

variable "security_groups" {}

variable "keypair" {}

variable "DB_NAME" {}

variable "DB_USER" {}

variable "DB_PASS" {}

variable "DB_PORT" {
    default = "3306"
}