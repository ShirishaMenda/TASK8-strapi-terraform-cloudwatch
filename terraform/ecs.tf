resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  execution_role_arn = "arn:aws:iam::811738710312:role/ec2-ecr-role"
  task_role_arn      = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = "${aws_ecr_repository.strapi.repository_url}:latest"

      environment = [
        {
          name  = "DATABASE_CLIENT"
          value = "postgres"
        },
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "DATABASE_PORT"
          value = "5432"
        },
        {
          name  = "DATABASE_NAME"
          value = "strapidb"
        },
        {
          name  = "DATABASE_USERNAME"
          value = "postgres"
        },
        {
          name  = "DATABASE_PASSWORD"
          value = "postgres123"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "APP_KEYS"
          value = "key1,key2,key3,key4"
        },
        {
          name  = "API_TOKEN_SALT"
          value = "yoursalt"
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = "youradminsecret"
        },
        {
          name  = "JWT_SECRET"
          value = "yourjwtsecret"
        }
      ],

      portMappings = [
        {
          containerPort = 1337
        }
      ],

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/strapi"
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "/ecs/strapi"
        }
      }
    }
  ])
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

  depends_on = [
    aws_lb_listener.listener
  ]
}


