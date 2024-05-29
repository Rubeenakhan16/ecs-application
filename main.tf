provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "example" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = data.aws_vpc.default.cidr_block
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow inbound traffic"
  
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  container_definitions    = jsonencode([{
    name      = "example"
    image     = "amazon/amazon-ecs-sample"
    essential = true
    memory    = 512
    cpu       = 256
  }])
}

resource "aws_iam_role" "task_execution_role" {
  name               = "example-task-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.example.id]
    security_groups = [aws_security_group.example.id]
    assign_public_ip = true
  }
}
