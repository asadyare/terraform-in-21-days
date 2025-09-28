data "aws_route53_zone" "main" {
  name = "my-domain.com."
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"


  domain_name         = "my-domain.com"
  zone_id             = data.aws_route53_zone.main.zone_id
  wait_for_validation = true
}

module "external_sg" {
  source = "terraform-aws-modules/security-group/aws"


  name   = "${var.env_code}-external-sg"
  vpc_id = data.terraform_remote_state.level1.outputs.vpc_id


  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "https to ELB"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.8.0"

  name               = var.env_code
  load_balancer_type = "application"
  vpc_id             = data.terraform_remote_state.level1.outputs.vpc_id
  subnets            = data.terraform_remote_state.level1.outputs.public_subnet_id
  security_groups    = [module.external_sg.security_group_id]



  target_groups = {
  tg1 = {
    name_prefix          = var.env_code
    backend_protocol     = "HTTP"
    backend_port         = 80
    deregistration_delay = 10
    health_check = {
      enabled             = true
      interval            = 30
      path                = "/"
      port                = "traffic-port"
      healthy_threshold   = 5
      unhealthy_threshold = 2
      timeout             = 5
      protocol            = "HTTP"
      matcher             = "200"
    }
  }
}

listeners = {
  https = {
    port            = 443
    protocol        = "HTTPS"
    certificate_arn = module.acm.acm_certificate_arn
    default_action = {
      type               = "forward"
      target_group_index = 0
    }
  }
}
}

module "dns" {
  source  = "terraform-aws-modules/route53/aws"
  version = "6.1.0"
  
  
  records = [
    {
      zone_id = data.aws_route53_zone.main.zone_id
      name    = "www"
      type    = "CNAME"
      ttl     = 3600
      records = [module.alb.this_lb_dns_name]
    }
  ]
}



  

