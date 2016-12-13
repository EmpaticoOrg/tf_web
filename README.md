# Empatico.org Website module for Terraform

A lightweight Web service module for the Empatico.org site

## Usage

```hcl
module "web" {
  source             = "github.com/EmpaticoOrg/tf_web"
  environment        = "${var.environment}"
  vpc_id             = "${module.vpc.vpc_id}"
  public_subnet_ids  = "${module.vpc.public_subnet_ids}"
  private_subnet_ids = "${module.vpc.private_subnet_ids}"
  web_instance_count = "${var.web_instance_count}"
  role               = "${var.role}"
  app                = "${var.app}"
  region             = "${var.region}"
  key_name           = "${var.key_name}"
  domain             = "${var.domain}"
  zoneid             = "${var.zoneid}"
  key                = "${file("files/key.pem")}"
  cert               = "${file("files/cert.pem")}"
}

output "web_elb_address" {
  value = "${module.web.web_elb_address}"
}

output "web_host_addresses" {
  value = ["${module.web.web_host_addresses}"]
}
```

Assumes you're building your Web service inside a VPC created from [this
module](https://github.com/EmpaticoOrg/tf_vpc).

See `interface.tf` for additional configurable variables.

## License

MIT

