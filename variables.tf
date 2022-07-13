# private key local path(vagrant path)
variable "private_key_file_path_var" {
  default = "/home/vagrant/.ssh/EC2Tutorial.pem"
}

# authentication key name
variable "key_name_var" {
    default = "EC2 Tutorial"
}

# AWS instance type
variable "instance_type_var" {
  default = "t2.micro"
}

variable "amazon_linux_webserver_ami_id_var" {
  default = "ami-0f9da006345383dd6"
}

#Region name
variable "region_var" {
    default = "eu-west-2"
}

# VPC name extraction from terraform
locals {
  vpc_id_var = aws_vpc.terraform_daniel_vpc_tf.id
}