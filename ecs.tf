# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = "my-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([{
    name      = "web-app"
    image     = aws_ecr_repository.my_app.repository_url
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 9000
      }
    ]
  }])
}

resource "aws_launch_template" "ecs" {
  name_prefix  = "ecs-launch-template-"
  image_id     = var.image_id
  instance_type = var.instance_type
  key_name      = "New-Key-Pair"  # Replace with actual key pair name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_groups
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = var.subnet_ids
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2
  launch_type     = "EC2"

  depends_on = [
    aws_ecs_cluster.main,
    aws_ecs_task_definition.task
  ]
}

#Instance Target Group
resource "aws_lb_target_group" "alb-example" {
  name        = "tf-example-lb-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
}

#Application Load Balancer
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_ids

  enable_deletion_protection = false 

  tags = {
    Environment = "production"
  }
}

# Output ECS Cluster ARN
output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
