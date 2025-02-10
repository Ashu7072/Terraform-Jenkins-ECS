
# Varibles
variable "region" {}

variable "aws_account_id" {}

variable "vpc_id" {}

variable "image_id" {
  default = "ami-04b4f1a9cf54c11d0"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "Local-Key.pem"
}

variable "security_groups" {
  type = list(string)
}
variable "subnet_ids" {
  type = list(string)
}