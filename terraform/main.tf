module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "task-vpc"
  cidr = var.vpc_cidr

  azs             = ["eu-central-1a", "eu-central-1b"] # TODO: variable
  public_subnets  = [var.public_subnet1_cidr, var.public_subnet2_cidr]
  private_subnets = [var.private_subnet1_cidr, var.private_subnet2_cidr]

  tags = {
    "Name" = "task-vpc"
  }
}

resource "aws_security_group" "task_rds_sg" {
  name        = "task-rds-sg"
  description = "Allow inbound traffic for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet1_cidr, var.public_subnet2_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task-rds-sg"
  }
}

resource "aws_db_subnet_group" "task_db_subnet_group" {
  name       = "task-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "task-db-subnet-group"
  }
}

resource "aws_db_instance" "task_rds" {
  identifier           = "task-rds"
  engine               = "postgres"
  engine_version       = "14.7"
  instance_class       = "db.t3.micro"
  db_name              = var.initial_db_name
  username             = var.rds_username
  password             = var.rds_password
  allocated_storage    = 20
  vpc_security_group_ids = [aws_security_group.task_rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.task_db_subnet_group.name
  publicly_accessible = false
  skip_final_snapshot = true
  depends_on = [aws_security_group.task_rds_sg]
}


resource "aws_ssm_parameter" "database_url" {
  name  = "DATABASE_URL"
  type  = "SecureString"
  value = "postgresql://${aws_db_instance.task_rds.username}:${var.rds_password}@${aws_db_instance.task_rds.endpoint}/${aws_db_instance.task_rds.db_name}"
}

resource "aws_iam_policy" "task_policy" {
  name        = "task-policy"
  description = "Policy for ECS task to get DB connection string from SSM"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "ssm:GetParameters",
        Resource = aws_ssm_parameter.database_url.arn
      }
    ]
  })
}

resource "aws_iam_role" "task_ecsTaskExecutionRole" {
  name = "task-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.task_ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.task_ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "task_alb_sg" {
  name        = "task-alb-sg"
  description = "Allow inbound traffic for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow all HTTP traffic"
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

  tags = {
    Name = "task-alb-sg"
  }
}

resource "aws_lb" "task_app_alb" {
  name               = "task-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.task_alb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "task-app-alb"
  }
}

resource "aws_lb_target_group" "task_app_alb_target_group" {
  name     = "task-app-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "task_app_alb_listener" {
  load_balancer_arn = aws_lb.task_app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.task_app_alb_target_group.arn
  }
}

resource "aws_ecs_cluster" "task_ecs_cluster" {
  name = "task-ecs-cluster"
}

resource "aws_security_group" "task_ecs_sg" {
  name        = "task-ecs-sg"
  description = "Allow inbound traffic for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  # TODO: Load balancer trafik almalı
  ingress {
    description      = "Flask app access from ALB"
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    security_groups  = [aws_security_group.task_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task-ecs-sg"
  }
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name = "/ecs/task-app-family"
} 

resource "aws_ecs_task_definition" "app_task" {
  family                   = "task-app-family"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_repo_name}:latest"
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "FLASK_ENV"
          value = "production"
        }
      ],
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.app_log_group.name
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "task-app-service"
  cluster         = aws_ecs_cluster.task_ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.task_app_alb_target_group.arn
    container_name   = "app"
    container_port   = 5000
  }

  network_configuration {
    assign_public_ip = true
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.task_ecs_sg.id]
  }

  lifecycle {
    ignore_changes = [
      desired_count,
    ]
  }

  depends_on = [
    aws_db_instance.task_rds,
    aws_lb_listener.task_app_alb_listener,
  ]
}

