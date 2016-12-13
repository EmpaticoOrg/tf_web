variable "region" {
  description = "The AWS region."
}

variable "environment" {
  description = "The name of our environment, i.e. development."
}

variable "encryption_key" {
  description = "The Consul encryption key"
}

variable "mastertoken" {
  description = "Consul master token"
}

variable "key_name" {
  description = "The AWS key pair to use for resources."
}

variable "public_subnet_ids" {
  default     = []
  description = "The list of public subnets to populate."
}

variable "private_subnet_ids" {
  default     = []
  description = "The list of private subnets to populate."
}

variable "ami" {
  default = {
    "us-east-1" = "ami-f652979b"
    "us-west-1" = "ami-7c4b331c"
  }

  description = "The AMIs to use for web and app instances."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "The instance type to launch "
}

variable "web_instance_count" {
  default     = 1
  description = "The number of Web instances to create"
}

variable "vpc_id" {
  description = "The VPC ID to launch in"
}

variable "domain" {
  description = "The domain of the site"
}

variable "zoneid" {
  description = "Route 53 Zone ID"
}

variable "key" {
  default     = ""
  description = "Private key"
}

variable "cert" {
  default     = ""
  description = "Certificate"
}

variable "app" {
  description = "Name of application"
}

variable "role" {
  description = "Role of servers"
}

output "web_elb_address" {
  value = "${aws_elb.web.dns_name}"
}

output "web_host_addresses" {
  value = ["${aws_instance.web.*.private_ip}"]
}
