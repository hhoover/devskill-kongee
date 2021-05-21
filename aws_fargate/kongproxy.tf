resource "aws_ecs_service" "main" {
  name                               = "${var.name}-${var.environment}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
 
  network_configuration {
    security_groups  = var.ecs_service_security_groups
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }
 
  load_balancer {
    target_group_arn = aws_lb_target_group.kong.arn
    container_name   = "kong-proxy"
    container_port   = 8443
  }
 
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  depends_on = [aws_security_group.elb]
}

resource "aws_lb" "main" {
  name                       = "${var.name}-lb-${var.environment}"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = false
  tags                       = var.additional_tags
}

resource "aws_lb_target_group" "kong" {
  name     = "${var.name}-tg-${var.environment}"
  vpc_id   = aws_vpc.main.id
  port     = 8443
  protocol = "TCP"
  target_type = "ip"
  tags = var.additional_tags
  depends_on = [aws_lb.main]
}

resource "aws_ecs_task_definition" "main" {
  family                   = "kong"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  tags                     = { "Name" : "kong-proxy" }
  container_definitions = <<TASK_DEFINITION
[
    {
        "essential": true,
        "name": "kong-proxy",
        "image": "kong/kong-gateway:2.3.3.2-alpine",
        "entryPoint": [
            "/docker-entrypoint.sh"
        ],
        "command": [
            "kong",
            "docker-start"
        ],
        "healthCheck": {
            "command": [
                "CMD-SHELL",
                "/usr/local/bin/kong health"
            ],
            "startPeriod": 5,
            "interval": 10,
            "timeout": 5,
            "retries": 3
        },
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-region": "us-east-2",
                "awslogs-group": "awslogs-kong-fargate",
                "awslogs-stream-prefix": "awslogs-fargate"
            }
        },
        "portMappings": [
            {
                "containerPort": 80,
                "protocol": "tcp"
            },
            {
                "containerPort": 443,
                "protocol": "tcp"
            },
            {
                "containerPort": 8000,
                "protocol": "tcp"
            },
            {
                "containerPort": 8003,
                "protocol": "tcp"
            },
            {
                "containerPort": 8004,
                "protocol": "tcp"
            },
            {
                "containerPort": 8100,
                "protocol": "tcp"
            },
            {
                "containerPort": 8443,
                "protocol": "tcp"
            },
            {
                "containerPort": 8444,
                "protocol": "tcp"
            },
            {
                "containerPort": 8445,
                "protocol": "tcp"
            },
            {
                "containerPort": 8446,
                "protocol": "tcp"
            },
            {
                "containerPort": 8447,
                "protocol": "tcp"
            },
            {
                "containerPort": 10254,
                "protocol": "tcp"
            }
        ],
        "environment": [
            {
                "name": " KONG_NGINX_DAEMON",
                "value": "off"
            },
            {
                "name": "KONG_CLUSTER_LISTEN",
                "value": "off"
            },
            {
                "name": " KONG_STREAM_LISTEN",
                "value": "off"
            },
            {
                "name": "KONG_NGINX_WORKER_PROCESSES",
                "value": "2"
            },
            {
                "name": "KONG_PLUGINS",
                "value": "bundled"
            },
            {
                "name": "KONG_LUA_PACKAGE_PATH",
                "value": "/opt/?.lua;/opt/?/init.lua;;"
            },
            {
                "name": "KONG_PORT_MAPS",
                "value": "80:8000, 443:8443"
            },
            {
                "name": "KONG_ADMIN_LISTEN",
                "value": "127.0.0.1:8444 http2 ssl"
            },
            {
                "name": "KONG_STATUS_LISTEN",
                "value": "0.0.0.0:8100"
            },
            {
                "name": "KONG_PROXY_LISTEN",
                "value": "0.0.0.0:8000, 0.0.0.0:8443 http2 ssl"
            },
            {
                "name": "KONG_ADMIN_ERROR_LOG",
                "value": "/dev/stderr"
            },
            {
                "name": "KONG_PROXY_ERROR_LOG",
                "value": "/dev/stderr"
            },
            {
                "name": "KONG_PROXY_ACCESS_LOG",
                "value": "/dev/stdout"
            },
            {
                "name": "KONG_ADMIN_ACCESS_LOG",
                "value": "/dev/stdout"
            },
            {
                "name": "KONG_ADMIN_GUI_ERROR_LOG",
                "value": "/dev/stderr"
            },
            {
                "name": "KONG_PORTAL_API_ERROR_LOG",
                "value": "/dev/stderr"
            },
            {
                "name": "KONG_PORTAL_API_ACCESS_LOG",
                "value": "/dev/stdout"
            },
            {
                "name": "KONG_ADMIN_GUI_ACCESS_LOG",
                "value": "/dev/stdout"
            }
        ]
    }
]
TASK_DEFINITION
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}