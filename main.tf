provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  container_definitions    = jsonencode([{
    name      = "example"
    image     = "amazon/amazon-ecs-sample"
    essential = true
    memory    = 128
    cpu       = 128
  }])
}

resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.example.id]
    security_groups = ["sg-0188ea9c19e25dad7"] // Replace with your default security group ID
  }
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.example.id
}

output "ecs_service_name" {
  value = aws_ecs_service.example.name
}
