data "aws_security_group" "eks_node_security_group" {
  id = module.eks.node_security_group_id
}
data "aws_security_group" "eks_primary_security_group" {
  id = module.eks.cluster_primary_security_group_id
}



# For demo purposes open all traffic in internal nodes and for cluster
# Not recommennded for production deployment
resource "aws_security_group_rule" "ingress_rule_node_to_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = data.aws_security_group.eks_node_security_group.id
  description       = "Open all ports for node to node communication"
}
resource "aws_security_group_rule" "ingress_rule_cluster_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = data.aws_security_group.eks_primary_security_group.id
  security_group_id        = data.aws_security_group.eks_node_security_group.id
  description              = "Open all ports for cluster to node"
}
resource "aws_security_group_rule" "open_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.eks_primary_security_group.id
  description       = "Open all ports for cluster"
}
resource "aws_security_group_rule" "egress_rule_node_to_node" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = data.aws_security_group.eks_node_security_group.id
  description       = "Allow all egress communication"
}
