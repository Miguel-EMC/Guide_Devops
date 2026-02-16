# 9. Real-World Terraform Examples

This section serves as a practical culmination of all the Terraform concepts learned throughout this guide. We will explore several common real-world infrastructure deployment scenarios, demonstrating how to combine various Terraform resources, modules, and best practices to build robust and scalable cloud environments.

## 9.1. Introduction: Bridging Theory with Practical Deployments

These examples are designed to move beyond isolated resource declarations and illustrate how to construct complete, production-ready infrastructure using Terraform. Each example will highlight key learnings and best practices.

## 9.2. Example 1: Deploying a VPC/VNet with Subnets and Security Groups (AWS)

Setting up a robust and secure network foundation is the first step for almost any cloud deployment. This example focuses on creating a multi-tier network architecture in AWS.

### Scenario

A secure network for a web application, including:
*   A Virtual Private Cloud (VPC).
*   Public subnets for internet-facing resources (e.g., Load Balancers).
*   Private subnets for application servers and databases.
*   An Internet Gateway for outbound internet access.
*   NAT Gateway for private subnet outbound internet access.
*   Route Tables to direct traffic.
*   Security Groups to act as firewalls for instances.

### Key Learnings

*   **Networking Fundamentals:** How to structure a secure cloud network.
*   **Modularity:** Often, networking components are encapsulated in a reusable module.
*   **`count` Meta-Argument:** For creating multiple similar subnets.
*   **Resource Dependencies:** How Terraform manages the order of resource creation.

### Example Terraform Structure (Conceptual)

```
.
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

**`versions.tf`**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**`variables.tf`**

```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "environment_tag" {
  description = "Environment tag for resources"
  type        = string
  default     = "development"
}
```

**`main.tf` (Simplified for illustration)**

```hcl
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "my-app-vpc"
    Environment = var.environment_tag
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b"], count.index)}" # Dynamically pick AZ
  map_public_ip_on_launch = true
  tags = {
    Name        = "my-app-public-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b"], count.index)}"
  tags = {
    Name        = "my-app-private-subnet-${count.index}"
    Environment = var.environment_tag
  }
}

# ... (Internet Gateway, NAT Gateway, Route Tables, Security Groups would follow)
```

## 9.3. Example 2: Deploying a Scalable Web Application Stack (AWS EC2, ALB, RDS)

Building on the network foundation, this example provisions a highly available and scalable web application.

### Scenario

A typical 3-tier web application:
*   Application Load Balancer (ALB) for distributing traffic.
*   EC2 instances running the web application, managed by an Auto Scaling Group.
*   Amazon RDS for PostgreSQL as the managed database.

### Key Learnings

*   **High Availability:** Deploying resources across multiple Availability Zones.
*   **Autoscaling:** Dynamically adjusting compute capacity.
*   **Managed Services:** Leveraging AWS RDS for database management.
*   **Data Persistence:** Connecting application to a managed database.
*   **Security:** Configuring security groups for all layers.

### Example Terraform Structure (Conceptual)

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── modules/
│   ├── vpc/             # Reusable VPC module
│   ├── webserver/       # Reusable web server module (EC2, ASG)
│   └── rds/             # Reusable RDS module
└── environments/
    ├── dev/
    │   └── main.tf      # Calls modules for dev environment
    └── prod/
        └── main.tf      # Calls modules for prod environment
```

## 9.4. Example 3: Provisioning a Managed Kubernetes Cluster (GCP GKE)

Kubernetes is a critical component of modern infrastructure. This example demonstrates deploying a production-ready managed Kubernetes cluster.

### Scenario

A Google Kubernetes Engine (GKE) cluster, ready to host containerized applications.

### Components

*   GKE Cluster (`google_container_cluster`).
*   Node Pools (`google_container_node_pool`) with appropriate machine types and scaling configurations.
*   Networking (VPC, subnets, firewall rules to allow GKE traffic).
*   IAM roles for GKE service accounts.

### Key Learnings

*   **Managed Kubernetes:** Deploying and configuring a GKE cluster.
*   **Cloud-Specific Integrations:** How Terraform manages GCP-specific features.
*   **Security:** Configuring network and IAM for the cluster.
*   **Scaling:** Setting up node pool autoscaling.

## 9.5. Example 4: Deploying a Multi-Environment Infrastructure using Modules and Workspaces

This example showcases how to manage infrastructure for different environments (e.g., `dev`, `staging`, `prod`) efficiently using Terraform's modularity and workspace features.

### Scenario

A common set of infrastructure components (e.g., VPC, web servers, database) deployed with slight variations across `dev`, `staging`, and `prod` environments.

### Key Learnings

*   **Modularity:** Defining reusable modules for common infrastructure patterns.
*   **Workspaces vs. Separate Directories:** Understanding when to use Terraform workspaces for minor variations vs. separate directories for distinct environments.
*   **DRY Principle:** Avoiding repetition in infrastructure code.
*   **Environment-Specific Configuration:** Using `tfvars` files or conditional logic to customize deployments per environment.

### Example Terraform Structure (Conceptual)

```
.
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── app-server/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── main.tf          # Calls modules for dev
    │   └── terraform.tfvars # Dev-specific variables
    ├── staging/
    │   ├── main.tf          # Calls modules for staging
    │   └── terraform.tfvars # Staging-specific variables
    └── prod/
        ├── main.tf          # Calls modules for prod
        └── terraform.tfvars # Prod-specific variables
```

Each `main.tf` in the `environments` directories would call the modules defined in the `modules` directory.

## 9.6. Future Trends in Real-World Usage (up to 2026)

*   **GitOps for Infrastructure:** Terraform configurations will be increasingly managed through GitOps workflows, where changes to infrastructure are driven by Git commits and automatically reconciled.
*   **CDK for Terraform (CDKTF):** For complex infrastructure that benefits from programmatic logic, CDKTF will see greater adoption, allowing engineers to define infrastructure using familiar programming languages.
*   **Automated Governance:** Policy as Code (e.g., OPA, Sentinel) will become standard practice, ensuring that all deployed infrastructure adheres to organizational policies before deployment.
*   **AIOps Integration:** AI/ML will assist in optimizing infrastructure, predicting issues, and providing intelligent recommendations for Terraform configurations.

By working through these real-world examples, you will gain the practical experience necessary to design, implement, and manage complex cloud infrastructure with confidence using Terraform.
