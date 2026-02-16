# main.tf for GitLab CI example
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "gitlab-ci-example-vpc" }
}

output "vpc_id" {
  value = aws_vpc.example.id
}
