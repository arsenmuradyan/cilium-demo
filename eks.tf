module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.31"
  cluster_name                             = local.name
  cluster_version                          = local.eks.version
  cluster_endpoint_public_access           = true
  subnet_ids                               = module.vpc.private_subnets
  enable_irsa                              = true
  vpc_id                                   = module.vpc.vpc_id
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      desired_size   = local.eks.node_desired_capacity
      max_size       = local.eks.node_max_capacity
      min_size       = local.eks.node_min_capacity
      instance_types = local.eks.node_instance_types
      capacity_type  = local.eks.node_capacity_type
      ami_type       = local.eks.ami_type
      subnet_ids     = module.vpc.private_subnets
      taints = [
        {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      ]
      additional_tags = {
        EKS = local.name
      }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            iops                  = 100
            throughput            = 150
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }
}
