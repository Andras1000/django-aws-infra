resource "aws_ecs_cluster" "prod" {
  name = "prod"
}

locals {
  container_vars = {
    region = var.region

    image = aws_ecr_repository.backend.repository_url
    log_group = aws_cloudwatch_log_group.prod_backend.name

    rds_db_name = var.prod_rds_db_name
    rds_username = var.prod_rds_username
    rds_password = var.prod_rds_password
    rds_hostname = aws_db_instance.prod.address

    domain = var.prod_backend_domain
    secret_key = var.prod_backend_secret_key

    sqs_access_key = aws_iam_access_key.prod_sqs.id
    sqs_secret_key = aws_iam_access_key.prod_sqs.secret
    sqs_name = aws_sqs_queue.prod.name

    s3_media_bucket = var.prod_media_bucket
    s3_access_key = aws_iam_access_key.prod_media_bucket.id
    s3_secret_key = aws_iam_access_key.prod_media_bucket.secret
  }
}

resource "aws_ecs_task_definition" "prod_backend_web" {
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  family = "backend-web"
  container_definitions = templatefile(
    "templates/backend_container.json.tpl",
    merge(
      local.container_vars,
      {
        name = "prod-backend-web"
        command = ["gunicorn", "-w", "3", "-b", ":8000", "django_ecs_aws.wsgi:application"]
        log_stream = aws_cloudwatch_log_stream.prod_backend_web.name
      },
    )
  )
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.prod_backend_task.arn
}

resource "aws_ecs_task_definition" "prod_backend_migration" {
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  family = "backend-migration"
  container_definitions = templatefile(
    "templates/backend_container.json.tpl",
    merge(
      local.container_vars,
      {
        name = "prod-backend-migration"
        command = ["python", "manage.py", "migrate"]
        log_stream = aws_cloudwatch_log_stream.prod_backend_migrations.name
      }
    )
  )
  depends_on = [aws_db_instance.prod]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.prod_backend_task.arn
}

resource "aws_ecs_service" "prod_backend_web" {
  name = "prod-backend-web"
  cluster = aws_ecs_cluster.prod.id
  task_definition = aws_ecs_task_definition.prod_backend_web.arn
  desired_count = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200
  enable_execute_command = true
  launch_type = "FARGATE"
  scheduling_strategy = "REPLICA"

  load_balancer {
    target_group_arn = aws_lb_target_group.prod_backend.arn
    container_name = "prod-backend-web"
    container_port = 8000
  }

  network_configuration {
    security_groups = [aws_security_group.prod_ecs_backend.id]
    subnets = [aws_subnet.prod_private_1.id, aws_subnet.prod_private_2.id]
    assign_public_ip = false
  }
}

resource "aws_security_group" "prod_ecs_backend" {
  name = "prod-ecs-backend"
  vpc_id = aws_vpc.prod.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.prod_lb.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "prod_backend_task" {
  name = "prod-backend-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })

  inline_policy {
    name = "prod-backend-task-ssmmessages"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Sid = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role = aws_iam_role.ecs_task_execution.name
}

resource "aws_cloudwatch_log_group" "prod_backend" {
  name = "prod-backend"
  retention_in_days = var.ecs_prod_backend_retention_days
}

resource "aws_cloudwatch_log_stream" "prod_backend_web" {
  log_group_name = aws_cloudwatch_log_group.prod_backend.name
  name           = "prod-backend-web"
}

resource "aws_cloudwatch_log_stream" "prod_backend_migrations" {
  log_group_name = aws_cloudwatch_log_group.prod_backend.name
  name           = "prod-backend-migrations"
}
