locals {
  name                       = "cilium-demo"
  default_availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  eks = {
    node_desired_capacity = 1
    node_min_capacity     = 1
    node_max_capacity     = 3
    version               = "1.32"
    node_instance_types   = ["t3.medium"]
    node_capacity_type    = "ON_DEMAND"
    ami_type              = "AL2023_x86_64_STANDARD"
  }
  vpc = {
    cidr            = "10.130.0.0/18"
    public_subnets  = ["10.130.0.0/22", "10.130.4.0/22", "10.130.8.0/22"]
    private_subnets = ["10.130.12.0/22", "10.130.16.0/22", "10.130.20.0/22"]
  }
  vector = {
    namespace      = "vector"
    sevice_account = "vector"
  }
}
