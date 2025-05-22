module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5.2"

  name                    = local.name
  cidr                    = local.vpc.cidr
  azs                     = local.default_availability_zones
  public_subnets          = local.vpc.public_subnets
  private_subnets         = local.vpc.private_subnets
  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw         = true
  enable_nat_gateway = true

  # Additional tags
  public_subnet_tags = {
    Type = "public"
  }

  private_subnet_tags = {
    Type = "private"
  }
}
