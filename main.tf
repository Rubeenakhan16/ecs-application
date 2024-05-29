provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "example-container"
    image     = "amazon/amazon-ecs-sample"
    essential = true
    portMappings = [
      {
        containerPort = 80
        protocol      = "tcp"
      }
    ]
  }])
}

resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [aws_default_subnet.default.id]
    assign_public_ip = true
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_default_subnet" "default" {
  default = true
  depends_on = [aws_ecs_cluster.example]
}

data "aws_vpc" "default" {
  default = true
}

