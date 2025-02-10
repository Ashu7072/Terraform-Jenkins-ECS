# Providers
provider "aws" {
  region = var.region
}

# ECR Repository
resource "aws_ecr_repository" "my_app" {
  name                 = "my-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repo_url" {
  value = aws_ecr_repository.my_repo.repository_url
}