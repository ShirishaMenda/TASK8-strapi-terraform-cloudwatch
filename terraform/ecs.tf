resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.ecsTaskRole.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "${aws_ecr_repository.strapi.repository_url}:latest"
      essential = true

      environment = [
        { name = "HOST",                   value = "0.0.0.0" },
        { name = "PORT",                   value = "1337" },
        { name = "NODE_ENV",               value = "production" },

        { name = "DATABASE_CLIENT",        value = "postgres" },
        { name = "DATABASE_HOST",          value = aws_db_instance.postgres.address },
        { name = "DATABASE_PORT",          value = "5432" },
        { name = "DATABASE_NAME",          value = "strapidb" },
        { name = "DATABASE_USERNAME",      value = "postgres" },
        { name = "DATABASE_PASSWORD",      value = "postgres123" },
        { name = "DATABASE_SSL",           value = "false" },
        { name = "DATABASE_SCHEMA",        value = "public" },
        { name = "DATABASE_SYNCHRONIZE",   value = "true" },

        { name = "URL",                    value = "http://${aws_lb.alb.dns_name}" },

        { name = "APP_KEYS",               value = "key1,key2,key3,key4" },
        { name = "API_TOKEN_SALT",         value = "yoursalt" },
        { name = "ADMIN_JWT_SECRET",       value = "youradminsecret" },
        { name = "JWT_SECRET",             value = "yourjwtsecret" }
      ],

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.ecs_logs
  ]
}

resource "aws_ecs_service" "service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.strapi.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  health_check_grace_period_seconds = 300

  depends_on = [
    aws_lb_listener.listener
  ]
}
