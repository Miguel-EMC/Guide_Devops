# 3. Terraform CLI and Workflow

The Terraform Command-Line Interface (CLI) is your primary interface for interacting with Terraform configurations and managing your infrastructure. This section will guide you through the essential CLI commands and the standard workflow, emphasizing best practices for safe, collaborative, and efficient infrastructure management.

## 3.1. Terraform CLI Overview

The `terraform` command is the entry point for all Terraform operations. It enables you to initialize working directories, generate execution plans, apply changes to your infrastructure, and destroy resources.

## 3.2. The Standard Terraform Workflow

The typical workflow for managing infrastructure with Terraform involves a few core commands executed in sequence.

### a. `terraform init`

*   **Purpose:** Initializes a working directory containing Terraform configuration files. This command must be run first in a new directory or after cloning a repository containing Terraform code.
*   **What it does:**
    *   **Downloads Providers:** Installs the necessary provider plugins (e.g., `hashicorp/aws`) defined in your configuration.
    *   **Backend Configuration:** Configures the backend where Terraform will store its state file (e.g., local, S3, Terraform Cloud).
    *   **Module Configuration:** Downloads any modules referenced in your configuration.
*   **Best Practice:** Run `terraform init -upgrade` to ensure providers and modules are updated to their latest compatible versions.

### b. `terraform validate`

*   **Purpose:** Verifies that your configuration is syntactically valid and internally consistent. It checks for common errors like undeclared variables or incorrect argument types.
*   **Benefits:** Catches errors early, before attempting to build an execution plan.
*   **Best Practice:** Run this command frequently, especially before `terraform plan` or integrating into CI/CD.

### c. `terraform plan`

*   **Purpose:** Generates an execution plan that shows exactly what actions Terraform will take to achieve the desired state defined in your configuration. It performs a "dry run" without making any actual changes to your infrastructure.
*   **Output:** The plan output shows:
    *   Resources to be added (`+`).
    *   Resources to be changed (`~`).
    *   Resources to be destroyed (`-`).
    *   Resources that will be tainted or replaced.
*   **Importance:** This is a crucial safety step. Always review the plan carefully.
*   **`terraform plan -out=tfplan`:** Saves the generated plan to a file. This is best practice for CI/CD pipelines to ensure the `apply` step executes the *exact* plan that was reviewed.

### d. `terraform apply`

*   **Purpose:** Executes the actions proposed in a `terraform plan`, making changes to your real-world infrastructure.
*   **Interactive Confirmation:** If `terraform apply` is run without a saved plan file, it will display the plan and prompt for confirmation before proceeding.
*   **`terraform apply "tfplan"`:** When you pass a saved plan file, Terraform executes that specific plan without further confirmation (unless `auto-approve` is not used in CI/CD).
*   **Outputs:** Displays any output values defined in your configuration.

### e. `terraform destroy`

*   **Purpose:** Tears down all resources managed by the current Terraform configuration. It generates a destruction plan and prompts for confirmation.
*   **Caution:** Use with extreme care! This command will permanently delete your infrastructure.
*   **`terraform destroy -auto-approve`:** Destroys resources without confirmation (use with caution in automated scripts).

## 3.3. Advanced CLI Commands and Best Practices

### a. `terraform fmt`

*   **Purpose:** Automatically rewrites configuration files to a canonical format, ensuring consistent styling across your team.
*   **Best Practice:** Integrate into pre-commit hooks or CI/CD pipelines to enforce style.

### b. `terraform graph`

*   **Purpose:** Generates a visual graph of your Terraform configuration's resource dependencies.
*   **Output:** Generates output in DOT format, which can be rendered with tools like Graphviz.
*   **Use Cases:** Understanding complex configurations, identifying bottlenecks.

### c. `terraform state` Commands

These commands allow you to inspect and modify the Terraform state file directly. Use them with extreme caution as incorrect modifications can lead to infrastructure drift or loss.

*   **`terraform state list`:** Lists all resources managed by the current state file.
*   **`terraform state show <address>`:** Shows the details of a specific resource in the state file.
*   **`terraform state rm <address>`:** Removes a resource from the state file. **Crucially, this does NOT destroy the actual resource in the cloud.** It tells Terraform to "forget" about it.
*   **`terraform import <ADDRESS> <ID>`:** Imports an existing resource into your Terraform state. Useful for adopting manually created resources into Terraform management.

### d. `terraform output`

*   **Purpose:** Retrieves the value of an output variable from the state file.
*   **Example:** `terraform output instance_ip`

### e. `terraform workspace` Commands (Brief Introduction)

*   **Purpose:** Allows you to manage multiple distinct state files (workspaces) for a single Terraform configuration. This is often used to manage different environments (e.g., `dev`, `staging`, `prod`) from the same set of configuration files.
*   **Commands:** `terraform workspace new <name>`, `terraform workspace select <name>`, `terraform workspace list`.

### f. `terraform taint / untaint`

*   **Purpose:** Marks a resource as "tainted," forcing Terraform to destroy and recreate it on the next `apply`. `untaint` removes the tainted state.
*   **Caution:** Use with caution. This is a destructive operation.

## 3.4. Backend Configuration

The **backend** defines where Terraform stores its state file.

*   **Local Backend:** The default, stores `terraform.tfstate` in your working directory. Suitable only for solo development.
*   **Remote Backends:** Store the state file in a shared, remote location.
    *   **Importance:** Essential for team collaboration and CI/CD pipelines to ensure all team members are working with the same, most up-to-date state.
    *   **Popular Options:** Amazon S3, Azure Blob Storage, Google Cloud Storage, HashiCorp Consul, Terraform Cloud.
*   **Example (S3 Backend):**
    ```hcl
    terraform {
      backend "s3" {
        bucket         = "my-terraform-state-bucket"
        key            = "path/to/my-app/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "my-terraform-state-lock" # For state locking
        encrypt        = true
      }
    }
    ```

## 3.5. Workflow for Team Collaboration

*   **Remote State:** Always configure a remote backend.
*   **State Locking:** Remote backends typically offer state locking mechanisms to prevent multiple users or CI/CD jobs from concurrently running `terraform apply` operations, which could corrupt the state file.
*   **CI/CD Integration:** Automate `terraform init`, `validate`, `plan`, and `apply` in your CI/CD pipelines (covered in detail in a later section).
*   **Code Reviews:** Treat Terraform configuration like application code. Review `terraform plan` outputs during pull requests to ensure changes are intended and safe.
*   **Modularity:** Use modules to abstract reusable infrastructure components.

By understanding and adhering to this workflow, you can leverage the full power of Terraform to manage your infrastructure collaboratively and safely.
