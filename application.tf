############################################
# Provider
############################################
provider "aws" {
  region = var.aws_region
}

############################################
# Application Load Balancer
############################################
resource "aws_lb" "this" {
  name               = "cmtr-wz7heak5-loadbalancer"
  load_balancer_type = "application"
  security_groups    = ["cmtr-wz7heak5-sglb"]
  subnets            = var.public_subnets

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
    enabled             = true
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
# ALB Listener
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
  image_id      = "ami-068c0051b15cdb816"
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  iam_instance_profile {
    name = "cmtr-wz7heak5-instance_profile"
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      "cmtr-wz7heak5-ec2_sg",
      "cmtr-wz7heak5-http_sg"
    ]
    delete_on_termination = true
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

    cat <<HTML > /var/www/html/index.html
    <html>
      <body>
        <h1>This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP</h1>
      </body>
    </html>
    HTML
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
  vpc_zone_identifier       = var.public_subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

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