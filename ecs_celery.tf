resource "aws_ecs_task_definition" "prod_backend_worker" {
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  family = "backend-worker"
  container_definitions = templatefile(
    "templates/backend_container.json.tpl",
    merge(
      local.container_vars,
      {
        name = "prod-backend-worker"
        command = ["celery", "-A", "django_ecs_aws", "worker", "-l", "info"]
        log_stream = aws_cloudwatch_log_stream.prod_backend_worker.name
      }
    )
  )
  depends_on = [aws_sqs_queue.prod, aws_db_instance.prod]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.prod_backend_task.arn
}

resource "aws_ecs_service" "prod_backend_worker" {
  name                               = "prod-backend-worker"
  cluster                            = aws_ecs_cluster.prod.id
  task_definition                    = aws_ecs_task_definition.prod_backend_worker.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  enable_execute_command             = true

  network_configuration {
    security_groups  = [aws_security_group.prod_ecs_backend.id]
    subnets          = [aws_subnet.prod_private_1.id, aws_subnet.prod_private_2.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "prod_backend_beat" {
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"

  family = "backend-worker"
  container_definitions = templatefile(
    "templates/backend_container.json.tpl",
    merge(
      local.container_vars,
      {
        name = "prod-backend-worker"
        command = ["celery", "-A", "django_ecs_aws", "beat", "-l", "info"]
        log_stream = aws_cloudwatch_log_stream.prod_backend_beat.name
      }
    )
  )
  depends_on = [aws_sqs_queue.prod, aws_db_instance.prod]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.prod_backend_task.arn
}

resource "aws_ecs_service" "prod_backend_beat" {
  name                               = "prod-backend-beat"
  cluster                            = aws_ecs_cluster.prod.id
  task_definition                    = aws_ecs_task_definition.prod_backend_beat.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  enable_execute_command             = true

  network_configuration {
    security_groups  = [aws_security_group.prod_ecs_backend.id]
    subnets          = [aws_subnet.prod_private_1.id, aws_subnet.prod_private_2.id]
    assign_public_ip = false
  }
}


resource "aws_cloudwatch_log_stream" "prod_backend_worker" {
  name           = "prod-backend-worker"
  log_group_name = aws_cloudwatch_log_group.prod_backend.name

}

resource "aws_cloudwatch_log_stream" "prod_backend_beat" {
  name           = "prod-backend-beat"
  log_group_name = aws_cloudwatch_log_group.prod_backend.name
}
