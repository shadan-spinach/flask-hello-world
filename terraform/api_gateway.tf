resource "aws_api_gateway_rest_api" "flask_api" {
  name        = "Flask API"
  description = "API Gateway for Flask app"
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  parent_id   = aws_api_gateway_rest_api.flask_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = "vpc-link"
  target_arns = [aws_lb.nlb.arn]
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.flask_api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flask_api.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.nlb.dns_name}:5000/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
  cache_key_parameters = ["method.request.path.proxy"]
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "flask_api_deploy" {
  depends_on  = [aws_api_gateway_integration.proxy_integration]
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  stage_name  = "v1"
}
