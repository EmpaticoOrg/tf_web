data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

data "template_file" "userdata" {
  template = "${file("files/bootstrap.tpl")}"

  vars {
    consul_address = "consul.${var.domain}"
    environment    = "${var.environment}"
    encryption_key = "${var.encryption_key}"
    name           = "${var.environment}-${var.app}-${var.role}-${count.index}"
  }

  count = "${var.web_instance_count}"
}

resource "aws_instance" "web" {
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.public_subnet_ids[0]}"
  user_data     = "${element(data.template_file.userdata.*.rendered, count.index)}"

  vpc_security_group_ids = [
    "${aws_security_group.web_host_sg.id}",
  ]

  tags {
    Name    = "${var.environment}-${var.app}-${var.role}-${count.index}"
    Project = "${var.app}"
    Stages  = "${var.environment}"
    Roles   = "${var.role}"
  }

  count = "${var.web_instance_count}"
}

resource "aws_elb" "web" {
  name            = "${var.environment}-web-elb"
  subnets         = ["${var.public_subnet_ids[0]}"]
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

  instances = ["${aws_instance.web.*.id}"]
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
  zone_id = "${var.zoneid}"
  name    = "*.${var.domain}"
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.environment.cidr_block}"]
  }

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
