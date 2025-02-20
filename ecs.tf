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

# AWS Launch template
resource "aws_launch_template" "ecs" {
  name_prefix  = "ecs-launch-template-"
  image_id     = var.image_id
  instance_type = var.instance_type
  key_name      = "New-Key-Pair"  # Replace with actual key pair name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["sg-0188c9fb8c5e55847"]
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
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnet_ids
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "EC2"

  depends_on = [
    aws_ecs_cluster.main,
    aws_ecs_task_definition.task
  ]
}

# AWS load balancer
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_ids

  enable_deletion_protection = true

  /*access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }*/

  tags = {
    Environment = "production"
  }
}

# AWS lb target group
resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# Output ECS Cluster ARN
output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
