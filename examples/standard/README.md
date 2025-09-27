# Standard EKS Auto Mode Example

This example demonstrates a standard Amazon EKS Auto Mode deployment with monitoring, security, and workload management capabilities.

## 🚀 What This Example Deploys

### **Core Infrastructure**

- **VPC** with public/private subnets across 3 AZs
- **EKS Auto Mode cluster** with managed node groups
- **Internet Gateway** and **NAT Gateway** for connectivity
- **Security groups** with least-privilege access

### **EKS Add-ons & Monitoring**

- **Metrics Server** - Resource metrics collection
- **Amazon CloudWatch Observability** - Container insights and monitoring
- **AWS EFS CSI Driver** - Shared file system support
- **Cert Manager** - TLS certificate management
- **Fluent Bit** - Log collection and forwarding
- **EBS CSI Controller** - Block storage support (enabled but not in add-ons list)

### **Sample Workloads**

- **Hello World (Internet-facing)** - Public ALB with SSL termination
- **Hello World Internal** - Internal ALB for private access

## 🏗️ Architecture

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Public    │  │   Public    │  │   Public    │         │
│  │  Subnet 1   │  │  Subnet 2   │  │  Subnet 3   │         │
│  │ 10.0.1.0/24 │  │ 10.0.2.0/24 │  │ 10.0.3.0/24 │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Private    │  │  Private    │  │  Private    │         │
│  │  Subnet 1   │  │  Subnet 2   │  │  Subnet 3   │         │
│  │10.0.101.0/24│  │10.0.102.0/24│  │10.0.103.0/24│         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   EKS Auto Mode   │
                    │     Cluster       │
                    │  ┌─────────────┐  │
                    │  │  Managed    │  │
                    │  │  Add-ons    │  │
                    │  └─────────────┘  │
                    │  ┌─────────────┐  │
                    │  │  Workloads  │  │
                    │  │  (Pods)     │  │
                    │  └─────────────┘  │
                    └───────────────────┘
```

## 📋 Prerequisites

- **Terraform** >= 1.3
- **AWS CLI** configured with appropriate permissions
- **kubectl** for cluster interaction
- **AWS Account** with EKS Auto Mode support

## 🚀 Quick Start

1. **Clone and navigate to the example:**

   ```bash
   cd examples/standard
   ```

2. **Initialize Terraform:**

   ```bash
   terraform init
   ```

3. **Review the configuration:**

   ```bash
   terraform plan
   ```

4. **Deploy the infrastructure:**

   ```bash
   terraform apply
   ```

5. **Configure kubectl:**

   ```bash
   aws eks update-kubeconfig --region ap-southeast-2 --name cltest
   ```

6. **Verify the deployment:**

   ```bash
   kubectl get nodes
   kubectl get pods -A
   kubectl get services
   kubectl get ingress
   ```

## 🔧 Key Configuration

### **Example-Specific Settings**

- **Cluster Name**: `cltest` (with random suffix)
- **Region**: `ap-southeast-2` (Sydney)
- **Kubernetes Version**: `1.33`
- **Node Pools**: `general-purpose` and `system`
- **VPC CIDR**: `10.0.0.0/16`
- **Public Access**: Restricted to your public IP only
- **Log Retention**: 1 day (for cost optimization)

### **EKS Auto Mode Settings**

```hcl
module "eks_auto" {
  source = "../.."

  cluster_name = "cltest"
  cluster_version = "1.33"

  # Enable all essential features
  enable_elastic_load_balancing       = true
  enable_oidc                         = true
  enable_ebs_csi_controller           = true
  enable_container_insights           = true
  enable_aws_load_balancer_controller = true

  eks_addons = [
    { name = "metrics-server", version = "latest" },
    { name = "amazon-cloudwatch-observability", version = "latest" },
    { name = "cert-manager", version = "latest" },
    { name = "fluent-bit", version = "latest" },
    { name = "aws-efs-csi-driver", version = "latest" }
  ]

  # Required namespaces
  namespaces = [
    "aws-observability"  # Required for Container Insights
  ]
}
```

### **Sample Workload Configuration**

```hcl
# Internet-facing workload
module "hello_world" {
  source = "../../modules/workload"

  name             = "hello-world"
  create_namespace = true
  namespace        = "hello-world"
  replicas         = 2
  create_service   = true
  create_ingress   = true
  ingress_scheme   = "internet-facing"

  containers = [{
    name  = "hello-world"
    image = "nginx:1.25"
  }]

  service_ports = [{
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "TCP"
  }]

  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/"
      path_type    = "Prefix"
      backend_port = 80
    }]
  }]

  ingress_annotations = {
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/load-balancer-name" = "${local.base_name}-hello-world"
  }

  cluster_name = local.name
  tags         = local.tags

  depends_on = [
    module.eks_auto,
    module.vpc
  ]
}

# Internal workload
module "hello_world_internal" {
  source = "../../modules/workload"

  name             = "hello-world-internal"
  create_namespace = true
  namespace        = "hello-world-internal"
  replicas         = 1
  create_service   = true
  create_ingress   = true
  ingress_scheme   = "internal"

  containers = [{
    name  = "hello-world"
    image = "nginx:1.25"
  }]

  service_ports = [{
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "TCP"
  }]

  ingress_rules = [{
    host = ""
    http_paths = [{
      path         = "/"
      path_type    = "Prefix"
      backend_port = 80
    }]
  }]

  ingress_annotations = {
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/load-balancer-name" = "${local.base_name}-hello-world-internal"
    "alb.ingress.kubernetes.io/scheme"             = "internal"
  }

  cluster_name = local.name
  tags         = local.tags

  depends_on = [
    module.eks_auto,
    module.vpc
  ]
}
```

## ⚙️ Advanced Features

### **EKS Auto Mode Specific Features**

- **Managed Node Groups**: Automatically managed by AWS
- **Integrated EBS CSI Driver**: Built-in storage support
- **Managed Add-ons**: vpc-cni, kube-proxy, coredns, eks-pod-identity-agent (managed by AWS, not installed as add-ons)

### **Logging Configuration**

- **API Server Logs**: Enabled for audit and debugging
- **Controller Manager Logs**: For cluster management insights
- **Scheduler Logs**: For pod scheduling analysis
- **Authenticator Logs**: For authentication debugging
- **Audit Logs**: For security compliance

## 📊 Monitoring & Observability

### **CloudWatch Integration**

- **Container Insights** enabled for pod and node metrics
- **Fluent Bit** for log collection and forwarding
- **Custom metrics** from applications

### **Accessing Metrics**

```bash
# View cluster metrics
kubectl top nodes
kubectl top pods -A

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/cltest
```

## 🔒 Security Features

### **IAM Roles for Service Accounts (IRSA)**

- **EBS CSI Controller** with dedicated IAM role
- **Container Insights** with CloudWatch permissions
- **Load Balancer Controller** with ALB permissions

### **Network Security**

- **Private subnets** for worker nodes
- **Security groups** with least-privilege access
- **VPC endpoints** for AWS services (optional)

### **Encryption**

- **TLS termination** at ALB

## 🌐 Accessing Your Applications

### **Internet-facing Application**

```bash
# Get the ALB URL
terraform output hello_world_alb_url

# Get the ALB DNS name
terraform output hello_world_alb_dns

# Access the application
curl $(terraform output -raw hello_world_alb_url)
```

### **Internal Application**

```bash
# Get the internal ALB URL
terraform output hello_world_internal_alb_url

# Get the internal ALB DNS name
terraform output hello_world_internal_alb_dns

# Access from within the cluster
kubectl run test-pod --image=busybox --rm -it -- wget -qO- http://hello-world-internal.hello-world-internal.svc.cluster.local
```

### **Cluster Information**

```bash
# Get cluster endpoint
terraform output eks_cluster_endpoint

# Get cluster version
terraform output eks_cluster_version
```

## 📈 Scaling & Management

### **Updates & Maintenance**

```bash
# Update cluster version
terraform plan -var="cluster_version=1.33"
terraform apply
```

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Verify cleanup
aws eks list-clusters --region ap-southeast-2
```
