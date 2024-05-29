provider "aws" {
  region = "us-east-1"
}

# Data source to get availability zones
data "aws_availability_zones" "available" {}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Create an internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# Create a route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

# Associate route table with subnets
resource "aws_route_table_association" "example" {
  count          = 2
  subnet_id      = aws_subnet.example[count.index].id
  route_table_id = aws_route_table.example.id
}

# Create a security group
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}

# Create a task definition
resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "example-container"
    image     = "nginx"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
  }])
}

# Create an ECS service
resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.example[*].id
    security_groups = [aws_security_group.example.id]
    assign_public_ip = true
  }
}
