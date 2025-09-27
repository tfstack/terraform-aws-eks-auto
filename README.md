# terraform-aws-eks-auto

Terraform module for deploying an AWS EKS cluster in Auto Mode with fully managed compute

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.36.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.6 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_addons"></a> [addons](#module\_addons) | ./modules/addons | n/a |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ./modules/cluster | n/a |
| <a name="module_container_insights"></a> [container\_insights](#module\_container\_insights) | ./modules/container_insights | n/a |
| <a name="module_ebs_csi_controller"></a> [ebs\_csi\_controller](#module\_ebs\_csi\_controller) | ./modules/ebs_csi_controller | n/a |
| <a name="module_namespaces"></a> [namespaces](#module\_namespaces) | ./modules/namespaces | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apps"></a> [apps](#input\_apps) | n/a | <pre>list(object({<br/>    name           = string<br/>    image          = string<br/>    port           = number<br/>    namespace      = optional(string, "default")<br/>    labels         = optional(map(string), {})<br/>    enable_logging = optional(bool, false)<br/>    replicas       = optional(number, 1)<br/>    autoscaling    = optional(object({ enabled = bool }), { enabled = false })<br/>    resources      = optional(object({ limits = optional(map(string)), requests = optional(map(string)) }), null)<br/>    env            = optional(list(object({ name = string, value = string })), [])<br/>    healthcheck = optional(object({<br/>      liveness = optional(object({<br/>        http_get              = object({ path = string, port = number })<br/>        initial_delay_seconds = number<br/>        period_seconds        = number<br/>      }))<br/>      readiness = optional(object({<br/>        http_get              = object({ path = string, port = number })<br/>        initial_delay_seconds = number<br/>        period_seconds        = number<br/>      }))<br/>    }), { liveness = null, readiness = null })<br/>    volume_mounts = optional(list(object({ name = string, mount_path = string })), [])<br/>    volumes = optional(list(object({<br/>      name                    = string<br/>      persistent_volume_claim = object({ claim_name = string })<br/>    })), [])<br/>    init_containers = optional(list(object({ name = string, image = string, command = list(string) })), [])<br/>    node_selector   = optional(map(string), {})<br/>    tolerations = optional(list(object({<br/>      key      = string<br/>      operator = optional(string, "Equal")<br/>      value    = optional(string)<br/>      effect   = optional(string)<br/>    })), [])<br/>    image_pull_secrets = optional(list(string), [])<br/>    pod_annotations    = optional(map(string), {})<br/>    security_context = optional(object({<br/>      run_as_user  = optional(number)<br/>      run_as_group = optional(number)<br/>      fs_group     = optional(number)<br/>    }), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of enabled cluster log types | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_node_pools"></a> [cluster\_node\_pools](#input\_cluster\_node\_pools) | Node pools for EKS Auto Mode (valid: general-purpose, system) | `list(string)` | <pre>[<br/>  "general-purpose"<br/>]</pre> | no |
| <a name="input_cluster_upgrade_policy"></a> [cluster\_upgrade\_policy](#input\_cluster\_upgrade\_policy) | Upgrade policy for EKS cluster | <pre>object({<br/>    support_type = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Kubernetes version | `string` | `"latest"` | no |
| <a name="input_cluster_vpc_config"></a> [cluster\_vpc\_config](#input\_cluster\_vpc\_config) | VPC configuration for EKS | <pre>object({<br/>    private_subnet_ids      = list(string)<br/>    private_access_cidrs    = list(string)<br/>    public_access_cidrs     = list(string)<br/>    security_group_ids      = list(string)<br/>    endpoint_private_access = bool<br/>    endpoint_public_access  = bool<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_zonal_shift_config"></a> [cluster\_zonal\_shift\_config](#input\_cluster\_zonal\_shift\_config) | Zonal shift configuration | <pre>object({<br/>    enabled = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create an internal security group for EKS | `bool` | `true` | no |
| <a name="input_ebs_csi_controller_sa_name"></a> [ebs\_csi\_controller\_sa\_name](#input\_ebs\_csi\_controller\_sa\_name) | The name of the Kubernetes ServiceAccount used by the EBS CSI driver | `string` | `"ebs-csi-controller-sa"` | no |
| <a name="input_ebs_csi_driver_chart_version"></a> [ebs\_csi\_driver\_chart\_version](#input\_ebs\_csi\_driver\_chart\_version) | Helm chart version to use for AWS EBS CSI Driver. Use 'latest' or null to always get the latest chart version. | `string` | `"latest"` | no |
| <a name="input_eks_addons"></a> [eks\_addons](#input\_eks\_addons) | List of EKS add-ons to install with optional configurations | <pre>list(object({<br/>    name                        = string<br/>    version                     = optional(string, null)<br/>    configuration_values        = optional(string, null)<br/>    resolve_conflicts_on_create = optional(string, "NONE")<br/>    resolve_conflicts_on_update = optional(string, "NONE")<br/>    tags                        = optional(map(string), {})<br/>    preserve                    = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_eks_log_prevent_destroy"></a> [eks\_log\_prevent\_destroy](#input\_eks\_log\_prevent\_destroy) | Whether to prevent the destruction of the CloudWatch log group | `bool` | `true` | no |
| <a name="input_eks_log_retention_days"></a> [eks\_log\_retention\_days](#input\_eks\_log\_retention\_days) | The number of days to retain logs for the EKS in CloudWatch | `number` | `30` | no |
| <a name="input_eks_view_access"></a> [eks\_view\_access](#input\_eks\_view\_access) | Configuration for assigning view access to EKS cluster | <pre>object({<br/>    enabled    = bool<br/>    role_names = list(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "role_names": []<br/>}</pre> | no |
| <a name="input_enable_aws_load_balancer_controller"></a> [enable\_aws\_load\_balancer\_controller](#input\_enable\_aws\_load\_balancer\_controller) | Enable AWS Load Balancer Controller with IAM role and RBAC | `bool` | `false` | no |
| <a name="input_enable_cluster_encryption"></a> [enable\_cluster\_encryption](#input\_enable\_cluster\_encryption) | Enable encryption for Kubernetes secrets using a KMS key | `bool` | `false` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Whether to enable CloudWatch logging for EKS workloads (e.g., Fluent Bit, Fargate logs) | `bool` | `false` | no |
| <a name="input_enable_ebs_csi_controller"></a> [enable\_ebs\_csi\_controller](#input\_enable\_ebs\_csi\_controller) | Enable the AWS EBS CSI Controller. If true, deploys the Helm release and sets up required IAM roles and policies. | `bool` | `false` | no |
| <a name="input_enable_elastic_load_balancing"></a> [enable\_elastic\_load\_balancing](#input\_enable\_elastic\_load\_balancing) | Enable or disable Elastic Load Balancing for EKS Auto Mode | `bool` | `true` | no |
| <a name="input_enable_oidc"></a> [enable\_oidc](#input\_enable\_oidc) | Enable IAM Roles for Service Accounts (IRSA) support by creating the OIDC provider for the EKS cluster. | `bool` | `true` | no |
| <a name="input_enable_prometheus"></a> [enable\_prometheus](#input\_enable\_prometheus) | Enable Prometheus monitoring with StatefulSet, persistent storage, and LoadBalancer service | `bool` | `false` | no |
| <a name="input_fluentbit_namespace"></a> [fluentbit\_namespace](#input\_fluentbit\_namespace) | The Kubernetes namespace where Fluent Bit is deployed. Use 'aws-observability' for EKS Auto Mode or 'amazon-cloudwatch' for standard EKS. | `string` | `"aws-observability"` | no |
| <a name="input_fluentbit_sa_name"></a> [fluentbit\_sa\_name](#input\_fluentbit\_sa\_name) | The name of the Kubernetes service account used by Fluent Bit. This is used to associate the IAM role via IRSA. | `string` | `"fluent-bit"` | no |
| <a name="input_helm_charts"></a> [helm\_charts](#input\_helm\_charts) | List of Helm releases to deploy | <pre>list(object({<br/>    name                 = string<br/>    namespace            = string<br/>    repository           = string<br/>    chart                = string<br/>    chart_version        = optional(string)<br/>    values_files         = optional(list(string), [])<br/>    set_values           = optional(list(object({ name = string, value = string })), [])<br/>    set_sensitive_values = optional(list(object({ name = string, value = string })), [])<br/>    create_namespace     = optional(bool, true)<br/>    enabled              = optional(bool, true)<br/>    depends_on           = optional(list(any), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | List of Kubernetes namespaces to create | `list(string)` | `[]` | no |
| <a name="input_prometheus_chart_version"></a> [prometheus\_chart\_version](#input\_prometheus\_chart\_version) | Version of the Prometheus Helm chart | `string` | `"25.8.0"` | no |
| <a name="input_prometheus_namespace"></a> [prometheus\_namespace](#input\_prometheus\_namespace) | Kubernetes namespace for Prometheus | `string` | `"monitoring"` | no |
| <a name="input_prometheus_replicas"></a> [prometheus\_replicas](#input\_prometheus\_replicas) | The number of Prometheus replicas to deploy | `number` | `1` | no |
| <a name="input_prometheus_resources"></a> [prometheus\_resources](#input\_prometheus\_resources) | The resource requests and limits for Prometheus | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "1000m",<br/>    "memory": "2Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "512Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_prometheus_retention_time"></a> [prometheus\_retention\_time](#input\_prometheus\_retention\_time) | The number of days to retain metrics in Prometheus | `string` | `"15d"` | no |
| <a name="input_prometheus_service_annotations"></a> [prometheus\_service\_annotations](#input\_prometheus\_service\_annotations) | The annotations for the Prometheus service | `map(string)` | <pre>{<br/>  "service.beta.kubernetes.io/aws-load-balancer-scheme": "internal",<br/>  "service.beta.kubernetes.io/aws-load-balancer-type": "nlb"<br/>}</pre> | no |
| <a name="input_prometheus_service_type"></a> [prometheus\_service\_type](#input\_prometheus\_service\_type) | The type of Kubernetes service for Prometheus | `string` | `"LoadBalancer"` | no |
| <a name="input_prometheus_storage_class"></a> [prometheus\_storage\_class](#input\_prometheus\_storage\_class) | The storage class for the Prometheus persistent volume | `string` | `"gp2"` | no |
| <a name="input_prometheus_storage_size"></a> [prometheus\_storage\_size](#input\_prometheus\_storage\_size) | The size of the persistent volume for Prometheus data | `string` | `"10Gi"` | no |
| <a name="input_prometheus_version"></a> [prometheus\_version](#input\_prometheus\_version) | Prometheus version. Use 'latest' or null to always get the latest version. | `string` | `"latest"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to use on all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeouts for EKS cluster creation, update, and deletion | <pre>object({<br/>    create = optional(string, null)<br/>    update = optional(string, null)<br/>    delete = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the EKS cluster will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The Kubernetes version used by the EKS cluster, if exported by the module. |
| <a name="output_eks_cluster_auth_token"></a> [eks\_cluster\_auth\_token](#output\_eks\_cluster\_auth\_token) | Authentication token for the EKS cluster (used by kubectl and SDKs) |
| <a name="output_eks_cluster_ca_cert"></a> [eks\_cluster\_ca\_cert](#output\_eks\_cluster\_ca\_cert) | The base64-decoded certificate authority data for the EKS cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | The endpoint URL of the EKS cluster |
<!-- END_TF_DOCS -->
