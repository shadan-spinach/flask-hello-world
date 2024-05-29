
provider "aws" {
  region     = "ap-south-1"

}

terraform {
  backend "s3" {
    bucket         = "spinach-s3"   # Replace with your S3 bucket name
    key            = "terraform/terraform.tfstate" # Replace with the path to your state file
    region         = "ap-south-1"            # Change to the region where your S3 bucket is located
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat-gateway"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Associate Private Subnet with Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for SSH access
resource "aws_security_group" "ssh" {
  vpc_id = aws_vpc.main.id

   # Allow traffic on port 5000 only from the NLB
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-sg"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ssm-role"

  assume_role_policy =jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid = ""
      Principal= {
        Service = "ec2.amazonaws.com"
      }
    },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ssm-role-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 Instance in Private Subnet
resource "aws_instance" "web" {
  ami             = "ami-0c76ded57b818ac02" # Ubuntu 20
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private.id
  availability_zone = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.ssh.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  # Add user_data to install Docker
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get install -y docker-ce
              sudo systemctl start docker
              sudo systemctl enable docker

              # Add the default user to the docker group
              sudo usermod -aG docker ubuntu
              
              # Install AWS CLI
              sudo apt-get install -y awscli
              EOF

  tags = {
    Name = "web-server"
  }

  # Ensure the instance creation waits for the security group to be created
  depends_on = [aws_security_group.ssh]
}

# Network Load Balancer (NLB)
resource "aws_lb" "nlb" {
  name               = "web-nlb3"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private.id]

  tags = {
    Name = "web-nlb"
  }
}

# Create a target group
resource "aws_lb_target_group" "tg3" {
  name     = "web-tg3"
  port     = 5000
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

# Add the EC2 instance to the target group
resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.tg3.arn
  target_id        = aws_instance.web.id
  port             = 5000
}

# Create a listener for the NLB
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 5000
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg3.arn
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "flask_api" {
  name        = "Flask API"
  description = "API Gateway for Flask app"
}

resource "aws_api_gateway_resource" "flask_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  parent_id   = aws_api_gateway_rest_api.flask_api.root_resource_id
  path_part   = "flask"
}

# VPC Link
resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = "vpc-link"
  target_arns = [aws_lb.nlb.arn]
}

resource "aws_api_gateway_method" "flask_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.flask_api.id
  resource_id   = aws_api_gateway_resource.flask_api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "flask_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.flask_api.id
  resource_id             = aws_api_gateway_resource.flask_api_resource.id
  http_method             = aws_api_gateway_method.flask_api_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${aws_lb.nlb.dns_name}:5000/flask"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
}

resource "aws_api_gateway_deployment" "flask_api_deploy" {
  depends_on = [aws_api_gateway_integration.flask_api_integration]
  rest_api_id = aws_api_gateway_rest_api.flask_api.id
  stage_name  = "prod"
}

output "private_instance_ip" {
  value = aws_instance.web.private_ip
}

output "api_gateway_endpoint" {
  value = aws_api_gateway_deployment.flask_api_deploy.invoke_url
}

output "instance_id" {
  value = aws_instance.web.id
}
