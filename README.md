### Cilium Demo

This is the Infrastructure as Code (IaC) for the 'Enhancing A/B Testing and Observability on AWS EKS with Cilium and eBPF' talk at AWS Community Day Yerevan.

Cilum is installed without any customization so you can check offical docs:

[AWS VPC CNI plugin](https://docs.cilium.io/en/latest/installation/cni-chaining-aws-cni/)\
[Hubble setup](https://docs.cilium.io/en/latest/observability/hubble/setup/#hubble-setup)

Note: When installing the Vector agent, make sure to set IAM roles for the agent pods using helm/vector.yaml (these are the values used for the installation).
