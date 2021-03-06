# Empatico.org Website module for Terraform

A lightweight Web service module for the Empatico.org site

## Usage

```hcl
module "web" {
  source             = "github.com/EmpaticoOrg/tf_web"
  environment        = "${var.environment}"
  vpc_id             = "${module.vpc.vpc_id}"
  public_subnet_id  = "${module.vpc.public_subnet_id}"
  role               = "${var.role}"
  app                = "${var.app}"
  key_name           = "${var.key_name}"
  domain             = "${var.domain}"
  key                = "${file("files/key.pem")}"
  cert               = "${file("files/cert.pem")}"
}

output "web_elb_address" {
  value = "${module.web.web_elb_address}"
}
```

Assumes you're building your Web service inside a VPC created from [this
module](https://github.com/EmpaticoOrg/tf_vpc).

See `interface.tf` for additional configurable variables.

## License

MIT

