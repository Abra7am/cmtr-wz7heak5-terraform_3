provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_template" "this" {
  name = "cmtr-wz7heak5-template"

  image_id      = "ami-09e6f87a47903347c"
  instance_type = "t3.micro"
  key_name      = "cmtr-wz7heak5-keypair"

  vpc_security_group_ids = [
    "cmtr-wz7heak5-ec2_sg",
    "cmtr-wz7heak5-http_sg"
  ]

  iam_instance_profile {
    name = "cmtr-wz7heak5-instance_profile"
  }

  network_interfaces {
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
    Project   = "cmtr-wz7heak5"
  }
}

resource "aws_autoscaling_group" "this" {
  name             = "cmtr-wz7heak5-asg"
  desired_capacity = 2
  min_size         = 1
  max_size         = 2

  vpc_zone_identifier = [
    "subnet-10.0.1.0/24",
    "subnet-10.0.3.0/24"
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
    value               = "cmtr-wz7heak5"
    propagate_at_launch = true
  }
}

resource "aws_lb" "this" {
  name               = "cmtr-wz7heak5-loadbalancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = ["cmtr-wz7heak5-sglb"]

  subnets = [
    "subnet-10.0.1.0/24",
    "subnet-10.0.3.0/24"
  ]

  tags = {
    Terraform = "true"
    Project   = "cmtr-wz7heak5"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "cmtr-wz7heak5-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "cmtr-wz7heak5-vpc"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Terraform = "true"
    Project   = "cmtr-wz7heak5"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}