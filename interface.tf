variable "environment" {
  description = "The name of our environment, i.e. development."
}

variable "vpc_id" {
  description = "The VPC ID"
}

variable "key_name" {
  description = "The AWS key pair to use for resources."
}

variable "public_subnet_id" {
  default     = ""
  description = "The public subnets to populate."
}

variable "instance_type" {
  default     = "t2.micro"
  description = "The instance type to launch "
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "1"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "2"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "1"
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

output "launch_configuration" {
  value = "${aws_launch_configuration.web.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.web.id}"
}
