data "aws_vpc" "environment" {
  id = "${var.vpc_id}"
}

resource "aws_instance" "web" {
  ami           = "${lookup(var.ami, var.region)}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.public_subnet_ids[0]}"
  user_data     = "${file("${path.module}/files/web_bootstrap.sh")}"

  vpc_security_group_ids = [
    "${aws_security_group.web_host_sg.id}",
  ]

  tags {
    Name = "${var.environment}-web-${count.index}"
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
    instance_port = 80
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    #ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.web.*.id}"]
}

resource "aws_route53_zone" "web" {
   name = "${var.domain}"
}

resource "aws_route53_record" "web" {
  zone_id = "${aws_route53_zone.web.zone_id}"
  name = "${var.domain}"
  type = "A"

  alias {
    name = "${aws_elb.web.dns_name}"
    zone_id = "${aws_elb.web.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "${var.environment}-web-inbound"
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
    Name = "${var.environment}-web-inbound-sg"
  }
}

resource "aws_security_group" "web_host_sg" {
  name        = "${var.environment}-web-host"
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
    Name = "${var.environment}-web-host-sg"
  }
}
