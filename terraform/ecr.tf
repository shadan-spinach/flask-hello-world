
resource "aws_ecr_repository" "strapi_app" {
  name                 = "strapi-app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "strapi_app_policy" {
  repository = aws_ecr_repository.strapi_app.name

  policy = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Retain only the single newest image",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
POLICY
}