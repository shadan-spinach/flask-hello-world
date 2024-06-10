resource "aws_ecr_repository" "flask_app_new" {
  name                 = "flask-app-new"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "flask_app_policy" {
  repository = aws_ecr_repository.flask_app_new.name

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
