# 7. Terraform in CI/CD Pipelines

Integrating Terraform into your Continuous Integration (CI) and Continuous Delivery (CD) pipelines is a crucial step towards fully automating your infrastructure provisioning and management. This approach ensures consistency, reduces manual errors, and accelerates the delivery of infrastructure changes. This section covers the best practices and common patterns for using Terraform effectively within CI/CD.

## 7.1. Introduction: Why Integrate Terraform with CI/CD?

Just as application code benefits from CI/CD, so does infrastructure code. Automating Terraform operations in a pipeline provides:

*   **Automation:** Eliminates manual execution of Terraform commands, reducing human error.
*   **Consistency:** Ensures that infrastructure changes are applied uniformly across environments.
*   **Speed:** Accelerates the provisioning and modification of infrastructure.
*   **Auditability:** Every infrastructure change is triggered by a version-controlled commit, providing a clear audit trail.
*   **Safety:** The `terraform plan` output can be reviewed by a team member before applying changes, acting as an essential safety gate.
*   **Collaboration:** Facilitates team collaboration on infrastructure code.

## 7.2. Basic CI/CD Workflow for Terraform

A typical Terraform CI/CD pipeline often involves these stages:

### a. Trigger

*   The pipeline is triggered by events such as:
    *   Push to a Git repository (`main` branch for deployments, feature branches for validation).
    *   Pull Request (PR) or Merge Request (MR) creation or updates.

### b. Initialization & Validation (`terraform init`, `validate`, `fmt`)

*   **`terraform init`:** Initializes the Terraform working directory, downloads provider plugins, and configures the backend.
*   **`terraform validate`:** Checks the HCL configuration for syntax errors and internal consistency.
*   **`terraform fmt -check -diff`:** (Optional but recommended) Ensures code formatting compliance without modifying files. Fails the pipeline if formatting issues are found.

### c. Planning (`terraform plan`)

*   **`terraform plan -out=tfplan`:** Generates an execution plan and saves it to a file (`tfplan`). This plan shows what changes Terraform *proposes* to make to the infrastructure.
*   **Reviewing the Plan:** The generated plan should be reviewed by a human (e.g., as a comment on a PR) to ensure the changes are expected and safe.

### d. Approval Gate (for Continuous Delivery)

*   For production environments, an explicit approval gate is often implemented after the `plan` stage. This can be:
    *   **Manual Approval:** A human approving the plan (e.g., clicking a button in the CI/CD UI).
    *   **Automated Policy Check:** Using Policy as Code tools to automatically approve/deny based on predefined rules (e.g., ensuring cost limits are not exceeded).

### e. Application (`terraform apply`)

*   **`terraform apply "tfplan"`:** Applies the previously saved execution plan to make the actual changes to the infrastructure.
*   **`terraform apply -auto-approve "tfplan"`:** Used for fully automated Continuous Deployment scenarios, skipping the interactive confirmation. Use with extreme caution and only after rigorous testing and approval.

## 7.3. Security in CI/CD Pipelines for Terraform

Securing your infrastructure pipelines is paramount.

### a. Credentials Management

*   **Principle of Least Privilege:** CI/CD runners should only have the minimum necessary permissions (IAM roles, Service Principals) to provision the resources defined in the Terraform configuration.
*   **Short-Lived Credentials:** Use temporary credentials or OIDC-based authentication for cloud providers where possible.
*   **CI/CD Platform Secrets:** Store cloud provider credentials and other sensitive data (e.g., API keys for remote state) as encrypted secrets in your CI/CD platform (GitHub Secrets, GitLab CI/CD Variables, Azure Key Vault integration). **Never hardcode credentials.**

### b. State Access

*   The CI/CD pipeline will need read/write access to the remote state backend. Ensure this access is tightly controlled via IAM policies.

### c. Policy as Code (Brief Mention)

*   Integrate tools like HashiCorp Sentinel or Open Policy Agent (OPA) into your pipeline to enforce compliance, security, and cost policies on your Terraform plans *before* they are applied. This acts as an automated safety net.

## 7.4. Integrating with Popular CI/CD Tools

### a. GitHub Actions

GitHub Actions is a popular choice due to its deep integration with GitHub repositories.

```yaml
# .github/workflows/terraform.yml
name: 'Terraform CI/CD'

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: 'us-east-1'

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.x.x' # Use a specific version or range

      - name: Terraform Init
        id: init
        run: terraform init

      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color

      - name: Terraform Plan
        id: plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color -input=false
        continue-on-error: true # Allow plan to fail if there are errors

      - name: Terraform Apply
        id: apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve -input=false
```

### b. GitLab CI

GitLab CI has native support for Terraform with a rich set of features.

```yaml
# .gitlab-ci.yml
image:
  name: hashicorp/terraform:latest
  entrypoint:
    - /usr/bin/env
    - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    - sh

variables:
  TF_ROOT: ${CI_PROJECT_DIR} # Assumes Terraform files are at project root
  TF_STATE_NAME: default
  TF_CACHE_KEY: default

cache:
  key: ${TF_CACHE_KEY}
  paths:
    - ${TF_ROOT}/.terraform

before_script:
  - cd ${TF_ROOT}
  - terraform --version
  - terraform init -backend-config="s3_bucket=${S3_BUCKET}" -backend-config="s3_region=${AWS_REGION}" # Example for S3 backend

stages:
  - validate
  - plan
  - apply

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: plan
  script:
    - terraform plan -out=plan.tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/plan.tfplan

apply:
  stage: apply
  script:
    - terraform apply -auto-approve plan.tfplan
  dependencies:
    - plan
  when: manual # Requires manual approval to run
```

## 7.5. Advanced CI/CD Patterns

*   **Drift Detection:** Periodically run `terraform plan` in a separate pipeline or schedule to detect unintended changes (drift) in your infrastructure that are not reflected in your Terraform code.
*   **Destroy Operations in CI/CD:** While `terraform destroy` can be automated, it should be done with extreme caution, often requiring multiple manual approvals or specific branch/tag triggers.
*   **Monorepo Strategy:** Use path-based triggers (e.g., `paths:` in GitHub Actions, `only:changes` in GitLab CI) to run Terraform pipelines only when changes occur in relevant infrastructure code directories.

## 7.6. Terraform Cloud / Enterprise in CI/CD

These managed solutions offer a specialized CI/CD experience for Terraform:

*   **Remote Runs:** Terraform operations (plan, apply) are executed securely on HashiCorp's infrastructure.
*   **VCS-driven Workflows:** Automatically trigger runs based on Git commits/PRs.
*   **Policy Enforcement (Sentinel):** Policy as Code is built-in, preventing non-compliant infrastructure.
*   **Cost Estimation:** Provides cost estimates for proposed infrastructure changes.
*   **Private Module Registry:** Centralized private modules for your organization.

## 7.7. Future Trends (up to 2026)

*   **Increased GitOps for Infrastructure:** The GitOps paradigm, where Git is the single source of truth for desired infrastructure state, will become even more prevalent, with Terraform being a key component.
*   **More Intelligent CI/CD Platforms for IaC:** CI/CD tools will integrate more deeply with Terraform, offering richer plan review experiences, automated validation, and predictive insights.
*   **AI/ML Assistance:** AI/ML will play a growing role in assisting in the validation, optimization, and even generation of Terraform configurations and plans within CI/CD.

By embracing these CI/CD integration strategies, you can transform your infrastructure management into a fully automated, auditable, and reliable process.
