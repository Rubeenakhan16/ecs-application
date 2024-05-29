provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
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
  # Specify the launch type as FARGATE
  network_mode             = "awsvpc"  # Required when using FARGATE
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.example.id]
    # Use the default security group associated with the VPC
    security_groups = [aws_vpc.example.default_security_group_id]
  }
}
