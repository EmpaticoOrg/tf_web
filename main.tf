data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

data "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

data "aws_ami" "base_ami" {
  filter {
    name   = "tag:Role"
    values = ["base"]
  }

  most_recent = true
}

data "aws_security_group" "core" {
  filter {
    name   = "tag:Name"
    values = ["core-to-${var.environment}-sg"]
  }
}

resource "aws_iam_instance_profile" "consul" {
  name_prefix = "consul"
  roles       = ["ConsulInit"]
}

resource "aws_launch_configuration" "web" {
  name_prefix          = "${var.environment}-${var.app}-${var.role}-"
  image_id             = "${data.aws_ami.base_ami.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.consul.name}"

  security_groups = ["${aws_security_group.web_host_sg.id}",
    "${data.aws_security_group.core.id}",
  ]

  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/files/web_bootstrap.sh")}"
  key_name                    = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "${aws_launch_configuration.web.name}-asg"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.web.name}"
  load_balancers       = ["${aws_elb.web.name}"]
  vpc_zone_identifier  = ["${var.public_subnet_id}"]
  wait_for_elb_capacity     = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.role}-${var.app}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "Role"
    value               = "${var.role}"
    propagate_at_launch = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web" {
  name            = "${var.environment}-web-elb"
  subnets         = ["${var.public_subnet_id}"]
  security_groups = ["${aws_security_group.web_inbound_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.test.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  access_logs {
    bucket = "empatico-elb-logs"
    bucket_prefix = "${var.environment}-${var.app}"
    enabled = true
  }
}

resource "aws_iam_server_certificate" "test" {
  name_prefix      = "test"
  certificate_body = "${var.cert}"
  private_key      = "${var.key}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "web" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "www.${data.aws_route53_zone.domain.name}"
  type    = "A"

  alias {
    name                   = "${aws_elb.web.dns_name}"
    zone_id                = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "${var.environment}-${var.app}-${var.role}-inbound"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${data.aws_vpc.environment.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.app}-${var.role}-inbound-sg"
  }
}

resource "aws_security_group" "web_host_sg" {
  name        = "${var.environment}-${var.app}-${var.role}-host"
  description = "Allow SSH and HTTP to web hosts"
  vpc_id      = "${data.aws_vpc.environment.id}"

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-${var.app}-${var.role}-host-sg"
  }
}
