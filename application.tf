############################################
# Provider
############################################
provider "aws" {
  region = var.aws_region
}

############################################
# Data sources (pre-created resources)
############################################
data "aws_security_group" "lb" {
  name = "cmtr-wz7heak5-sglb"
}

data "aws_security_group" "ec2" {
  name = "cmtr-wz7heak5-ec2_sg"
}

data "aws_security_group" "http" {
  name = "cmtr-wz7heak5-http_sg"
}

data "aws_subnet" "public_a" {
  cidr_block = "10.0.1.0/24"
}

data "aws_subnet" "public_b" {
  cidr_block = "10.0.3.0/24"
}

############################################
# Application Load Balancer
############################################
resource "aws_lb" "this" {
  name               = "cmtr-wz7heak5-loadbalancer"
  load_balancer_type = "application"

  security_groups = [data.aws_security_group.lb.id]

  subnets = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

############################################
# Target Group
############################################
resource "aws_lb_target_group" "this" {
  name     = "cmtr-wz7heak5-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

############################################
# Listener
############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

############################################
# Launch Template
############################################
resource "aws_launch_template" "this" {
  name_prefix   = "cmtr-wz7heak5-template"
  image_id      = "ami-09e6f87a47903347c"
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  iam_instance_profile {
    name = "cmtr-wz7heak5-instance_profile"
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true

    security_groups = [
      data.aws_security_group.ec2.id,
      data.aws_security_group.http.id
    ]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd aws-cli jq
    systemctl enable httpd
    systemctl start httpd

    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

    PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)

    echo "This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP" \
      > /var/www/html/index.html
  EOF
  )

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

############################################
# Auto Scaling Group
############################################
resource "aws_autoscaling_group" "this" {
  name                      = "cmtr-wz7heak5-asg"
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  vpc_zone_identifier = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_id
    propagate_at_launch = true
  }
}

############################################
# Attach ASG to Target Group
############################################
resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn

  depends_on = [
    aws_lb_listener.http
  ]
}
