# Terraform EKS Apps Module

This Terraform module deploys a list of **Kubernetes applications** on an **EKS Fargate cluster**, including optional **namespace creation**, **logging configuration**, and **health checks**.

## Features

- ✅ Deploys multiple applications via `kubernetes_deployment`
- ✅ Creates dedicated namespaces per app (if needed)
- ✅ Supports Fluent Bit logging annotations
- ✅ Supports liveness and readiness probes

---

## Usage Example

```hcl
module "apps" {
  source = "../.."

  cluster_name     = "example-cluster"
  cluster_endpoint = module.cluster.cluster_endpoint
  cluster_ca       = module.cluster.cluster_certificate_authority_data

  apps = [
    {
      name           = "webapp"
      image          = "nginx:1.21"
      port           = 80
      enable_logging = true
      labels = {
        tier = "frontend"
      }
    },
    {
      name             = "api"
      image            = "my-api:latest"
      port             = 8080
      namespace        = "custom-api"
      create_namespace = true
      enable_logging   = false
    }
  ]
}

output "app_namespaces" {
  value = module.apps.app_namespaces
}
```

---

## Inputs

| Name             | Type     | Default | Description                                                   |
|------------------|----------|---------|---------------------------------------------------------------|
| `apps`           | `list(object)` | `[]`    | List of application definitions to deploy                     |
| `cluster_name`   | `string` | —       | EKS cluster name (informational)                              |
| `cluster_endpoint` | `string` | —     | The EKS cluster endpoint                                      |
| `cluster_ca`     | `string` | —       | Base64 encoded cluster CA certificate                         |

Each object in `apps` supports:

| Field             | Type             | Default     | Description                                         |
|------------------|------------------|-------------|-----------------------------------------------------|
| `name`           | `string`         | —           | Name of the Kubernetes deployment                  |
| `image`          | `string`         | —           | Container image                                     |
| `port`           | `number`         | —           | Container port                                      |
| `namespace`      | `string`         | `"default"` | Namespace to deploy the app into                   |
| `labels`         | `map(string)`    | `{}`        | Optional labels for pods and deployments           |
| `create_namespace` | `bool`         | `true`      | Whether to create the namespace if it doesn't exist|
| `enable_logging` | `bool`           | `false`     | Whether to enable Fluent Bit logging annotations   |

---

## Outputs

| Name              | Description                                              |
|-------------------|----------------------------------------------------------|
| `deployed_apps`   | List of app names that were deployed                     |
| `app_namespaces`  | Map of app names to their deployed namespaces            |

---

## Deployment

### Initialize Terraform

```sh
terraform init
```

### Apply Configuration

```sh
terraform apply -auto-approve
```

### View Outputs

```sh
terraform output
```

### Destroy Resources

```sh
terraform destroy -auto-approve
```

---

## Notes

- Namespaces are only created if `create_namespace = true` and not a core namespace.
- Fluent Bit logging annotations are only added if `enable_logging = true`.
- Health checks are optional and must be specified in the `apps` definition.

---

## License

This module is released under the **MIT License**.
