run "cluster_module_validation" {
  command = plan

  variables {
    cluster_name = "test-eks-cluster"
    vpc_id       = "vpc-12345678"
    cluster_vpc_config = {
      private_subnet_ids      = ["subnet-12345678", "subnet-87654321"]
      private_access_cidrs    = ["10.0.0.0/8"]
      public_access_cidrs     = ["0.0.0.0/0"]
      security_group_ids      = ["sg-12345678"]
      endpoint_private_access = true
      endpoint_public_access  = true
    }
  }

  # Test that the cluster module is planned correctly
  assert {
    condition     = module.cluster.cluster_name == "test-eks-cluster"
    error_message = "Cluster name should be set correctly"
  }
}
