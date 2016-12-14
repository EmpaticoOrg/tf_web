variable "region" {
  description = "The AWS region."
}

variable "environment" {
  description = "The name of our environment, i.e. development."
}

variable "key_name" {
  description = "The AWS key pair to use for resources."
}

variable "public_subnet_id" {
  default     = ""
  description = "The public subnets to populate."
}

variable "ami" {
  default = {
    "us-east-1" = "ami-f652979b"
    "us-west-1" = "ami-7c4b331c"
  }

  description = "The AMIs to use for web instances."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "The instance type to launch "
}

variable "web_instance_count" {
  default     = 1
  description = "The number of Web instances to create"
}

variable "domain" {
  description = "The domain of the site"
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
