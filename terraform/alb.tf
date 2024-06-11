resource "aws_lb" "nlb" {
  name               = "web-nlb3"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  tags = {
    Name = "web-nlb"
  }
}

resource "aws_lb_target_group" "ecs_service_tg" {
  name         = "ecs-service-tg"
  port         = 5000
  protocol     = "TCP"
  vpc_id       = aws_vpc.main.id
  target_type  = "ip"
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 5000
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_service_tg.arn
  }
}

resource "aws_lb_target_group" "ecs_strapi_tg" {
  name         = "ecs-strapi-tg"
  port         = 1337
  protocol     = "TCP"
  vpc_id       = aws_vpc.main.id
  target_type  = "ip"
}

resource "aws_lb_listener" "strapi_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 1337
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_strapi_tg.arn
  }
}