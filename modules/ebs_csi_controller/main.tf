#########################################
# EBS CSI Controller Version Resolver
#########################################

data "aws_region" "current" {}

locals {
  ebs_csi_driver_version = (
    var.ebs_csi_driver_chart_version == null || var.ebs_csi_driver_chart_version == "latest"
  ) ? null : var.ebs_csi_driver_chart_version
}
