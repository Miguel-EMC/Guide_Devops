# 5. Terraform for Cloud Providers (AWS, Azure, GCP)

One of Terraform's most compelling features is its ability to manage infrastructure across multiple cloud providers with a consistent workflow. This section delves into using Terraform with the three major cloud providers: Amazon Web Services (AWS), Microsoft Azure, and Google Cloud Platform (GCP), highlighting their respective provider configurations and common resource types.

## 5.1. Introduction: Multi-Cloud IaC with Terraform

Terraform's provider model allows it to act as a universal IaC tool. You define your desired infrastructure using HCL, and the relevant provider translates those definitions into API calls for the specific cloud. This enables:

*   **Unified Workflow:** Use the same `terraform init`, `plan`, `apply` workflow regardless of the cloud.
*   **Multi-Cloud Agility:** Deploy components across different clouds to leverage best-of-breed services or avoid vendor lock-in.
*   **Consistent Management:** Apply consistent IaC practices across your entire infrastructure portfolio.

## 5.2. Terraform with AWS

The `aws` provider is one of the most mature and feature-rich providers available for Terraform.

### a. Provider Configuration & Authentication

*   **`provider "aws"` block:** Specify the region and any other provider-specific settings.
*   **Authentication Methods:**
    *   **Environment Variables:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.
    *   **Shared Credentials File:** `~/.aws/credentials` (used by `profile` argument).
    *   **IAM Roles for EC2 Instances:** Automatically assigned credentials.
    *   **IAM Roles for OIDC Providers (e.g., for GitHub Actions):** Best practice for CI/CD.

### b. Common Resource Types

*   **Networking:**
    *   `aws_vpc`: Virtual Private Cloud (network isolation).
    *   `aws_subnet`: Subnets within a VPC.
    *   `aws_internet_gateway`: Connects VPC to the internet.
    *   `aws_route_table`: Defines network routes.
    *   `aws_security_group`: Firewall rules for instances.
*   **Compute:**
    *   `aws_instance`: EC2 virtual machines.
    *   `aws_autoscaling_group`: Manages groups of EC2 instances for scaling.
    *   `aws_launch_template`: Configuration for EC2 instances in Auto Scaling Groups.
*   **Storage:**
    *   `aws_s3_bucket`: Object storage.
    *   `aws_ebs_volume`: Block storage for EC2.
    *   `aws_rds_instance`: Managed relational databases (PostgreSQL, MySQL, etc.).
*   **Serverless:**
    *   `aws_lambda_function`: Serverless compute.
    *   `aws_apigatewayv2_api`: API Gateway for HTTP/REST APIs.
*   **Kubernetes:**
    *   `aws_eks_cluster`: Managed Kubernetes service (EKS).

### c. Example: Deploying a Simple EC2 Instance

```hcl
# main.tf for AWS EC2
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "terraform-example-vpc" }
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "terraform-example-subnet" }
}

resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.example.id
  name        = "web-access"
  description = "Allow web traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example.id
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = "HelloWorldWebServer"
  }
}

output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}
```

## 5.3. Terraform with Azure

The `azurerm` provider allows you to manage resources across Microsoft Azure.

### a. Provider Configuration & Authentication

*   **`provider "azurerm"` block:** Configure features and the Azure environment.
*   **Authentication Methods:**
    *   **Service Principal:** Recommended for automation (client ID, client secret, tenant ID).
    *   **Azure CLI:** Authenticates using your active Azure CLI session.
    *   **Managed Identities:** For Azure resources to authenticate without credentials.

### b. Common Resource Types

*   **Networking:**
    *   `azurerm_resource_group`: Logical container for Azure resources.
    *   `azurerm_virtual_network`: Virtual Networks (VNet).
    *   `azurerm_subnet`: Subnets within a VNet.
    *   `azurerm_network_security_group`: Firewall rules.
    *   `azurerm_public_ip`: Public IP addresses.
*   **Compute:**
    *   `azurerm_linux_virtual_machine` / `azurerm_windows_virtual_machine`: Virtual machines.
    *   `azurerm_virtual_machine_scale_set`: Manages groups of VMs.
*   **Storage:**
    *   `azurerm_storage_account`: Azure Storage accounts.
    *   `azurerm_sql_database`: Azure SQL Databases.
*   **Serverless:**
    *   `azurerm_function_app`: Azure Functions.
*   **Kubernetes:**
    *   `azurerm_kubernetes_cluster`: Managed Kubernetes service (AKS).

### c. Example: Deploying a Simple Azure VM

```hcl
# main.tf for Azure VM
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                  = "example-vm"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.example.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub") # Ensure this file exists
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "vm_private_ip" {
  value = azurerm_network_interface.example.private_ip_address
}
```

## 5.4. Terraform with Google Cloud Platform (GCP)

The `google` provider allows you to manage resources across Google Cloud.

### a. Provider Configuration & Authentication

*   **`provider "google"` block:** Configure project ID and region.
*   **Authentication Methods:**
    *   **Service Account Key File:** JSON key file for a service account.
    *   **`gcloud` CLI:** Authenticates using your active `gcloud` session.
    *   **Workload Identity Federation:** For securely accessing GCP from other clouds or on-premises.

### b. Common Resource Types

*   **Networking:**
    *   `google_compute_network`: VPC Networks.
    *   `google_compute_subnetwork`: Subnets within a VPC.
    *   `google_compute_firewall`: Firewall rules.
    *   `google_compute_address`: External IP addresses.
*   **Compute:**
    *   `google_compute_instance`: Compute Engine instances.
    *   `google_compute_instance_group_manager`: Manages instance groups.
*   **Storage:**
    *   `google_storage_bucket`: Cloud Storage buckets.
    *   `google_sql_database_instance`: Cloud SQL instances.
*   **Serverless:**
    *   `google_cloud_function`: Cloud Functions.
*   **Kubernetes:**
    *   `google_container_cluster`: Managed Kubernetes service (GKE).

### c. Example: Deploying a Simple GCP Compute Engine Instance

```hcl
# main.tf for GCP Compute Engine
provider "google" {
  project = "your-gcp-project-id" # Replace with your GCP project ID
  region  = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-example-network"
}

resource "google_compute_subnetwork" "default" {
  name          = "terraform-example-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.name
  region        = "us-central1"
}

resource "google_compute_instance" "default" {
  name         = "terraform-example-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    access_config {
      # Assign a public IP address
    }
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y nginx && sudo systemctl start nginx"

  tags = ["http-server"]
}

resource "google_compute_firewall" "default" {
  name    = "terraform-example-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

output "instance_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
```

## 5.5. Multi-Cloud Architecture Patterns

Terraform excels at managing infrastructure across multiple clouds, enabling patterns such as:

*   **Disaster Recovery:** Deploying a standby environment in a different cloud provider.
*   **Hybrid Cloud:** Integrating on-premises infrastructure with public cloud resources.
*   **Best-of-Breed Services:** Using a specialized service from one cloud provider alongside services from another.
*   **Consistent Environment Provisioning:** Ensuring development, staging, and production environments are consistently provisioned regardless of the underlying cloud.

## 5.6. Future Trends (up to 2026)

*   **Enhanced Cross-Cloud Abstractions:** Tools and methodologies will emerge to provide even higher-level, cloud-agnostic abstractions over basic cloud resources, simplifying multi-cloud deployments.
*   **Greater Integration with Cloud-Native Services:** Terraform providers will continue to rapidly integrate new cloud-native services, allowing you to manage the latest offerings programmatically.
*   **Increased Automation of Provider Updates:** Tools and practices for automatically managing and updating Terraform provider versions securely.
*   **Managed IaC Solutions:** Cloud providers may offer more tightly integrated and managed solutions for orchestrating Terraform deployments directly from their platforms.

By leveraging Terraform's multi-cloud capabilities, you can build resilient, flexible, and portable infrastructure architectures tailored to your specific needs.
