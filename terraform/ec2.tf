resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/generated-key.pem"
}

resource "aws_instance" "web" {
  ami                      = "ami-0f8bd0dd1106fad54"
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.public.id
  availability_zone        = "ap-south-1b"
  vpc_security_group_ids   = [aws_security_group.ssh.id]
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  key_name                 = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF

  tags = {
    Name = "web-server"
  }

  depends_on = [aws_security_group.ssh]
}
